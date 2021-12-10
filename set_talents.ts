//npx hardhat node
//npx hardhat run set_talents.ts --network hard
import * as env from "hardhat";
import { setTalents } from './utils/initTalents';
import fs from 'fs-extra';
import * as factory from './typechain';
import {ethers} from "hardhat";
import { Signer } from 'ethers';
import { getAddressBookShareFilePath } from './address_config';

console.log("Set New Talents");

let addressBook = {};
async function getContractAddress(path : string){
    // @ts-ignore
    addressBook = JSON.parse(await fs.readFileSync(path));
}

async function operateRarelifeTalentsAs(wallet: Signer){return factory.RarelifeTalents__factory.connect(addressBook["RarelifeTalents"], wallet);}

async function main(): Promise<void> {
    let addressBookFile = getAddressBookShareFilePath();
    await getContractAddress(addressBookFile);
    const [deployerWallet, actor0Wallet] = await ethers.getSigners();

    //new talents
    let tlts_list = {
        "1011": {
            "id": "1011",
            "name": "talents 1",
            "description": "desc"
        }
    };

    let tlts = await operateRarelifeTalentsAs(actor0Wallet);
    await setTalents(tlts, tlts_list);
}

const args = require('minimist')(process.argv.slice(2));

if (args.network) {
	env.changeNetwork(args.network);
}

main()
	.then(() => process.exit(0))
	.catch((error: Error) => {
		console.error(error);
		process.exit(1);
	});
