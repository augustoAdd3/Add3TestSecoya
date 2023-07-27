// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Add3Token is ERC20, Ownable, Pausable {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10**decimals()));
    }

    // Burn tokens from the sender's balance
    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    // Mint new tokens and send them to the specified address
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    // Pause the contract to prevent certain functionalities
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause the contract to re-enable functionalities
    function unpause() public onlyOwner {
        _unpause();
    }

    // Overriding the transfer and transferFrom functions to check for paused state
    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}