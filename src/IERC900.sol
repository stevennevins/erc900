// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface for ERC900, a standard interface for staking tokens
interface IERC900 {
    /// @notice Emitted when a user stakes tokens
    /// @param user The address of the user who staked tokens
    /// @param amount The amount of tokens staked
    /// @param total The total amount of tokens staked by the user after the operation
    /// @param extraData Additional data with no specified format, used for logging
    event Staked(address indexed user, uint256 amount, uint256 total, bytes extraData);

    /// @notice Emitted when a user unstakes tokens
    /// @param user The address of the user who unstaked tokens
    /// @param amount The amount of tokens unstaked
    /// @param total The total amount of tokens staked by the user after the operation
    /// @param extraData Additional data with no specified format, used for logging
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes extraData);

    /// @notice Stakes a certain amount of tokens
    /// @param amount The amount of tokens to stake
    /// @param extraData Additional data with no specified format
    function stake(uint256 amount, bytes memory extraData) external;

    /// @notice Stakes a certain amount of tokens on behalf of another user
    /// @param user The address of the user for whom to stake tokens
    /// @param amount The amount of tokens to stake
    /// @param extraData Additional data with no specified format
    function stakeFor(address user, uint256 amount, bytes memory extraData) external;

    /// @notice Unstakes a certain amount of tokens
    /// @param amount The amount of tokens to unstake
    /// @param extraData Additional data with no specified format
    function unstake(uint256 amount, bytes memory extraData) external;

    /// @notice Gets the total amount of tokens staked for a particular user
    /// @param user The address of the user
    /// @return The total amount of tokens staked by the user
    function totalStakedFor(address user) external view returns (uint256);

    /// @notice Gets the total amount of tokens staked in the contract
    /// @return The total amount of tokens staked
    function totalStaked() external view returns (uint256);

    /// @notice Returns the address of the token used for staking
    /// @return The address of the ERC20 token used for staking
    function token() external view returns (address);

    /// @notice Determines whether the contract supports staking history
    /// @return True if staking history is supported, false otherwise
    function supportsHistory() external pure returns (bool);
}
