//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * The Land contract of the `nft-fruit-tree` game.
 */
contract Land is ERC721 {

    constructor() ERC721("Land", "LAND") {

    }
}