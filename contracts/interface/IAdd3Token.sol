// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <=0.8.20;

interface IAdd3Token {
    function burn(uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Paused(address account);
    event Unpaused(address account);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
}
