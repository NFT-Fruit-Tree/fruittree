//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * The Fruit contract of the `nft-fruit-tree` game.
 */
contract Fruit is ERC20 {

    constructor() ERC20("Fruit", "FRT") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}