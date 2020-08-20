pragma solidity ^0.5.4;

import "./TRC20.sol";

contract ANTE is TRC20 {

  string public constant name    = "ANTE token";
  string public constant symbol  = "ANTE";
  uint8 public constant decimals = 6;

  uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}
