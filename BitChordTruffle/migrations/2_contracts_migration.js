var Crowdsale = artifacts.require("./BitChordCrowdsale.sol");
var Token = artifacts.require("./TokenERC20.sol")
// Token = "0xE7207901406978FC6e443C057A316c103495C474";

var address = web3.eth.accounts[0];
module.exports = function(deployer) {
  deployer.deploy(Token,1000000000000000000,"TEST","TST").then(function(){
  	return deployer.deploy(Crowdsale,Token.address,address);

  });
}