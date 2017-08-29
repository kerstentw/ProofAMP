contract TheContractFactory {

  mapping (bytes32 => address) public deployer;
  mapping (bytes32 => bytes) public code;

  function deployCode(bytes _code) returns (address deployedAddress) {
    assembly {
      deployedAddress := create(0, add(_code, 0x20), mload(_code))
      jumpi(invalidJumpLabel, iszero(extcodesize(deployedAddress))) // jumps if no code at addresses
    }
    ContractDeployed(deployedAddress);
  }

  function uploadCode(string identifier, bytes o_code) onlyOrNone(deployer[identifierHash(identifier)]) returns (bytes32) {
    bytes32 h = identifierHash(identifier);

    code[h] = o_code;
    deployer[h] = msg.sender;

    NewCode(identifier);
    return h;
  }

  function deploy(string identifier) {
    bytes c = code[identifierHash(identifier)];
    if (c.length == 0) throw;

    NewContract(deployCode(c), msg.sender, identifier);
  }

  function identifierHash(string identifier) returns (bytes32) {
    return sha3(identifier);
  }


  modifier onlyOrNone(address x) {
    if (x != 0x0 && x != msg.sender) throw;
    _;
  }

  event NewContract(address x, address indexed owner, string indexed identifier);
  event NewCode(string indexed identifier);
  event ContractDeployed(address deployedAddress);
}