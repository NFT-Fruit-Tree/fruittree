//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fertilizer is ERC20 {

    constructor() ERC20("Fertilizer", "FLZ") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}