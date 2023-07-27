import {ethers, upgrades} from "hardhat";
import type { ContractFactory } from 'ethers';
import {sleep, verify} from "../utils/helpers";

async function main() {

    const stakingToken = "0xB1ed2cF9Fe1C986141BB7456D5190F5b469cf596";
    const Staking = await ethers.getContractFactory("Staking");
    const staking = await upgrades.deployProxy(
        Staking as unknown as ContractFactory,
        [
            stakingToken,
            true,
            true,
            10
        ],
        {
            kind: "uups",
            initializer: "__Staking_init"
        }
        );
    await staking.deployed();
    const stakingImpl = await upgrades.erc1967.getImplementationAddress(
        staking.address
    );
    console.log("Staking Proxy", staking.address);
    console.log("Staking Implement:", stakingImpl);
    
    await verify(staking.address);
    await verify(stakingImpl);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });