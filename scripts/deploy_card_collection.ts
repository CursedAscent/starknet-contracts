import { Account, ec, ProviderOptions, Signer, json, Contract } from "starknet";
import fs from "fs";
import { toBN } from "starknet/dist/utils/number";

const CONTRACT_NAME="CardCollection";

function generateDefaultCalldata() {
    let calldata: any[] = [];

    calldata.push(toBN(74171710399844).toString()); // name
    calldata.push(toBN(289194267461).toString()); // symbol
    calldata.push(toBN(52).toString()); // total_supply

    var base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm";

    calldata.push(toBN(base_uri.length).toString()); //base_uri_len

    for (var i=0; i < base_uri.length; i++) // base_uri
        calldata.push(base_uri.charCodeAt(i));

    var data = [ //data: CardData*
        // WARRIOR
        [0x0, 0x1, 0x1], // [action, class, rarity]
        [0x0, 0x1, 0x1],
        [0x0, 0x1, 0x1],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x3],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x2],
        [0x0, 0x1, 0x3],
        // HUNTER
        [0x0, 0x2, 0x1], // [action, class, rarity]
        [0x0, 0x2, 0x1],
        [0x0, 0x2, 0x1],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x3],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x3],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x2],
        [0x0, 0x2, 0x2],
        // LIGHT_MAGE
        [0x0, 0x3, 0x1], // [action, class, rarity]
        [0x0, 0x3, 0x1],
        [0x0, 0x3, 0x1],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x3],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x2],
        [0x0, 0x3, 0x3],
        // DARK_MAGE
        [0x0, 0x4, 0x1], // [action, class, rarity]
        [0x0, 0x4, 0x1],
        [0x0, 0x4, 0x1],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x3],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x2],
        [0x0, 0x4, 0x3],
    ]

    calldata.push(data.length)

    for (const d of data) { // data_len
        calldata.push(toBN(d[0]).toString());
        calldata.push(toBN(d[1]).toString());
        calldata.push(toBN(d[2]).toString());
    }

    calldata = calldata.map((x) => toBN(x).toString());

    return calldata;
}

export async function deployCardCollection (calldataCallback?: Function) {
    console.log("["+CONTRACT_NAME+"] - [~] - Setting up env and payload for deployment");
    console.log("["+CONTRACT_NAME+"] - [~] - Got STARKNET_NET_URL : ", process.env.STARKNET_NET_URL, ", STARKNET_ACC_ADDRESS : ", process.env.STARKNET_ACC_ADDRESS, ", STARKNET_PK : ", process.env.STARKNET_PK?.substring(0, 6) + "...");

    const compiledContract = json.parse(
        fs.readFileSync("build/CardCollection.json").toString("ascii")
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
    deployCardCollection().then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
}