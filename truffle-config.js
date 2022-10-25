require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */
  contracts_directory: './contracts',
  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache, geth, or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 7545, // Standard Ethereum port (default: none)
      network_id: '4', // Any network (default: none)
    },

    // Useful for deploying to a public network.
    // Note: It's important to wrap the provider as a function to ensure truffle uses a new provider every time.
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          process.env.seed,
          `wss://rinkeby.infura.io/ws/v3/${process.env.INFURA_API_KEY}`
        ),
      network_id: 4, // Rinkeby's id
      gas: 5500000,

      confirmations: 2, // # of confirmations to ait between deployments. (default: 0)
      timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)

      skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
    },
    //
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: '0.8.15', // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
  plugins: ['truffle-plugin-verify', 'truffle-flatten'],
  api_keys: {
    etherscan: '4K4CACKSZDRWQP9HCX4K58GSVDA2SAYKKC',
  },
};
