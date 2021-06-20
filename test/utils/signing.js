const {web3} = require('hardhat');
const {ecsign} = require('ethereumjs-util');

const SIGNED_MESSAGE_PREFIX = '0x1901';

function dependencies(typedData, primaryType, found = []) {
  if (found.includes(primaryType)) {
    return found;
  }
  if (typedData.types[primaryType] === undefined) {
    return found;
  }
  found.push(primaryType);
  for (let field of typedData.types[primaryType]) {
    for (let dep of dependencies(typedData, field.type, found)) {
      if (!found.includes(dep)) {
        found.push(dep);
      }
    }
  }
  return found;
}

function encodeType(typedData, primaryType) {
  // Get dependencies primary first, then alphabetical
  let deps = dependencies(typedData, primaryType);
  deps = deps.filter((t) => t != primaryType);
  deps = [primaryType].concat(deps.sort());

  // Format as a string with fields
  let result = '';
  for (let type of deps) {
    result += `${type}(${typedData.types[type].map(({name, type}) => `${type} ${name}`).join(',')})`;
  }
  return result;
}

function typeHash(typedData, primaryType) {
  return web3.utils.sha3(encodeType(typedData, primaryType));
}

function encodeData(typedData, primaryType, data) {
  let encTypes = [];
  let encValues = [];

  // Add typehash
  encTypes.push('bytes32');
  encValues.push(typeHash(typedData, primaryType));

  // Add field contents
  for (let field of typedData.types[primaryType]) {
    let value = data[field.name];
    if (field.type == 'string' || field.type == 'bytes') {
      encTypes.push('bytes32');
      value = web3.utils.sha3(value);
      encValues.push(value);
    } else if (typedData.types[field.type] !== undefined) {
      encTypes.push('bytes32');
      value = web3.utils.sha3(encodeData(typedData, field.type, value));
      encValues.push(value);
    } else if (field.type.lastIndexOf(']') === field.type.length - 1) {
      throw 'TODO: Arrays currently unimplemented in encodeData';
    } else {
      encTypes.push(field.type);
      encValues.push(value);
    }
  }

  return web3.eth.abi.encodeParameters(encTypes, encValues);
}

function structHash(typedData, primaryType, data) {
  return web3.utils.sha3(encodeData(typedData, primaryType, data));
}

function domainSeparator(typedData) {
  return web3.utils.stripHexPrefix(structHash(typedData, 'EIP712Domain', typedData.domain));
}

function message(typedData) {
  return web3.utils.stripHexPrefix(structHash(typedData, typedData.primaryType, typedData.message));
}

function signHash(typedData) {
  return web3.utils.sha3(`${SIGNED_MESSAGE_PREFIX}${domainSeparator(typedData)}${message(typedData)}`);
}

function signTypedData(typedData, privateKey) {
  const signHashString = signHash(typedData);
  const signHashBuffer = Buffer.from(web3.utils.stripHexPrefix(signHashString), 'hex');
  return ecsign(signHashBuffer, privateKey);
}

function signTypedDataRpc(address, typedData, method = 'eth_signTypedData') {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        method,
        params: [address, typedData],
        jsonrpc: '2.0',
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          reject(err);
        } else {
          resolve(result.result);
        }
      }
    );
  });
}

module.exports = {
  domainSeparator,
  signTypedData,
  signTypedDataRpc,
};
