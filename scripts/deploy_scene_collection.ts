import { Account, ec, ProviderOptions, Signer, json, Contract } from "starknet";
import fs from "fs";
import { toBN } from "starknet/dist/utils/number";

const CONTRACT_NAME="SceneCollection";

function generateDefaultCalldata(sceneData: string[]) {
    let calldata: any[] = [];

    calldata.push(74171710399844); // name;
    calldata.push(289194267461); // symbol
    calldata.push(0x1); // total_supply

    var base_uri = "ipfs://bafybeihqn642isjie5ynxy7au42jug4bl2obqsappjjujkb7nzz3sexwh4";

    calldata.push(toBN(base_uri.length).toString()); //base_uri_len

    for (var i=0; i < base_uri.length; i++) // base_uri
        calldata.push(base_uri.charCodeAt(i));

    calldata.push(sceneData.length) // data_len

    for (const d of sceneData) { // data
        calldata.push(toBN(d).toString());
    }

    calldata = calldata.map((x) => toBN(x).toString());

    return calldata;
}

export async function deploySceneCollection (sceneData: string[], calldataCallback?: Function) {
    console.log("["+CONTRACT_NAME+"] - [~] - Setting up env and payload for deployment");
    console.log("["+CONTRACT_NAME+"] - [~] - Got STARKNET_NET_URL : ", process.env.STARKNET_NET_URL, ", STARKNET_ACC_ADDRESS : ", process.env.STARKNET_ACC_ADDRESS, ", STARKNET_PK : ", process.env.STARKNET_PK?.substring(0, 6) + "...");

    const compiledContract = json.parse(
        fs.readFileSync("build/SceneCollection.json").toString("ascii")
    );
        
    const providerOptions : ProviderOptions = process.env.STARKNET_NET_URL ? {sequencer: {baseUrl: process.env.STARKNET_NET_URL}} : {sequencer: {network: "goerli-alpha"}};
    const keyPair = ec.getKeyPair(process.env.STARKNET_PK);
    const signer = new Signer(keyPair);
    const account = new Account(providerOptions, process.env.STARKNET_ACC_ADDRESS?.toLowerCase() ?? "", signer);

    console.log("["+CONTRACT_NAME+"] - [~] - Sending deployment request");

    const computedCalldata = calldataCallback ? calldataCallback() : generateDefaultCalldata(sceneData);

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
    deploySceneCollection(["0x42"]).then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
}