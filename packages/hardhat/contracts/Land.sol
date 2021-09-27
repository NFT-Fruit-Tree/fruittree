//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * The Land contract of the `nft-fruit-tree` game.
 */
contract Land is ERC721, ERC721Enumerable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Land", "LAND") {
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function safeTransfer(address _to, uint256 _tokenId) external {
        _safeTransfer(msg.sender, _to, _tokenId, "");
    }

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