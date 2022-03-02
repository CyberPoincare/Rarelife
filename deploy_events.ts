//npx hardhat node
//npx hardhat run deploy_events.ts --network hard
import * as env from "hardhat";
import { deploy_new_events } from './scripts/deploy_new_events';
import { getAddressBookShareFilePath } from './address_config';

console.log("Deploy New Event Contracts");
const args = require('minimist')(process.argv.slice(2));
if (args.network) {
	env.changeNetwork(args.network);
}

async function main(): Promise<void> {
    let addressBookFile = getAddressBookShareFilePath(args.network);

    //new event ids
    let evtMap = {
        10005:10005,
        10006:10006
    };

    //event probability
    let age = 3;
    let ageEvts = [
        //id, prob
        [10005,1]
    ];

    await deploy_new_events(addressBookFile, age, ageEvts, evtMap);
}

main()
	.then(() => process.exit(0))
	.catch((error: Error) => {
		console.error(error);
		process.exit(1);
	});
