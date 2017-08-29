var Promise = require('bluebird');

import { gas, gasPrice, ether } from '../scripts/testConfig.js';
import { waitUntilTransactionsMined } from '../scripts/helper.js';



/**
 * @description Transfer the ownership of a contract from the sender to the receiver
 * @param contract 
 * @param sender 
 * @param receiver 
 */
const transferOwnership = async (contract, sender, receiver) => {
    let params = {from: sender, gas: gas};
    let txn = await contract.transferOwnership(receiver, params);
    let txnReceipt = await waitUntilTransactionsMined(txn.tx);
}


/**
 * @description Transfer the ownership of an array of contracts from the sender to the receiver
 * @param contracts Array of contracts to be transferred
 * @param sender 
 * @param receiver 
 */
const transferOwnerships = async (contracts, sender, receiver) => {
    let params = {from: sender, gas: gas};
    let promises = contracts.map(function(contract) { transferOwnership(contract, sender, receiver) });
    await Promise.all(promises);
}

/**
 * @description Lock the ownership of a contract. 
 * @param contract 
 * @param owner This method will be successful only if called by the user of the smart contract
 */
const lockOwnership = async (contract, owner) => {
    let params = { from: owner, gas: gas };
    let txn = await contract.lockOwnership(owner, params);
    let txnReceipt = await waitUntilTransactionsMined(txn.tx);
}


module.exports = {
    transferOwnership,
    transferOwnerships,
    lockOwnership
}