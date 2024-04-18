// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC900 {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 _amount, bytes memory _data) external;

    function stakeFor(address _user, uint256 _amount, bytes memory _data) external;

    function unstake(uint256 _amount, bytes calldata _data) external;

    function totalStakedFor(address _addr) external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function token() external view returns (address);

    function supportsHistory() external pure returns (bool);
}
