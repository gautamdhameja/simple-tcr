pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract Token is StandardToken {
    address public owner;

    string public constant name = "DemoToken";                        // Set the token name for display
    string public constant symbol = "DTO";                            // Set the token symbol for display

    // SUPPLY
    uint256 public totalSupply;
    uint8 public constant decimals = 0;                               // Set the number of decimals for display
    uint256 public constant initialSupply = 21000000;                 // Token total supply

    // constructor function
    constructor() public {
        // set _owner
        owner = msg.sender;

        // total supply
        totalSupply = initialSupply;

        // owner of token contract has all tokens
        balances[msg.sender] = initialSupply;
    }
}