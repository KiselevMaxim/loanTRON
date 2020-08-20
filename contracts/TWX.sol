pragma solidity ^0.5.4;

import "./TRC20.sol";

contract TWX is TRC20 {

  string public constant name    = "TWX token";
  string public constant symbol  = "TWX";
  uint8 public constant decimals = 6;

  uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}
