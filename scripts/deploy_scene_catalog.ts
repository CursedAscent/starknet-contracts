import { Account, ec, ProviderOptions, Signer, json, Contract } from "starknet";
import fs from "fs";
import { toBN } from "starknet/dist/utils/number";

const CONTRACT_NAME="SceneCatalog";

function generateDefaultCalldata() {
    let calldata: any[] = [];

    return calldata;
}

export async function deploySceneCatalog (calldataCallback?: Function) {
    console.log("["+CONTRACT_NAME+"] - [~] - Setting up env and payload for deployment");
    console.log("["+CONTRACT_NAME+"] - [~] - Got STARKNET_NET_URL : ", process.env.STARKNET_NET_URL, ", STARKNET_ACC_ADDRESS : ", process.env.STARKNET_ACC_ADDRESS, ", STARKNET_PK : ", process.env.STARKNET_PK?.substring(0, 6) + "...");

    const compiledContract = json.parse(
        fs.readFileSync("build/SceneCatalog.json").toString("ascii")
    );
        
    const providerOptions : ProviderOptions = process.env.STARKNET_NET_URL ? {sequencer: {baseUrl: process.env.STARKNET_NET_URL}} : {sequencer: {network: "goerli-alpha"}};
    const keyPair = ec.getKeyPair(process.env.STARKNET_PK);
    const signer = new Signer(keyPair);
    const account = new Account(providerOptions, process.env.STARKNET_ACC_ADDRESS ?? "", signer);

    console.log("["+CONTRACT_NAME+"] - [~] - Sending deployment request");

    const computedCalldata = calldataCallback ? calldataCallback() : generateDefaultCalldata();

    const deployResponse = await account.deployContract({
      contract: compiledContract,
      constructorCalldata: computedCalldata
    });

    console.log("["+CONTRACT_NAME+"] - [~] - Waiting for Tx to be Accepted on Starknet - Contract Deployment...");
    console.log("["+CONTRACT_NAME+"] - [~] - Transaction hash : ", deployResponse.transaction_hash);

    await account.waitForTransaction(deployResponse.transaction_hash);

    console.log("["+CONTRACT_NAME+"] - [+] - Contract successfully deployed at : ", deployResponse.contract_address);



    return (new Contract(compiledContract.abi, deployResponse.contract_address, account));
}

if (require.main === module) {
    deploySceneCatalog().then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
}