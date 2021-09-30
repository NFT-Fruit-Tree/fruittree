//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TransferError } from "./Shared.sol";

/**
 * The Fruit contract of the `nft-fruit-tree` game.
 */
contract Fruit is ERC20 {

    uint256 constant public initialSupply = 1_000_000;
    uint256 constant public price = 2; // The price Currency/Fruit
    
    ERC20 immutable currency; // The ERC20 token contract used as currency

    constructor(address _currencyAddress) ERC20("Fruit", "FRT") {
        ERC20 _token = ERC20(_currencyAddress);
        currency = _token;
        // Mint the initial token supply
        _mint(address(this), initialSupply * 10 ** decimals());
    }

    /// Buy some fruit token for a fixed price with some token
    function buy(uint256 _amount) external {
        // Calculate the currency paid
        uint256 _currencyAmount = _amount / price;
        // Transfer a fixed amount of currency to this contract
        if (!currency.transferFrom(msg.sender, address(this), _currencyAmount)) revert TransferError(address(currency), msg.sender, address(this), _currencyAmount);
        // Transfer a fixed amount of currency to this contract
        _transfer(address(this), msg.sender, _amount);
    }
}