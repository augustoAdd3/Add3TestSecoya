Staking contract development with hardhat

# Contracts Dev

### Features

ERC20Token, Token Staking, Token Claim, Token Unstaking, Token Withdraw

### Install

```
yarn install
```

### Compile

```
yarn compile
```

### Configuration

create .env file

#### For multilogic deployment:

- **PRIVATE_KEY** - Private key of account that is using for deployment or test
- **ETHERSCAN_APIKEY** - etherscan API KEY
- **ALCHEMY_MAINNET_API_KEY** - Ethereum mainnet api key
- **ALCHEMY_SEPOLIA_API_KEY** - Sepolia testnet api key
- **ALCHEMY_GOERLI_API_KEY** -  Goerli testnet api key
- **ALCHEMY_MUMBAI_API_KEY** -  Mumbai testnet api key
- **TEST_ADD3TOKEN_ADDRESS** -  Goerli test token address
- **TEST_STAKING_ADDRESS**   -  Goerli staking address

### Artifacts

We use openzeppelin upgradable artifcast and we should to keep it fresh for upgrading.

We keep artifacts in **contract_artifacts** directory. With this scheme:

```
./contract_artifacts/
./contract_artifacts/{env_name}/
./contract_artifacts/{env_name}/{purpose_name}/
./contract_artifacts/{env_name}/{purpose_name}/openzeppelin/
./contract_artifacts/{env_name}/{purpose_name}/openzeppelin/unknown-56.json
```

### Deployment

- Token Deploy Command

```

yarn deploy-token --network [network_name]

```

- Staking Contract Deploy Command

```

yarn deploy-staking --network [network_name]

```

### Verify

```

npx hardhat verify --network bsc [Proxy Address]

````

### Testing

- Test Command

  For all tests:

  ```
  yarn test
  ```

  For local/ci-cd tests:

  ```
  yarn test:token
  yarn test:staking
  ```

### Versioning

- `Dynamic`, `Static`, `AutoCompound` mode for staking contract

`Dynamic` mode is working like that the staker can claim when they want even the staking period is not ended
`Static` mode is working like that the staker can claim only after the period is ended.
`AutoCompound` mode is working like auto stake when user claim