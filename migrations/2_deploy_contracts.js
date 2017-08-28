var Promise = require('bluebird');

var ProofToken = artifacts.require('./ProofToken.sol')
var SafeMath = artifacts.require('./SafeMath.sol');
var 


let defaultGas = 4712388;
let defaultGasPrice = 1000000000;

module.exports = function(deployer, network, accounts) {


  if (network == "development") {

    deployer.deploy(SafeMath, {gas: defaultGas, gasPrice: defaultGasPrice });
    deployer.link(SafeMath, CryptoFiat);
    deployer.link(SafeMath, CUSDToken);
    deployer.link(SafeMath, CEURToken);
    deployer.link(SafeMath, ProofToken);

    Promise.map(tokens, function(token) {
      return deployer.deploy(token);
    }).then(function() {

      deployer.deploy(CryptoFiat, 
                      CUSDToken.address, 
                      CEURToken.address, 
                      ProofToken.address,
                      {gas: defaultGas, gasPrice: defaultGasPrice});
    });

  }
  
};