import {ethers, network} from "hardhat";
import {sleep, verify} from "../utils/helpers";


async function main() {
    const [deploer] = await ethers.getSigners();

    console.log("- Deploy Token - ");

    const Token = await ethers.getContractFactory("Add3Token");
    const token = await Token.deploy("Add3Token", "ADD3", 10000000000);
    await token.deployed();
    const tokenAddress = await token.address;

    await sleep(1000);
    await verify(
        tokenAddress, 
        [
            "Add3Token",
            "ADD3",
            10000000000
        ]
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });