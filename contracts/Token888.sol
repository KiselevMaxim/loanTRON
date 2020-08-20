pragma solidity ^0.5.4;

import "./TRC20.sol";

contract Token888 is TRC20 {

  string public constant name    = "888 token";
  string public constant symbol  = "888";
  uint8 public constant decimals = 6;

  uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}
