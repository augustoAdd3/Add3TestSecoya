import {run} from "hardhat";
import {NomicLabsHardhatPluginError} from "hardhat/plugins";

export const sleep = (ms: number) => {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}

export const verify = async (address: string, param: any = []) => {
    try {
        console.log("Verifying: ", address);
        await run("verify", {
            address,
            constructorArguments: param,
        });
    } catch (error: any) {
        if (
            error instanceof NomicLabsHardhatPluginError &&
            error.message.includes("Reason: Already Verified")
        ) {
            console.log("Already verified, skipping...");
        } else {
            console.error(error);
        }
    }
}