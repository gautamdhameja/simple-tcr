pragma solidity ^0.5.8;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    address public owner;

    string public constant name = "DemoToken";                        // Set the token name for display
    string public constant symbol = "DTO";                            // Set the token symbol for display

    // SUPPLY
    uint256 public constant initialSupply = 21000000;                 // Token total supply

    // constructor function
    constructor() public {
        // set _owner
        owner = msg.sender;

        // owner of token contract has all tokens
        _mint(msg.sender, initialSupply);
    }
}