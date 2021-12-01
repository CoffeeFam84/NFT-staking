// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract YieldToken is ERC20("Dustz", "DTZ") {
uint public cost = 0.05 ether;
address public conAddress;
 constructor() {}

  function mint(uint256 _mintAmount) public payable { 
    // require(msg.value >= cost * _mintAmount, "Not enough funds!");
      _mint(conAddress, _mintAmount);
  }
	function setConAddress(address contractAddr) external onlyOwner {
		conAddress = contractAddr;
	}  
}