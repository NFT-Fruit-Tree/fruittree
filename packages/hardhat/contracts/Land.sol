//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { UnauthorizedError, TransferError } from "./Shared.sol";

/**
 * The Land contract of the `nft-fruit-tree` game.
 */
contract Land is ERC721, ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _boughtTokenNumber;

    uint8 constant gridSide = 32;
    uint16 constant gridArea = 1024; // gridSide ** 2

    ERC20 immutable currency; // The ERC20 token used a currency
    uint256 immutable currencyUnits; // 10 ** currency.decimals()

    // Mapping from the land id to its land type
    mapping (uint16 => uint8) public landTypes;

    /// The given coordinates x=`x` and y=`y` should be inside the bounds
    error OutOfBounds(uint8 x, uint8 y);

    constructor(address _currencyAddress) ERC721("Land", "LAND") {
        currency = ERC20(_currencyAddress);
        currencyUnits = 10 ** ERC20(_currencyAddress).decimals();
    }

    /* --- Land actions functions --- */
    
    /// Buy a purchasable land for a calculated price.
    function buy(uint16 _landId) external {
        // Check if the land already exists and it is buyable (i.e. its owner is this contract) 
        if (ownerOf(_landId) != address(this)) revert UnauthorizedError();
        // Calculate the land price
        uint256 _price = price();
        // Increment the bough token counter
        _boughtTokenNumber.increment();
        // Transfer this amount to this contract. Revert if not approved or not enough funds.
        if (!currency.transferFrom(msg.sender, address(this), _price)) revert TransferError(address(currency), msg.sender, address(this), _price);
        // Transfer ownership of this land to the sender
        _safeTransfer(address(this), msg.sender, _landId, "");
    }

    /* --- Land helper functions --- */

    /// Calculate the land price
    function price() public view returns (uint256) {
        uint256 _price = _boughtTokenNumber.current() ** 2 * currencyUnits / gridArea;
        return Math.max(_price, 1 * currencyUnits);
    }

    // Generate the land type from the land id, block timestamp, block difficulty.
    // FIXME: 🚨 Only pseudo random
    function _generateType(uint16 _landId) internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _landId))) % 8);
    }

    // Premint the land token from index `from` to `to`
    function premint(uint16 from, uint16 to) external onlyOwner {
        uint16 _max = uint16(Math.min(to, gridArea));
        for (uint16 i = from; i < _max; i++) {
            _mint(address(this), i);
            landTypes[i] = _generateType(i);
        }
    }

    /* --- Coordinates / Id functions --- */

    /// Get the land id from its coordinates
    function idFromCoordinates(uint8 _x, uint8 _y) public pure returns (uint16) {
        if (_x >= gridSide || _y >= gridSide) revert OutOfBounds(_x, _y);
        unchecked { return uint16(_x) + uint16(_y) * gridSide; }
    }

    /// Get the land's coordinates from its id
    function idToCoordinates(uint16 _landId) public pure returns (uint8 x, uint8 y) {
        unchecked {
            x = uint8(_landId % gridSide);
        }
        y = uint8(_landId / gridSide);
        if (y >= gridSide) revert OutOfBounds(x, y);
    }

    // function safeTransfer(address _to, uint256 _tokenId) external {
    //     _safeTransfer(msg.sender, _to, _tokenId, "");
    // }

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