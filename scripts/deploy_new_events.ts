//npx hardhat node
//npx hardhat run deploy_all.ts --network hard
import {ethers} from "hardhat";
import { Signer } from 'ethers';
import fs from 'fs-extra';
import * as factory from '../typechain';
import { deploy_Events } from '../utils/initEvents';
import { addTimeline } from '../utils/initTimeline';

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

export async function deploy_new_events(sharedAddressPath : string, age: number, ageNewEvents: any, newEventsMap: any): Promise<void> {

    await getContractAddress(sharedAddressPath);

    const [deployerWallet, actor0Wallet] = await ethers.getSigners();

    console.log(`deploy events...`);
    {
        let route = await operateRarelifeContractRouteAs(deployerWallet);
        const evts = await operateRarelifeEventsAs(actor0Wallet);

        addressBook =  await deploy_Events(newEventsMap, route, evts, deployerWallet, addressBook);
        await fs.writeFile(sharedAddressPath, JSON.stringify(addressBook, null, 2));
        console.log(`done!`);
    }

    console.log(`add events to ages...`);
    {
        const era = await operateRarelifeTimelineAs(actor0Wallet);
        await addTimeline(era, age, ageNewEvents);

        console.log('done!');
    }
}
