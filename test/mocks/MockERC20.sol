// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockERC20 is ERC20, ERC20Burnable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public returns (bool) {
        _mint(to, amount);
        return true;
    }
}
