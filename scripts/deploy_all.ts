//npx hardhat node
//npx hardhat run deploy_all.ts --network hard
import {ethers} from "hardhat";
import { Signer } from 'ethers';
import fs from 'fs-extra';
import * as factory from '../typechain';

let addressBook = {};
async function getContractAddress(path : string){
    // @ts-ignore
    addressBook = JSON.parse(await fs.readFileSync(path));
}

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}

async function operateRarelifeContractRouteAs(wallet: Signer){return factory.RarelifeContractRoute__factory.connect(addressBook["RarelifeContractRoute"], wallet);}
async function operateBaseRandomAs(wallet: Signer){return factory.BaseRandom__factory.connect(addressBook["BaseRandom"], wallet);}
async function operateRarelifeAs(wallet: Signer){return factory.Rarelife__factory.connect(addressBook["Rarelife"], wallet);}
async function operateRarelifeGoldAs(wallet: Signer){return factory.RarelifeGold__factory.connect(addressBook["RarelifeGold"], wallet);}
async function operateRarelifeTalentsAs(wallet: Signer){return factory.RarelifeTalents__factory.connect(addressBook["RarelifeTalents"], wallet);}
async function operateRarelifeEventsAs(wallet: Signer){return factory.RarelifeEvents__factory.connect(addressBook["RarelifeEvents"], wallet);}
async function operateRarelifeTimelineAs(wallet: Signer){return factory.RarelifeTimeline__factory.connect(addressBook["RarelifeTimeline"], wallet);}
async function operateRarelifeNamesAs(wallet: Signer){return factory.RarelifeNames__factory.connect(addressBook["RarelifeNames"], wallet);}
async function operateRarelifeAttributesAs(wallet: Signer){return factory.RarelifeAttributes__factory.connect(addressBook["RarelifeAttributes"], wallet);}

export async function deploy_all(sharedAddressPath : string): Promise<void> {

    const [deployerWallet, actor0Wallet] = await ethers.getSigners();
    await getContractAddress(sharedAddressPath);

    console.log(`deploy RarelifeContractRoute...`);
    {
        const deployTx = await (await new factory.RarelifeContractRoute__factory(deployerWallet).deploy({ gasLimit: 5000000 })).deployed();
        addressBook["RarelifeContractRoute"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));
    }

    console.log(`deploy BaseRandom...`);
    {
        const deployTx = await (await new factory.BaseRandom__factory(deployerWallet).deploy({ gasLimit: 5000000 })).deployed();
        addressBook["BaseRandom"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerRandom(deployTx.address)
    }

    console.log(`deploy Rarelife...`);
    {
        const deployTx = await (await new factory.Rarelife__factory(deployerWallet).deploy({ gasLimit: 5000000 })).deployed();
        addressBook["Rarelife"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerRLM(deployTx.address)
    }

    //mint actor #0 as GOD(Designer)
    {
        const rlm = await operateRarelifeAs(actor0Wallet);
        let actor = await rlm.next_actor();
        console.log(`mint actor#${actor.toString()} as GOD...`);
        await (await rlm.mint_actor({ gasLimit: 5000000 })).wait();
        let uri = await rlm.tokenURI(actor);
        console.log(`actor#${actor.toString()} uri:`);
        console.log(uri);
    }

    console.log(`deploy RarelifeGold...`);
    {
        const deployTx = await (await new factory.RarelifeGold__factory(deployerWallet).deploy(addressBook["RarelifeContractRoute"], { gasLimit: 5000000 })).deployed();
        addressBook["RarelifeGold"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerGold(deployTx.address)
    }

    console.log(`deploy RarelifeEvents...`);
    {
        const deployTx = await (await new factory.RarelifeEvents__factory(deployerWallet).deploy(addressBook["RarelifeContractRoute"], { gasLimit: 5000000 })).deployed();
        addressBook["RarelifeEvents"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerEvents(deployTx.address)
    }

    console.log(`deploy RarelifeTalents...`);
    {
        const deployTx = await (await new factory.RarelifeTalents__factory(deployerWallet).deploy(addressBook["RarelifeContractRoute"], { gasLimit: 5000000 })).deployed();
        addressBook["RarelifeTalents"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerTalents(deployTx.address)
    }

    console.log(`deploy RarelifeTimeline...`);
    {
        const deployTx = await (await new factory.RarelifeTimeline__factory(deployerWallet).deploy(addressBook["RarelifeContractRoute"], { gasLimit: 5000000 })).deployed();
        addressBook["RarelifeTimeline"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerTimeline(deployTx.address)
    }

    console.log(`deploy RarelifeNames...`);
    {
        const deployTx = await (await new factory.RarelifeNames__factory(deployerWallet).deploy(addressBook["RarelifeContractRoute"], { gasLimit: 5000000 })).deployed();
        addressBook["RarelifeNames"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerNames(deployTx.address)
    }

    console.log(`deploy RarelifeAttributes...`);
    {
        const deployTx = await (await new factory.RarelifeAttributes__factory(deployerWallet).deploy(addressBook["RarelifeContractRoute"], { gasLimit: 5000000 })).deployed();
        addressBook["RarelifeAttributes"] = deployTx.address;
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));

        let route = await operateRarelifeContractRouteAs(deployerWallet);
        await route.registerAttributes(deployTx.address)
    }
}
