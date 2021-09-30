//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Currency is ERC20 {

    constructor() ERC20("Currency", "Crc") {}

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}