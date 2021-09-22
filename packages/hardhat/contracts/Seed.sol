//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Land } from "./Land.sol";

/// You are not authorized to do this action
error UnauthorizedError();
/// You did not send enough funds
error InsuffisantFundsError();
/// The `symbol` transfer from `from` to `to` for `amount` failed
error TransferError(address token, address from, address to, uint256 amount);

/**
 * The Seed contract of the `nft-fruit-tree` game.
 */
contract Seed is ERC721, ERC721Enumerable {
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint8 constant mintLimitPerBlock = 8;
    uint256 constant seedPrice = 10 ** 17;

    uint8 constant dnaBits = 32;
    uint8 constant _speciesLastBitPosition = dnaBits - 3;
    uint8 constant _speciesMask = 2 ** 3 - 1;
    uint8 constant _treeGrowthFactorLastBitPosition = _speciesLastBitPosition - 4;
    uint8 constant _treeGrowthFactorMask = 2 ** 4 - 1;
    uint8 constant _treeWaterUseFactorLastBitPosition = _treeGrowthFactorLastBitPosition - 3;
    uint8 constant _treeWaterUseFactorMask = 2 ** 3 - 1;
    uint8 constant _treeFertilizerUseFactorLastBitPosition = _treeWaterUseFactorLastBitPosition - 3;
    uint8 constant _treeFertilizerUseFactorMask = 2 ** 3 - 1;
    uint8 constant _fruitGrowthFactorLastBitPosition = _treeFertilizerUseFactorLastBitPosition - 4;
    uint8 constant _fruitGrowthFactorMask = 2 ** 4 - 1;
    uint8 constant _longevityLastBitPosition = _fruitGrowthFactorLastBitPosition - 4;
    uint8 constant _longevityMask = 2 ** 4 - 1;
    uint8 constant _fruitColorLastBitPosition = _longevityLastBitPosition - 3;
    uint8 constant _fruitColorMask = 2 ** 3 - 1;
    uint8 constant _leaveColorLastBitPosition = _fruitColorLastBitPosition - 3;
    uint8 constant _leaveColorMask = 2 ** 3 - 1;
    uint8 constant _extraColorLastBitPosition = _leaveColorLastBitPosition - 2;
    uint8 constant _extraColorMask = 2 ** 2 - 1;
    uint8 constant _extraCosmeticLastBitPosition = _extraColorLastBitPosition - 3; 
    uint8 constant _extraCosmeticMask = 2 ** 3 - 1;

    enum TreeState {
        SEED, 
        SPROUT,
        BABY,
        TEENAGE,
        ADULT,
        DEAD
    }

    struct TreeData {
        // Seed characteristics
        /**
         * @dev DNA = 32 bits (e.g. 110_0101_011_101_0001_1110_010_101_00_000)
         * breakdown of bits in sequence:
         * 3 : 8 possible species
         * 111 = rare
         * 110 101 = medium
         * 100 011 010 001 000 = common
         * if tree species and landSpecies have same value then bonus growth
         * 4: treeGrowthFactor
         * const treeGrowthFactorInc = 5%
         * tree growth = … * (1 + treeGrowthFactorInc * treeGrowthFactor)
         * 3: treeWaterUseFactor
         * like above, normal = 1, add 5% for each value of factor
         * 3: treeFertilizerUseFactor
         * like treeWaterUseFactor
         * 4: fruitGrowthFactor
         * 4: longevity (max lifespan)
         * 3 : fruitColor
         * 3 : leaveColor
         * 2 : extraColor
         * 3 : extraCosmetic
         */
        uint32 dna;
        // Tree characteristics
        uint256 lastFertilized; // 
        uint256 lastWatered; // timestamp. implies that waterMeter = 100 @ lastWatered
        uint256 landId; // id of the tree's land
        //uint8 lastFruitMass; // 
        //uint16 lastMass; // last always means last saved. 
    }

    // Mapping from a Seed token Id to its TreeData
    mapping (uint256 => TreeData) treeDatas;
    // Mapping from a blockHash to the number of minted seeds in this block
    mapping (uint256 => uint8) mintedTokensPerBlock;
    // The Land contract
    Land immutable land;
    // The interest bearing token used as fertilizer
    ERC20 immutable fertilizer;

    event Planted(uint256 indexed seedId, uint256 indexed landId);
    event Watered(uint256 indexed seedId);
    event Fertilized(uint256 indexed seedId, uint256 fertilizerAmount);
    event Harvested(uint256 indexed seedId, uint256 fruitAmount);
    /// The seed `id` is already planted
    error AlreadyPlantedError();
    /// The state `state` is invalid
    error InvalidStateError(TreeState state);
    /// You cannot mint another seed this block
    error MintingForbiddenError();

    constructor(address _landAddress, address _fertilizerAddress) ERC721("Seed", "SEED") {
        land = Land(_landAddress);
        fertilizer = ERC20(_fertilizerAddress);
    }

    /**
     * @dev Extract a characteristic value from the seed's dna
     * @param lastBitPosition clears the right bits of the seed
     * @param bitsMask clear the left bits of the seed
     */
    function _characteristicFromDNA(uint32 _dna, uint8 lastBitPosition, uint8 bitsMask) internal pure returns (uint8) {
        return uint8(_dna >> lastBitPosition) & bitsMask;
    } 

    /// Get the species of a seed from its DNA
    function species(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _speciesLastBitPosition, _speciesMask);
    }

    /// Get the tree growth factor of a seed from its DNA
    function treeGrowthFactor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _treeGrowthFactorLastBitPosition, _treeGrowthFactorMask);
    }

    /// Get the tree water use factor of a seed from its DNA
    function treeWaterUseFactor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _treeWaterUseFactorLastBitPosition, _treeWaterUseFactorMask);
    }

    /// Get the tree fertilizer use factor of a seed from its DNA
    function treeFertilizerUseFactor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _treeFertilizerUseFactorLastBitPosition, _treeFertilizerUseFactorMask);
    }

    /// Get the fruit growth factor of a seed from its DNA
    function fruitGrowthFactor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _fruitGrowthFactorLastBitPosition, _fruitGrowthFactorMask);
    }

    /// Get the longevity of a seed from its DNA
    function longevity(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _longevityLastBitPosition, _longevityMask);
    }

    /// Get the fruit color of a seed from its DNA
    function fruitColor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _fruitColorLastBitPosition, _fruitColorMask);
    }

    /// Get the leave color of a seed from its DNA
    function leaveColor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _leaveColorLastBitPosition, _leaveColorMask);
    }

    /// Get the extra color of a seed from its DNA
    function extraColor(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _extraColorLastBitPosition, _extraColorMask);
    }

    /// Get the extra cosmetic of a seed from its DNA
    function extraCosmetic(uint32 _dna) public pure returns (uint8) {
        return _characteristicFromDNA(_dna, _extraCosmeticLastBitPosition, _extraCosmeticMask);
    }

    /// Get the water level of a tree
    function waterLevel(uint256 _treeId) public view returns (uint256) {
        uint256 lastWatered = treeDatas[_treeId].lastWatered;
        uint8 waterUseFactor = treeWaterUseFactor(treeDatas[_treeId].dna);
        int256 _waterLevel = int256(100 - waterUseFactor * (block.timestamp - lastWatered));
        return _waterLevel > 0 ? uint256(_waterLevel) : 0;
    }

    /// Calculate the state of a seed
    function state(uint256 _seedId) public view returns (TreeState) {}

    /**
     * Buy a new seed with pseudo random characteristics for some fixed amount of tokens.
     * @dev Mint a new Seed token. See {ERC721-_safeMint}
     */
    function buy() external {
        // Check if the limit to buy seed per block is hit
        if (mintedTokensPerBlock[block.number] >= mintLimitPerBlock) revert MintingForbiddenError();
        // Transfer the amount of fertilizer from the sender to this contract
        if (!fertilizer.transferFrom(msg.sender, address(this), seedPrice)) revert TransferError(address(fertilizer), msg.sender, address(this), seedPrice);
        // Generate the dna of the seed. 🚨 Only pseudo random
        // Extract up to 8 dna for a blockhash (256 / 32 = 8)
        bytes32 hash = blockhash(block.number - 1);
        bytes4 dna = bytes4(hash << mintedTokensPerBlock[block.number] * 32);
        // Track the number of minted seeds this block
        mintedTokensPerBlock[block.number]++;
        // Mint the seed token. Unsafe because of an external call
        uint256 id = _tokenIdCounter.current();
        _safeMint(msg.sender, id);
        _tokenIdCounter.increment();
        // Save its dna
        treeDatas[id].dna = uint32(dna);
    }

    /**
     * Plant one of `your` `seeds` into one of `your` `lands`. It will consume some of your fertilizer.
     * @dev Create a soft link from a Seed token to a Land token. The Seed token remains controlled by its owner, unlike a staking action.
     * It will initialize its TreeData.
     */
    function plant(uint256 _seedId, uint256 _landId) external {
        // Check if the token exists and if the sender owns the seed AND the land
        if (ownerOf(_seedId) != msg.sender || land.ownerOf(_landId) != msg.sender) revert UnauthorizedError();
        // Check if the seed is not already planted
        if (treeDatas[_seedId].landId != 0) revert AlreadyPlantedError();
        // Transfer the amount of fertilizer from the sender to this contract
        // TODO: Replace by the real fertilizer amount
        if (!fertilizer.transferFrom(msg.sender, address(this), /* temp */ 10 ** 16)) revert TransferError(address(fertilizer), msg.sender, address(this), /* temp */ 10 ** 16);
        // Initialize the tree data
        treeDatas[_seedId].landId = _landId;
        treeDatas[_seedId].lastFertilized = block.timestamp;
        treeDatas[_seedId].lastWatered = block.timestamp;
        // Events
        emit Planted(_seedId, _landId);
        emit Fertilized(_seedId, /* temp */ 10 ** 16);
        emit Watered(_seedId);
    }

    /**
     * Fertilize one of `your` `alive` trees with some token to boost its fruit production capacity.
     * @dev It is somewhat similar to staking some token for an unlimited time.
     * It will persist the new state data.
     */
    function fertilize(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_treeId) != msg.sender) revert UnauthorizedError();
        // Transfer the amount of fertilizer from the sender to this contract
        if (!fertilizer.transferFrom(msg.sender, address(this), /* temp */ 10 ** 16)) revert TransferError(address(fertilizer), msg.sender, address(this), /* temp */ 10 ** 16);
        // Update the tree state
        treeDatas[_treeId].lastFertilized = block.timestamp;
        // Event
        emit Fertilized(_treeId, /* temp */ 10 ** 16);
    }
    /**
     * Water one of `your` `alive` `trees` to maintain it `alive`. A dead tree cannot grow or produce fruit anymore.
     */
    function water(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_treeId) != msg.sender) revert UnauthorizedError();
        // Check if it is not a seed or dead
        TreeState treeState = state(_treeId);
        if (treeState == TreeState.SEED || treeState == TreeState.DEAD) revert InvalidStateError(treeState);
        // Update the tree state
        treeDatas[_treeId].lastWatered = block.timestamp;
        // Event
        emit Watered(_treeId);
    }
    /**
     * Harvest the produced `fruits` of one of `your` fully grown `alive` `trees`.
     */
    function harvest() external {}
    /**
     * Move one of `your` `alive` `trees` to another one of `your` `land`.
     * @dev Similar to {plant}
     */
    function move(uint256 _treeId, uint256 _newLandId) external {
        // Check if the token exists, if the sender owns the seed. Same thing for the new land
        if (ownerOf(_treeId) != msg.sender || land.ownerOf(_newLandId) != msg.sender) revert UnauthorizedError();
        // Check if it is not a seed or dead
        TreeState treeState = state(_treeId);
        if (treeState == TreeState.SEED || treeState == TreeState.DEAD) revert InvalidStateError(treeState);
        // Update the tree state
        treeDatas[_treeId].landId = _newLandId;
        // Event
        emit Planted(_treeId, _newLandId);
    }
    /**
     * Burn one of `your` `trees` and empty the corresponding `land`.
     * @dev See {ERC721-_burn}
     */
    function burn(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the seed
        if (ownerOf(_treeId) != msg.sender) revert UnauthorizedError();
        // TODO: Should we check the tree state ? 
        delete treeDatas[_treeId];
        _burn(_treeId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}