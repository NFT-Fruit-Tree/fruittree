pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockGtc is ERC20 {

    constructor () public ERC20("GTC", "GTC") {
        _mint(0xf88b0247e611eE5af8Cf98f5303769Cba8e7177C, 100 ether);
     }
}