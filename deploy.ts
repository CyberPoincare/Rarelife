//npx hardhat node
//npx hardhat run deploy.ts --network hard

//use ts-node
//TS_NODE_FILES=1 ts-node deploy.ts --network hard

import * as env from "hardhat";
import { deploy_all } from './scripts/deploy_all';
import { getAddressBookShareFilePath } from './address_config';

console.log("Deploy All Contracts");
const args = require('minimist')(process.argv.slice(2));
if (args.network) {
	console.log(`set network: ${args.network}.`);
	env.changeNetwork(args.network);
}

async function main(): Promise<void> {
    let addressBookFile = getAddressBookShareFilePath(args.network);
    await deploy_all(addressBookFile);
}

main()
	.then(() => process.exit(0))
	.catch((error: Error) => {
		console.error(error);
		process.exit(1);
	});
