//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Land } from "./Land.sol";
import { Fruit } from "./Fruit.sol";

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
    // TODO: What's the real value of a seed ?
    uint256 constant seedPrice = 10 ** 17;
    // TODO: Ask tomo for the real amount 
    uint256 constant fertilizerAmount = 10 ** 17;
    uint256 constant massPerStage = 10;
    uint256 constant wholeFruitMass = 10; // can harvest 1 FRUIT for every 10 mass

    // For dna generation
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

    // The Land contract
    Land immutable land;
    // The fruit token
    Fruit immutable fruit;
    // The interest bearing token used as fertilizer
    ERC20 immutable fertilizer;

    enum TreeState {
        SEED, 
        SPROUT,
        BABY,
        TEENAGE,
        ADULT,
        DEAD
    }

    struct TreeData {
        // Seed traits
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
         * 3: treeWaterUseFactor. like above, normal = 1, add 5% for each value of factor
         * 3: treeFertilizerUseFactor. like treeWaterUseFactor
         * 4: fruitGrowthFactor
         * 4: longevity (max lifespan)
         * 3 : fruitColor
         * 3 : leaveColor
         * 2 : extraColor
         * 3 : extraCosmetic
         */
        uint32 dna;
        // Tree traits
        uint256 lastFertilized; // timestamp. implies that fertilizedAmount = 100 @ lastFertilized
        uint256 lastWatered; // timestamp. implies that waterLevel = 100 @ lastWatered
        uint256 lastHarvested; // timestamp.
        uint256 plantedAt; // timestamp. When the seed was planted
        uint256 landId; // id of the tree's land
    }

    // Mapping from a Seed token Id to its TreeData
    mapping (uint256 => TreeData) treeDatas;
    // Mapping from a block number to the number of minted seeds in this block
    mapping (uint256 => uint8) mintedTokensPerBlock;

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

    constructor(address _landAddress, address _fruitAddress, address _fertilizerAddress) ERC721("Seed", "SEED") {
        land = Land(_landAddress);
        fruit = Fruit(_fruitAddress);
        fertilizer = ERC20(_fertilizerAddress);
    }

    /**
     * @dev Extract a trait value from the seed's dna
     * @param lastBitPosition clears the right bits of the seed
     * @param bitsMask clear the left bits of the seed
     */
    function _traitFromDNA(uint32 _dna, uint8 lastBitPosition, uint8 bitsMask) internal pure returns (uint8) {
        // 110_0101_011_101_0001_1110_010_101_00_000
        //                                  110_0101 <- right shift (>>) by 25
        //                               & 0000_1111 <- bit mask
        //                                 0000_0101 = 5
        return uint8(_dna >> lastBitPosition) & bitsMask;
    } 

    /// Get the species of a seed from its DNA
    function species(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _speciesLastBitPosition, _speciesMask);
    }

    /// Get the tree growth factor of a seed from its DNA
    function treeGrowthFactor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _treeGrowthFactorLastBitPosition, _treeGrowthFactorMask);
    }

    /// Get the tree water use factor of a seed from its DNA
    function treeWaterUseFactor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _treeWaterUseFactorLastBitPosition, _treeWaterUseFactorMask);
    }

    /// Get the tree fertilizer use factor of a seed from its DNA
    function treeFertilizerUseFactor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _treeFertilizerUseFactorLastBitPosition, _treeFertilizerUseFactorMask);
    }

    /// Get the fruit growth factor of a seed from its DNA
    function fruitGrowthFactor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _fruitGrowthFactorLastBitPosition, _fruitGrowthFactorMask);
    }

    /// Get the longevity of a seed from its DNA
    function longevity(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _longevityLastBitPosition, _longevityMask);
    }

    /// Get the fruit color of a seed from its DNA
    function fruitColor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _fruitColorLastBitPosition, _fruitColorMask);
    }

    /// Get the leave color of a seed from its DNA
    function leaveColor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _leaveColorLastBitPosition, _leaveColorMask);
    }

    /// Get the extra color of a seed from its DNA
    function extraColor(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _extraColorLastBitPosition, _extraColorMask);
    }

    /// Get the extra cosmetic of a seed from its DNA
    function extraCosmetic(uint32 _dna) public pure returns (uint8) {
        return _traitFromDNA(_dna, _extraCosmeticLastBitPosition, _extraCosmeticMask);
    }

    /// Calculate the tree's growth rate
    function growthRate(uint256 _seedId) public view returns (uint8) {
        // TODO: use the land with the seed trait instead
        return treeGrowthFactor(treeDatas[_seedId].dna);
    }

    /// Calculate the tree's fertilizer use rate
    function fertilizerUseRate(uint256 _seedId) public view returns (uint8) {
        return treeFertilizerUseFactor(treeDatas[_seedId].dna);
    }

    /// Calculate the tree's mass
    function mass(uint256 _seedId) public view returns (uint256) {
        return growthRate(_seedId) * (block.timestamp - treeDatas[_seedId].plantedAt) / 3600;
    }

    /// Calculate the tree's water level
    function waterLevel(uint256 _treeId) public view returns (uint256) {
        uint8 waterUseFactor = treeWaterUseFactor(treeDatas[_treeId].dna);
        int256 _waterLevel = int256(100 - waterUseFactor * (block.timestamp - treeDatas[_treeId].lastWatered));
        return _waterLevel > 0 ? uint256(_waterLevel) : 0;
    }

    /// Calculate the seed's state
    function state(uint256 _seedId) public view returns (TreeState) {
        // Check if the seed is planted
        if (treeDatas[_seedId].plantedAt == 0) return TreeState.SEED;
        // Check if the tree is dead
        uint256 _waterLevel = waterLevel(_seedId);
        if (_waterLevel == 0) return TreeState.DEAD;
        // Calculate the tree's mass
        uint256 _mass = mass(_seedId);
        // Calculate the tree's stage
        uint256 _stage = _mass / massPerStage;
        if (_stage > uint8(TreeState.ADULT)) return TreeState.ADULT;
        return TreeState(_stage);
    }

    /// Calculate the fruit growth rate of a tree
    function fruitGrowthRate(uint256 _seedId) public view returns (uint8) {
        return fruitGrowthFactor(treeDatas[_seedId].dna);
    }

    /// Calculate the tree's fruit mass
    function fruitMass(uint256 _seedId) public view returns (uint256) {
        uint256 fertilizedTil = treeDatas[_seedId].lastFertilized + fertilizerAmount / fertilizerUseRate(_seedId);
        return block.timestamp < fertilizedTil
            ? (block.timestamp - treeDatas[_seedId].lastHarvested) / 3600 * fruitGrowthRate(_seedId)
            : (fertilizedTil - treeDatas[_seedId].lastHarvested) / 3600 * fruitGrowthRate(_seedId);
    }

    function unharvestedFruitCount(uint256 _seedId) public view returns (uint256) {
        // Calculate the fruit mass
        uint256 _fruitMass = fruitMass(_seedId);
        return _fruitMass / wholeFruitMass;
    }

    /**
     * Buy a new seed with pseudo random traits for some fixed amount of fruit tokens.
     * @dev Mint a new Seed token. See {ERC721-_safeMint}
     */
    function buy() external {
        // Check if the limit to buy seed per block is hit
        if (mintedTokensPerBlock[block.number] >= mintLimitPerBlock) revert MintingForbiddenError();
        // Transfer a fixed amount of fruit from the sender to this contract
        if (!fruit.transferFrom(msg.sender, address(this), seedPrice)) revert TransferError(address(fruit), msg.sender, address(this), seedPrice);
        // Generate the dna of the seed.
        // Extract up to 8 dna for a blockhash (256 / 32 = 8)
        // FIXME: 🚨 Only pseudo random
        bytes32 hash = blockhash(block.number - 1);
        bytes4 dna = bytes4(hash << mintedTokensPerBlock[block.number] * 32);
        // Track the number of minted seeds this block
        mintedTokensPerBlock[block.number]++;
        // Mint the seed token. Unsafe because of an external call
        uint256 id = _tokenIdCounter.current();
        _safeMint(msg.sender, id);
        _tokenIdCounter.increment();
        // Initialise its data
        // TODO: calculate the different traits using the species trait values and its dna
        treeDatas[id].dna = uint32(dna);
    }

    /**
     * Plant one of `your` `seeds` into one of `your` `lands`. It will consume some of your fertilizer.
     * @dev Create a soft link from a Seed token to a Land token. The Seed token remains controlled by its owner, unlike a staking action.
     */
    function plant(uint256 _seedId, uint256 _landId) external {
        // Check if the token exists and if the sender owns the seed AND the land
        if (ownerOf(_seedId) != msg.sender || land.ownerOf(_landId) != msg.sender) revert UnauthorizedError();
        // Check if the seed is not already planted
        if (treeDatas[_seedId].landId != 0) revert AlreadyPlantedError();
        // Transfer the amount of fertilizer from the sender to this contract
        // TODO: Replace by the real fertilizer amount
        if (!fertilizer.transferFrom(msg.sender, address(this), fertilizerAmount)) revert TransferError(address(fertilizer), msg.sender, address(this), fertilizerAmount);
        // Initialize the tree data
        treeDatas[_seedId].plantedAt = block.timestamp;
        treeDatas[_seedId].landId = _landId;
        treeDatas[_seedId].lastFertilized = block.timestamp;
        treeDatas[_seedId].lastWatered = block.timestamp;
        // Event
        emit Planted(_seedId, _landId);
    }

    /**
     * Fertilize one of `your` `alive` trees with some token so it can produce fruits.
     * @dev It is somewhat similar to staking some token for an unlimited time.
     */
    function fertilize(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_treeId) != msg.sender) revert UnauthorizedError();
        // Transfer the amount of fertilizer from the sender to this contract
        if (!fertilizer.transferFrom(msg.sender, address(this), fertilizerAmount)) revert TransferError(address(fertilizer), msg.sender, address(this), fertilizerAmount);
        // Update the tree state
        treeDatas[_treeId].lastFertilized = block.timestamp;
        // Event
        emit Fertilized(_treeId, fertilizerAmount);
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
     * @dev Withdraw some fruits tokens to your address
     */
    function harvest(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_treeId) != msg.sender) revert UnauthorizedError();
        // Check if it is an adult tree
        if (state(_treeId) != TreeState.ADULT) revert InvalidStateError(state(_treeId));
        // Calculate the unharvested fruit amount
        uint256 _unharvestedFruits = unharvestedFruitCount(_treeId);
        // Update the tree data
        treeDatas[_treeId].lastHarvested = block.timestamp;
        // Transfer the amount of unharvested fruits from this contract to the sender
        if (!fruit.transferFrom(address(this), msg.sender, _unharvestedFruits)) revert TransferError(address(fruit), address(this), msg.sender, _unharvestedFruits);
        // Event
        emit Harvested(_treeId, _unharvestedFruits);
    }

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