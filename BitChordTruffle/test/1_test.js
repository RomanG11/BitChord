var Crowdsale = artifacts.require("BitChordCrowdsale");
var Token = artifacts.require("TokenERC20");

// var TokenPrice = 1000000000000000;
var decimals = 18
var tokensToSend = 1000000000000000000;

expect = require("chai").expect;

var TokenInstance;
var CrowdsaleInstance;

contract("tokenContract", function(accounts){
  it ("catch an instance of tokenContract", function(){
    return Token.deployed().then(function(instance){
      TokenInstance = instance;
      console.log("tokenContract = " + TokenInstance.address);
    });
  });
  contract("CrowdsaleContract", function(accounts){
    it ("catch an instance of crowdsaleContract", function(){
      return Crowdsale.deployed().then(function(instance){
        CrowdsaleInstance = instance;
        console.log("CrowdsaleInstance = " + CrowdsaleInstance.address);
      });
    });
    it ("send supply to crowdsale contract", function(){
      return TokenInstance.transfer(CrowdsaleInstance.address, tokensToSend * Math.pow(10,decimals)).then(function(res){
        expect (res.toString()).to.not.be.an("error");
      })
    })
    it ("check owner balace", function(){
      return TokenInstance.balanceOf(accounts[0]).then(function(res){
        console.log(res.toString());
        expect(res.toString()).to.be.equal("0");
      })
    })
    it ("check crowdsale balance", function(){
      return TokenInstance.balanceOf(CrowdsaleInstance.address).then(function(res){
        console.log(res.toString());
        expect(res.toString()).to.be.equal((tokensToSend * Math.pow(10,decimals)).toString());
      })
    })
    
    it("check user1 tokenBalance", function(){
      return TokenInstance.balanceOf(accounts[1]).then(function(res){
        console.log(res.toString());
        expect(res.toString()).to.be.equal("0");
      })
    })
    it("user1 send (1 eth)", function(){
      return web3.eth.sendTransaction({from: accounts[1], to: CrowdsaleInstance.address, value: 1000000000000000000, gas: 2000000})
    })
    it("check his tokenBalance again", function(){
      return TokenInstance.balanceOf(accounts[1]).then(function(res){
        console.log(res.toString());
        expect(res.toString()).to.be.not.equal("0");
      })
    })

    
  })
})
