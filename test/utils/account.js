const {accounts, config, network} = require('hardhat');
const {mnemonicToSeed} = require('bip39');
const {hdkey} = require('ethereumjs-wallet');

async function getWallet(mnemonic, derivationPath, index) {
  const seed = await mnemonicToSeed(mnemonic);
  const hdKey = hdkey.fromMasterSeed(seed);
  const addressNode = hdKey.derivePath(`${derivationPath}/${index}`);
  return addressNode.getWallet();
}

async function getPrivateKey(mnemonic, index, derivationPath = "m/44'/60'/0'/0") {
  const wallet = await getWallet(mnemonic, derivationPath, index);
  return wallet.getPrivateKey();
}

async function getPrivateKeyHardhat(account) {
  const accountsInfo = config.networks[network.name].accounts;
  const index = accounts.findIndex((item) => item.toLowerCase() === account.toLowerCase());

  if (index === -1) {
    throw new Error(`Unable to retrieve private key for unknown account.`);
  }

  const wallet = await getWallet(accountsInfo.mnemonic, accountsInfo.path, index);
  const walletAddress = `0x${wallet.getAddress().toString('hex')}`;

  if (walletAddress.toLowerCase() !== account.toLowerCase()) {
    // This issue was discovered when running the gas-report Hardhat task with Ganache as the
    // localhost network. This function depends upon the default or configured Hardhat network
    // account mnemonic. Configuring the localhost network account generation with the mnemonic
    // used for the Hardhat network will allow this function to be used for the localhost network.
    // By default Hardhat uses 'test test test test test test test test test test test junk' as
    // the mnemonic for its network.
    throw new Error(`Unable to retrieve private key. Specified account was not generated for the Hardhat network.`);
  }

  return wallet.getPrivateKey();
}

module.exports = {
  getWallet,
  getPrivateKey,
  getPrivateKeyHardhat,
};
