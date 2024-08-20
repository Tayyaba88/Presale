require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.MAINNET_API_KEY,
      // sepolia: "",
    },
  },
  defaultNetwork: "mainnet",
  networks: {
    mainnet: {
      url: process.env.MAINNET_URL,
      chainId: 1,
      accounts: [process.env.WALLET_ACCOUNT],
    },
  },
};
