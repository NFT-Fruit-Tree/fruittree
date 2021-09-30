//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Land } from "./Land.sol";
import { Fruit } from "./Fruit.sol";
import { UnauthorizedError, InsufficientFundsError, TransferError } from "./Shared.sol";

/**
 * The Seed contract of the `nft-fruit-tree` game.
 */
contract Seed is ERC721, ERC721Enumerable {
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint8 constant mintLimitPerBlock = 8;
    uint8 constant massPerStage = 50;
    uint8 constant minimumAdultMass = uint8(uint8(TreeState.ADULT) * massPerStage); // mass needed to become adult
    uint8 constant wholeFruitMass = 10; // can harvest 1 FRUIT for every 10 mass
    int16 constant driedDeath = -500; // level at which the tree will die from the lack of water
    // TODO: What's the real value of a seed ?
    uint256 constant seedPrice = 10 ** 17;
    // TODO: Ask tomo for the real amount 
    uint256 constant fertilizerAmount = 10 ** 17;

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

    Land immutable land; // The Land token contract
    Fruit immutable fruit; // The Fruit token contract
    ERC20 immutable currency; // The ERC20 used as currency

    enum TreeState {
        SEED, 
        SPROUT,
        BABY,
        TEENAGE,
        ADULT,
        DEAD
    }

    struct TreeData {
        // Seed properties
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
        // Tree properties
        uint16 landId; // id of the tree's land
        uint256 adultAt; // timestamp when the tree became adult
        uint256 lastSnapshotedAt; // timestamp of the last state snapshot
        uint256 lastFertilizedAt; // timestamp. implies that fertilizedAmount = 100 @ lastFertilized
        uint256 lastWateredAt; // timestamp. implies that waterLevel = 100 @ lastWatered
        uint256 lastHarvestedAt; // timestamp.
        uint256 lastMass; // last calculated tree mass at the last watering
        uint256 lastFruitMass; // last unharvested fruits mass at the last fertilizing
    }

    // A land's game state
    struct LandState {
        address landOwner;
        uint8 landType;
        uint256 seedId;
        uint8 seedSpecies;
        TreeState seedState;
        uint256 unharvestedFruits;
    }

    // Mapping from a Seed token Id to its TreeData
    mapping (uint256 => TreeData) public treeData;
    // Mapping from a land id to a seed id
    mapping (uint16 => uint256) private _seedByLandId;
    // Mapping from a block number to the number of minted seeds in this block
    mapping (uint256 => uint8) mintedTokensPerBlock;

    event Planted(uint256 indexed seedId, uint16 indexed landId);
    event Watered(uint256 indexed seedId);
    event Fertilized(uint256 indexed seedId, uint256 fertilizerAmount);
    event Harvested(uint256 indexed seedId, uint256 fruitAmount);
    /// The seed is already planted
    error AlreadyPlantedError();
    /// No planted seeds
    error NoPlantedSeedError();
    /// The state `state` is invalid
    error InvalidStateError(TreeState state);
    /// You cannot mint another seed this block
    error MintingForbiddenError();

    constructor(address _landAddress, address _fruitAddress, address _currencyAddress) ERC721("Seed", "SEED") {
        land = Land(_landAddress);
        fruit = Fruit(_fruitAddress);
        currency = ERC20(_currencyAddress);
    }

    /* --- Player actions functions --- */

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
        bytes32 _hash = blockhash(block.number - 1);
        bytes4 _dna = bytes4(_hash << mintedTokensPerBlock[block.number] * dnaBits);
        // Track the number of minted seeds this block
        mintedTokensPerBlock[block.number]++;
        // Mint the seed token. Unsafe because of an external call
        uint256 _id = _tokenIdCounter.current();
        _safeMint(msg.sender, _id);
        _tokenIdCounter.increment();
        // Initialise the seed's traits
        // TODO: calculate the different traits using the species trait values and its dna
        treeData[_id].dna = uint32(_dna);
    }

    /**
     * Plant one of `your` `seeds` into one of `your` `lands`.
     * @dev Create a soft link from a Seed token to a Land token. The Seed token remains controlled by its owner, unlike a staking action.
     */
    function plant(uint256 _seedId, uint16 _landId) external {
        // Check if the token exists and if the sender owns the seed AND the land
        if (ownerOf(_seedId) != msg.sender || land.ownerOf(_landId) != msg.sender) revert UnauthorizedError();
        // Check if the seed is not already planted and if the land is not already taken
        if (_isPlanted(treeData[_seedId]) || _isLandTaken(_landId)) revert AlreadyPlantedError();
        // Initialize the tree data
        _initializeState(_seedId, _landId);
        // Update the land id to seed id mapping
        _seedByLandId[_landId] = _seedId;
        // Event
        emit Planted(_seedId, _landId);
    }

    /**
     * Fertilize an `alive` `adult` `tree` with some token so it can produce fruits.
     * @dev It is somewhat similar to staking some token for an unlimited time.
     */
    function fertilize(uint256 _seedId) external {
        // Check if the token exists
        if (!_exists(_seedId)) revert UnauthorizedError();
        // Check if it is a adult tree
        if (!_isAdult(_seedId)) revert InvalidStateError(state(_seedId));
        // Transfer the amount of fertilizer from the sender to this contract
        if (!currency.transferFrom(msg.sender, address(this), fertilizerAmount)) revert TransferError(address(currency), msg.sender, address(this), fertilizerAmount);
        // Update the tree state
        _updateState(_seedId);
        treeData[_seedId].lastFertilizedAt = block.timestamp;
        // Event
        emit Fertilized(_seedId, fertilizerAmount);
    }

    /**
     * Water an `alive` `tree` to maintain it `alive`. A dead tree cannot grow or produce fruit anymore.
     */
    function water(uint256 _seedId) external {
        // Check if the token exists
        if (!_exists(_seedId)) revert UnauthorizedError();
        // Check if it is planted and not dead
        TreeState treeState = state(_seedId);
        if (!_isPlanted(treeData[_seedId]) || treeState == TreeState.DEAD) revert InvalidStateError(treeState);
        // Update the tree state
        _updateState(_seedId);
        treeData[_seedId].lastWateredAt = block.timestamp;
        // Event
        emit Watered(_seedId);
    }

    /**
     * Harvest the produced `fruits` of one of `your` `alive` `adult` `trees`.
     * @dev Withdraw some fruits tokens to your address
     */
    function harvest(uint256 _seedId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_seedId) != msg.sender) revert UnauthorizedError();
        // Check if it is an adult tree
        if (!_isAdult(_seedId)) revert InvalidStateError(state(_seedId));
        // Update the tree data
        _updateState(_seedId);
        // Calculate the unharvested fruit amount
        uint256 _unharvestedFruits = treeData[_seedId].lastFruitMass / wholeFruitMass;
        // Reset the fruit mass
        treeData[_seedId].lastHarvestedAt = block.timestamp;
        treeData[_seedId].lastFruitMass = 0;
        // Transfer the amount of unharvested fruits from this contract to the sender
        if (!fruit.transferFrom(address(this), msg.sender, _unharvestedFruits)) revert TransferError(address(fruit), address(this), msg.sender, _unharvestedFruits);
        // Event
        emit Harvested(_seedId, _unharvestedFruits);
    }

    /**
     * Move one of `your` `alive` `trees` to another one of `your` `land`.
     * @dev Similar to {plant}
     */
    function move(uint256 _seedId, uint16 _newLandId) external {
        // Check if the token exists, if the sender owns the seed. Same thing for the new land
        if (ownerOf(_seedId) != msg.sender || land.ownerOf(_newLandId) != msg.sender) revert UnauthorizedError();
        // Check if it is planted
        if (!_isPlanted(treeData[_seedId])) revert NoPlantedSeedError();
        // Check if the land is not already taken
        if (_isLandTaken(_newLandId)) revert AlreadyPlantedError();
        // Update the tree state
        _updateState(_seedId);
        treeData[_seedId].landId = _newLandId;
        // Update the land id to seed id mapping
        _seedByLandId[_newLandId] = _seedId;
        // Event
        emit Planted(_seedId, _newLandId);
    }

    /**
     * Burn one of `your` `trees` and empty the corresponding `land`.
     * @dev See {ERC721-_burn}
     */
    function burn(uint256 _seedId) external {
        // Check if the token exists and if the sender owns the seed
        if (ownerOf(_seedId) != msg.sender) revert UnauthorizedError();
        // TODO: Should we check the tree state ? 
        delete treeData[_seedId];
        _burn(_seedId);
    }

    /* --- Seed state functions --- */

    /// Calculate the seed's state
    function state(uint256 _seedId) public view returns (TreeState) {
        // Check if the seed is planted
        if (!_isPlanted(treeData[_seedId])) return TreeState.SEED;
        // Check if the tree is dead
        int256 _treeWaterLevel = _waterLevel(treeData[_seedId]);
        if (_treeWaterLevel <= driedDeath) return TreeState.DEAD;
        // Calculate the tree's mass
        uint256 _treeMass = _mass(treeData[_seedId]);
        // Calculate the tree's stage
        uint256 _stage = _treeMass / massPerStage;
        if (_stage >= uint8(TreeState.ADULT)) return TreeState.ADULT;
        return TreeState(_stage);
   }

    /// Calculate the tree's current mass
    function mass(uint256 _seedId) external view returns (uint256) {
        // Check if the seed is planted
        if (!_isPlanted(treeData[_seedId])) return 0;
        // Calculate the planted seed mass
        return _mass(treeData[_seedId]);
    }

    /// Calculate the tree's water level
    function waterLevel(uint256 _seedId) public view returns (int256) {
        // Check if the seed is planted
        if (!_isPlanted(treeData[_seedId])) return 0;
        return _waterLevel(treeData[_seedId]);
    }

    /// Calculate the tree's fruit mass
    function fruitMass(uint256 _seedId) external view returns (uint256) {
        // Check if the seed is an adult
        if (!_isAdult(_seedId)) return 0;
        return _fruitMass(treeData[_seedId]);
    }

    /// Calculate how many fruits you can harvest on a tree
    function unharvestedFruitCount(uint256 _seedId) public view returns (uint256) {
        // Check if the seed is an adult
        if (!_isAdult(_seedId)) return 0;
        return _fruitMass(treeData[_seedId]) / wholeFruitMass;
    }

    /// Get the tree's land id
    function landId(uint256 _seedId) external view returns (uint16) {
        // Check if the seed is planted
        if (!_isPlanted(treeData[_seedId])) return type(uint16).max;
        return treeData[_seedId].landId;
    }

    /// Get the land's tree id
    function seedByLandId(uint16 _landId) public view returns (uint256) {
        // Check if the land id is valid
        land.idToCoordinates(_landId);
        // Get the seed id by the land id
        uint256 _seedId = _seedByLandId[_landId];
        // Check the special case where _landId = 0
        if (treeData[_seedId].landId == _landId && _isPlanted(treeData[_seedId])) return _seedId;
        // It should only happen when there is no seed planted on this land
        return type(uint256).max;
    }

    // Calculate and save the seed's new state
    function _updateState(uint256 _seedId) internal {
        TreeData storage _seed = treeData[_seedId];
        // Calculate the new tree mass
        uint256 _treeMass = _mass(_seed);
        // Check if the tree is adult
        if (_treeMass >= minimumAdultMass) {
            // For the first time since the tree became adult only
            if (_seed.adultAt == 0) {
                // Calculate and save when the tree becomes adult
                _seed.adultAt = _seed.lastSnapshotedAt + (minimumAdultMass - _seed.lastMass) / uint256(_growthFactor(_seed)) * 3600;
            }

            // Calculate the fruit mass
            _seed.lastFruitMass = _fruitMass(_seed);
        }

        // Save the new mass only after the others state updates
        _seed.lastMass = _treeMass;
        _seed.lastSnapshotedAt = block.timestamp;
    }

    // Initialize the seed's state
    function _initializeState(uint256 _seedId, uint16 _landId) internal {
        TreeData storage _seed = treeData[_seedId];
        // Required for state calculations
        _seed.lastSnapshotedAt = block.timestamp;
        // The tree start to grow immediatly
        _seed.lastWateredAt = block.timestamp;
        _seed.landId = _landId;
    }
    
    // Calculate the tree's water level
    function _waterLevel(TreeData storage _seed) internal view returns (int256) {
        uint256 _treeWaterUseFactor = uint256(_waterUseFactor(_seed));
        return 100 - int256(_treeWaterUseFactor * (block.timestamp - _seed.lastWateredAt));
    }
    
    // Calculate the tree's mass
    function _mass(TreeData storage _seed) internal view returns (uint256) {
        // Calculate the time when the tree runs of water
        uint256 _hydratedTil = _seed.lastWateredAt + 100 / uint256(_waterUseFactor(_seed)) * 3600;
        // Did the tree ran out of water ?
        uint256 _hydratedTilNow = Math.min(block.timestamp, _hydratedTil);
        // Calculate the new tree mass from the previously calculated mass and calculated the new one
        return _seed.lastMass + uint256(_growthFactor(_seed)) * (_hydratedTilNow - _seed.lastSnapshotedAt) / 3600;
    }

    // Calculate the tree's fruit mass
    function _fruitMass(TreeData storage _seed) internal view returns (uint256) {
        // Calculate the time when the tree will run out of fertilizer
        uint256 _fertilizedTil = _seed.lastFertilizedAt + fertilizerAmount / uint256(_fertilizerUseFactor(_seed));
        // Did the tree ran out of fertilizer before now ?
        uint256 _fertilizedTilNow = Math.min(block.timestamp, _fertilizedTil);
        // Calculate the fruit mass by adding the previously unharvested fruits and calculating the newly produced mass
        return _seed.lastFruitMass + uint256(_fruitGrowthFactor(_seed)) * (_fertilizedTilNow - _seed.lastSnapshotedAt) / 3600;
    }

    // Check if the seed is planted to protect against landId = 0 default value that is a valid Land value (0,0)
    function _isPlanted(TreeData storage _seed) internal view returns (bool) {
        // lastSnapshotedAt is first initialized with the `_initializeState()`, when we plant the seed
        return _seed.lastSnapshotedAt != 0;
    }

    // Check if the seed is adult
    function _isAdult(uint256 _seedId) internal view returns (bool) {
        return state(_seedId) == TreeState.ADULT;
    }

    /// Check if the land is already taken
    function _isLandTaken(uint16 _landId) internal view returns (bool) {
        return seedByLandId(_landId) != type(uint256).max;
    }

    // FIXME: 🚨 ONLY FOR DEBUGGING PURPOSES. TO REMOVE BEFORE DEPLOYMENT 🚨 
    function _debugForceSetMass(uint256 _seedId, uint256 _treeMass) external {
        treeData[_seedId].lastMass = _treeMass;
    }

    // FIXME: 🚨 ONLY FOR DEBUGGING PURPOSES. TO REMOVE BEFORE DEPLOYMENT 🚨 
    function _debugForceSetFruitMass(uint256 _seedId, uint256 _treeFruitMass) external {
        treeData[_seedId].lastFruitMass = _treeFruitMass;
    }

    /// Calculate the entire game state
    function gameState() external view returns (LandState[1024] memory _landState) {
        // Loop over every lands
        for (uint16 i = 0; i < land.totalSupply(); i++) {
            // Get the land's owner
            _landState[i].landOwner = land.ownerOf(i);
            // Get the land's type
            _landState[i].landType = land.landTypes(i);
            // Get the land's seed id
            uint256 _seedId = seedByLandId(i);
            _landState[i].seedId = _seedId;
            _landState[i].seedSpecies = _species(treeData[_seedId]);
            _landState[i].seedState = state(_seedId);
            _landState[i].unharvestedFruits = unharvestedFruitCount(_seedId);
        }
    }

    /* --- Seed trait functions --- */

    function traits(uint256 _seedId) external view returns (uint8 species, uint8 growthFactor, uint8 waterUseFactor, uint8 fertilizerUseFactor, uint8 fruitGrowthFactor) {
        TreeData storage _seed = treeData[_seedId];
        return (_species(_seed), _growthFactor(_seed), _waterUseFactor(_seed), _fertilizerUseFactor(_seed), _fruitGrowthFactor(_seed));
    }

    /// Get the seed's dna
    function dna(uint256 _seedId) external view returns (uint32) {
        return treeData[_seedId].dna;
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

    // Get the tree's species
    function _species(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _speciesLastBitPosition, _speciesMask);
    }

    // Calculate the tree's growth factor
    function _growthFactor(TreeData storage _seed) internal view returns (uint8) {
        // TODO: use the land with the seed trait instead
        return _traitFromDNA(_seed.dna, _treeGrowthFactorLastBitPosition, _treeGrowthFactorMask);
    }

    // Calculate the tree's water use factor
    function _waterUseFactor(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _treeWaterUseFactorLastBitPosition, _treeWaterUseFactorMask);
    }

    // Calculate the tree's fertilizer use factor
    function _fertilizerUseFactor(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _treeFertilizerUseFactorLastBitPosition, _treeFertilizerUseFactorMask);
    }

    // Calculate the tree's fruit growth factor
    function _fruitGrowthFactor(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _fruitGrowthFactorLastBitPosition, _fruitGrowthFactorMask);
    }

    /* Still needed ?
    // Calculate the tree's longevity
    function _longevity(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _longevityLastBitPosition, _longevityMask);
    }

    function _fruitColor(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _fruitColorLastBitPosition, _fruitColorMask);
    }

    function _leaveColor(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _leaveColorLastBitPosition, _leaveColorMask);
    }

    function _extraColor(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _extraColorLastBitPosition, _extraColorMask);
    }

    function _extraCosmetic(TreeData storage _seed) internal view returns (uint8) {
        return _traitFromDNA(_seed.dna, _extraCosmeticLastBitPosition, _extraCosmeticMask);
    }
    */

    /* --- Other functions --- */

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