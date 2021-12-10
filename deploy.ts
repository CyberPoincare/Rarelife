//npx hardhat node
//npx hardhat run deploy.ts --network hard
import * as env from "hardhat";
import { deploy_all } from './scripts/deploy_all';
import { getAddressBookShareFilePath } from './address_config';

console.log("Deploy All Contracts");

async function main(): Promise<void> {
    let addressBookFile = getAddressBookShareFilePath();
    await deploy_all(addressBookFile);
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
