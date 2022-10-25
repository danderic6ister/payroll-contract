// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./template.sol";

contract EmployeePaymentToken is ERC20{

    string private _name = "EmployeePaymentToken";
    string private _symbol= "EPT";
    address private _owner;
    uint256 private constant _totalSupply = 220000000 * 10 ** 18;
   

    constructor()ERC20(_name,_symbol){
        _owner=msg.sender;
        _mint(msg.sender,_totalSupply);
    }

  
      

}