import { deployCardCollection } from "./deploy_card_collection";
import { deployCardCatalog } from "./deploy_card_catalog";
import { toBN } from "starknet/dist/utils/number";
import { AccountInterface } from "starknet/dist/account";
import { deployEnemyCollection } from "./deploy_enemy_collection";
import { deployCockyImp } from "./deploy_cocky_imp";
import { deploySceneCollection } from "./deploy_scene_collection";
import { deploySceneCatalog } from "./deploy_scene_catalog";

import { Account, ec, ProviderOptions, Signer, json, Contract } from "starknet";
import fs from "fs";

const CONTRACT_NAME="CursedAscent";

export async function deployCursedAscent (calldataCallback?: Function) {
    console.log("["+CONTRACT_NAME+"] - [~] - Deploying CardCollection");
    const cardCollectionInst = await deployCardCollection();
    console.log("["+CONTRACT_NAME+"] - [~] - Deploying CardCatalog");
    const cardCatalogInst = await deployCardCatalog();
    console.log("["+CONTRACT_NAME+"] - [~] - Adding card collection to catalog");
    
    await cardCatalogInst.add_collection(74171710399844, cardCollectionInst.address);

    console.log("["+CONTRACT_NAME+"] - [~] - Deploying EnemyCollection");
    const enemyCatalogInst = await deployEnemyCollection();
    console.log("["+CONTRACT_NAME+"] - [~] - Deploying CockyImp");
    const cockyImpInst = await deployCockyImp([[enemyCatalogInst.address, 0]]);
    console.log("["+CONTRACT_NAME+"] - [~] - Deploying SceneCollection");
    const sceneCollectionInst = await deploySceneCollection([cockyImpInst.address]);
    console.log("["+CONTRACT_NAME+"] - [~] - Deploying SceneCatalog");
    const sceneCatalogInst = await deploySceneCatalog();
    console.log("["+CONTRACT_NAME+"] - [~] - Adding scene collection to catalog");

    await sceneCatalogInst.add_collection(74171710399844, sceneCollectionInst.address);

    console.log("["+CONTRACT_NAME+"] - [~] - Setting up env and payload for deployment");
    const compiledContract = json.parse(
        fs.readFileSync("build/cursed_ascent.json").toString("ascii")
    );

    const account: any = sceneCatalogInst.providerOrAccount;

    console.log("["+CONTRACT_NAME+"] - [~] - Sending deployment request");

    const deployResponse = await account.deployContract({
        contract: compiledContract,
        constructorCalldata: [cardCatalogInst.address, sceneCatalogInst.address]
    });

    console.log("["+CONTRACT_NAME+"] - [~] - Waiting for Tx to be Accepted on Starknet - Contract Deployment...");
    console.log("["+CONTRACT_NAME+"] - [~] - Transaction hash : ", deployResponse.transaction_hash);

    await account.waitForTransaction(deployResponse.transaction_hash);

    console.log("["+CONTRACT_NAME+"] - [+] - Contract successfully deployed at : ", deployResponse.contract_address);
}

if (require.main === module) {
    deployCursedAscent().then(() => process.exit(0))
        .catch(error => {
            console.error(error);
            process.exit(1);
        });
}