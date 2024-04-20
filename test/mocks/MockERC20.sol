// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title MockToken
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Inherits from ERC20, ERC20Burnable and Ownable from OpenZeppelin.
 */
contract MockERC20 is ERC20, ERC20Burnable{
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public returns (bool) {
        _mint(to, amount);
        return true;
    }
}
