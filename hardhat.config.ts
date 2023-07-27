import dotenv from "dotenv";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();

const mainnetUrl = `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_MAINNET_API_KEY}`;
const sepoliaUrl = `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_SEPOLIA_API_KEY}`;
const goerliUrl = `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_API_KEY}`;
const mumbaUrl = `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_MUMBAI_API_KEY}`;

const mainnetChainId = 1;
const sepoliaChainId = 11155111;
const goerliChainId = 5;
const mumbaChainId = 80001;

const privateKey = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  mocha: {
    timeout: '100000'
  },
  networks: {
    hardhat: {
      forking: {
        url: goerliUrl,
        chainId: goerliChainId
      },
      saveDeployments: true
    },
    mainnet: {
      url: mainnetUrl,
      chainId: mainnetChainId,
      accounts: [privateKey],
      saveDeployments: true
    },
    sepolia: {
      url: sepoliaUrl,
      chainId: sepoliaChainId,
      accounts: [privateKey],
      saveDeployments: true
    },
    goerli: {
      url: goerliUrl,
      chainId: goerliChainId,
      accounts: [privateKey],
      saveDeployments: true,
      addressSet: 'goerli'
    },
    mumbaUrl: {
      url: mumbaUrl,
      chainId: mumbaChainId,
      accounts: [privateKey],
      saveDeployments: true
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true" ? true : false,
    currency: "USD"
  },
  etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
   },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6"
  },
  abiExporter: {
    path: './abis',
    flat: false,
    format: "json"
  },
  contractSizer: {
    alpha: true,
    runOnCompile: true,
    disambiguatePaths: false,
  }

}