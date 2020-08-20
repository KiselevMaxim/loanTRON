//var loanTRON_migration  = artifacts.require("./loanTRON.sol");
var loanMarket_migration  = artifacts.require("./loanMarket.sol");
var ANTE_migration        = artifacts.require("./ANTE.sol");
var TWX_migration         = artifacts.require("./TWX.sol");
var Token888_migration    = artifacts.require("./Token888.sol");
var USDT_migration        = artifacts.require("./USDT.sol");

module.exports = function(deployer) {
  //deployer.deploy(loanTRON_migration);
  deployer.deploy(loanMarket_migration);
  deployer.deploy(ANTE_migration);
  deployer.deploy(TWX_migration);
  deployer.deploy(Token888_migration);
  deployer.deploy(USDT_migration);
};