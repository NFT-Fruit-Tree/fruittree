//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Land } from "./Land.sol";

/// You are not authorized to do this action
error Unauthorized();
/// You did not send enough funds
error InsuffisantFundsError();
/// The `symbol` transfer from `from` to `to` for `amount` failed
error TransferError(string symbol, address from, address to, uint256 amount);

/**
 * The Seed contract of the `nft-fruit-tree` game.
 */
contract Seed is ERC721, ERC721Enumerable {

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
        uint8 fertilizerAmount; // constant, maybe varies by Species
        uint8 fertilizerUseRate; // constant, maybe varies by Species
        uint8 dehydrateRate; // water lost per hour: =4 means 0 in 24 hours. could vary by Species.
        // Tree characteristics
        uint256 lastFertilized; // 
        uint256 lastWatered; // timestamp. implies that waterMeter = 100 @ lastWatered
        uint256 landId; // id of the tree's land
        //uint8 lastFruitMass; // 
        //uint16 lastMass; // last always means last saved. 
    }

    // Mapping from a Seed token Id to its TreeData
    mapping (uint256 => TreeData) treeDatas;
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

    constructor(address _landAddress, address _fertilizerAddress) ERC721("Seed", "SEED") {
        land = Land(_landAddress);
        fertilizer = ERC20(_fertilizerAddress);
    }

    function getWaterLevel(uint256 _treeId) public view returns (uint256) {
        uint256 lastWatered = treeDatas[_treeId].lastWatered;
        uint8 dehydrateRate = treeDatas[_treeId].dehydrateRate;
        int256 waterLevel = int(100 - dehydrateRate * (block.timestamp - lastWatered));
        return waterLevel < 0 ? 0 : uint256(waterLevel);
    }

    function getState(uint256 _seedId) public view returns (TreeState) {

    }

    /**
     * Buy a new seed with random characteristics.
     * @dev Mint a new Seed token. See {ERC721-_safeMint}
     */
    function buy() external payable {}
    /**
     * Plant one of `your` `seeds` into one of `your` `lands`. It will consume some of your fertilizer.
     * @dev Create a soft link from a Seed token to a Land token. The Seed token remains controlled by its owner, unlike a staking action.
     * It will initialize its TreeData.
     */
    function plant(uint256 _seedId, uint256 _landId) external {
        // Check if the token exists and if the sender owns the seed AND the land
        if (ownerOf(_seedId) != msg.sender || land.ownerOf(_landId) != msg.sender) revert Unauthorized();
        // Check if the seed is not already planted
        if (treeDatas[_seedId].landId != 0) revert AlreadyPlantedError();
        // Transfer the amount of fertilizer from the sender to this contract
        if (!fertilizer.transferFrom(msg.sender, address(this), treeDatas[_seedId].fertilizerAmount)) revert TransferError(fertilizer.symbol(), msg.sender, address(this), treeDatas[_seedId].fertilizerAmount);
        // Initialize the tree data
        treeDatas[_seedId].landId = _landId;
        treeDatas[_seedId].lastFertilized = block.timestamp;
        treeDatas[_seedId].lastWatered = block.timestamp;
        // Events
        emit Planted(_seedId, _landId);
        emit Fertilized(_seedId, treeDatas[_seedId].fertilizerAmount);
        emit Watered(_seedId);
    }

    /**
     * Fertilize one of `your` `alive` trees with some token to boost its fruit production capacity.
     * @dev It is somewhat similar to staking some token for an unlimited time.
     * It will persist the new state data.
     */
    function fertilize(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_treeId) != msg.sender) revert Unauthorized();
        // Transfer the amount of fertilizer from the sender to this contract
        if (!fertilizer.transferFrom(msg.sender, address(this), treeDatas[_treeId].fertilizerAmount)) revert TransferError(fertilizer.symbol(), msg.sender, address(this), treeDatas[_treeId].fertilizerAmount);
        // Update the tree state
        treeDatas[_treeId].lastFertilized = block.timestamp;
        // Event
        emit Fertilized(_treeId, treeDatas[_treeId].fertilizerAmount);
    }
    /**
     * Water one of `your` `alive` `trees` to maintain it `alive`. A dead tree cannot grow or produce fruit anymore.
     */
    function water(uint256 _treeId) external {
        // Check if the token exists and if the sender owns the tree
        if (ownerOf(_treeId) != msg.sender) revert Unauthorized();
        // Check if it is not a seed or dead
        TreeState treeState = getState(_treeId);
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
        if (ownerOf(_treeId) != msg.sender || land.ownerOf(_newLandId) != msg.sender) revert Unauthorized();
        // Check if it is not a seed or dead
        TreeState treeState = getState(_treeId);
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
        if (ownerOf(_treeId) != msg.sender) revert Unauthorized();
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