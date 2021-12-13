//use hardhat network to debug
//npx hardhat node
//npx hardhat run log_server.ts --network hard

//use ts-node
//TS_NODE_FILES=1 ts-node log_server.ts --network hard --start 10

import * as env from "hardhat";
import { ethers } from "hardhat";
import fs from 'fs-extra';
import { BigNumber } from 'ethers'; //https://docs.ethers.io/v5/
import { JsonRpcProvider } from '@ethersproject/providers';
import { Wallet } from '@ethersproject/wallet';
import * as factory from './typechain';
import { accessSync } from 'fs';
import chalk from 'chalk';
import { getAddressBookShareFilePath } from './address_config';

console.log("Log Server");

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function str_pad( hex : string ){
	var zero = '00000000';
	var tmp = 8-hex.length;
	return zero.substr(0,tmp) + hex;
}

function formatTime(time) {
	let unixtime = time
	let unixTimestamp = new Date(unixtime * 1000)
	let Y = unixTimestamp.getFullYear()
	//let M = ((unixTimestamp.getMonth() + 1) > 10 ? (unixTimestamp.getMonth() + 1) : '0' + (unixTimestamp.getMonth() + 1))
	let M = unixTimestamp.getMonth() + 1;
	let D = (unixTimestamp.getDate() > 10 ? unixTimestamp.getDate() : '0' + unixTimestamp.getDate())
	let toDay = Y + '-' + M + '-' + D
	return {
		toDay : toDay,
		Y: Y,
		M: M,
		D: D
	}
}

var addressBook = {};
async function initAddress() {
	addressBook = JSON.parse(await fs.readFileSync(await getAddressBookShareFilePath()));
	console.log(addressBook);
}

async function startSyncMain(startBlockNum : number) {
	if(addressBook["Rarelife"] == undefined) {
		await initAddress();
	}
	let provider = await ethers.provider;
    const [wallet] = await ethers.getSigners();
	const rarelife = factory.Rarelife__factory.connect(addressBook["Rarelife"], wallet);
	const rarelifeGold = factory.RarelifeGold__factory.connect(addressBook["RarelifeGold"], wallet);
	const rarelifeEvents = factory.RarelifeEvents__factory.connect(addressBook["RarelifeEvents"], wallet);
	const rarelifeTalents = factory.RarelifeTalents__factory.connect(addressBook["RarelifeTalents"], wallet);
	const rarelifeTimeline = factory.RarelifeTimeline__factory.connect(addressBook["RarelifeTimeline"], wallet);
	const rarelifeNames = factory.RarelifeNames__factory.connect(addressBook["RarelifeNames"], wallet);
	const rarelifeAttributes = factory.RarelifeAttributes__factory.connect(addressBook["RarelifeAttributes"], wallet);

	const rarelifeEventProcessor10000 = factory.RarelifeEventProcessor10000__factory.connect(addressBook["RarelifeEventProcessor10000"], wallet);
	const rarelifeEventProcessor10001 = factory.RarelifeEventProcessor10001__factory.connect(addressBook["RarelifeEventProcessor10001"], wallet);
	const rarelifeEventProcessor10002 = factory.RarelifeEventProcessor10002__factory.connect(addressBook["RarelifeEventProcessor10002"], wallet);

	let blockNum = await provider.getBlockNumber();
	//console.log(startBlockNum, blockNum);

	let actorMinted_filter = rarelife.filters.actorMinted(null, null, null);
	let timeline_born_filter = rarelifeTimeline.filters.Born(null, null);
	let timeline_ageEvent_filter = rarelifeTimeline.filters.AgeEvent(null, null, null);
	let timeline_branchEvent_filter = rarelifeTimeline.filters.BranchEvent(null, null, null);
	let timeline_activeEvent_filter = rarelifeTimeline.filters.ActiveEvent(null, null, null);
	let attrUpdate_filter = rarelifeAttributes.filters.Updated(null, null, null, null, null, null, null, null);
	let NameClaimed_filter = rarelifeNames.filters.NameClaimed(null, null, null, null, null, null);
	let talent_init_filter = rarelifeTalents.filters.Created(null, null, null);
	let gold_transfer_filter = rarelifeGold.filters.Transfer(null, null, null);

	if(startBlockNum <= blockNum) {
		while(true) {
			//console.log(startBlockNum);
			let block = await provider.getBlock(startBlockNum);

			//Create actor events
			let actorMinted_event = await rarelife.queryFilter(actorMinted_filter, block.hash);
			if(actorMinted_event.length > 0) {
				//console.log(actorMinted_event);
				for(var e=0; e<actorMinted_event.length; e++) {
					let owner = actorMinted_event[e].args._owner;
					let actor = actorMinted_event[e].args._actor.toNumber();
					let time = actorMinted_event[e].args._time.toNumber();
					let timeInfo = formatTime(time);

					//https://github.com/chalk/chalk
					console.log(`[${timeInfo.M}/${timeInfo.D}/${timeInfo.Y}]`+chalk.red(`actor#${actor}`)+`is created.`);
				}
			}

			//timeline born character events
			let timeline_born_event = await rarelifeTimeline.queryFilter(timeline_born_filter, block.hash);
			if(timeline_born_event.length > 0) {
				for(var e=0; e<timeline_born_event.length; e++) {
					let creator = timeline_born_event[e].args.creator;
					let actor = timeline_born_event[e].args.actor.toNumber();

					console.log(chalk.cyan(`actor#${actor}`)+` born.`);

					//Statistics
					console.log(chalk.yellow(`Gold:`)+chalk.yellowBright(`${ethers.utils.formatEther(await rarelifeGold.totalSupply())}`));
					console.log(chalk.yellow(`Statistics:`));
					console.log(`Male:   `+chalk.green(`${await rarelifeEventProcessor10001.maleNum()}`));
					console.log(`Female: `+chalk.green(`${await rarelifeEventProcessor10002.femaleNum()}`));
					console.log(`Death:  `+chalk.red(`${await rarelifeEventProcessor10000.deadNum()}`));
				}
			}

			//timeline age events
			let timeline_ageEvent_event = await rarelifeTimeline.queryFilter(timeline_ageEvent_filter, block.hash);
			if(timeline_ageEvent_event.length > 0) {
				for(var e=0; e<timeline_ageEvent_event.length; e++) {
					let actor = timeline_ageEvent_event[e].args._actor;
					let age = timeline_ageEvent_event[e].args._age;
					let eventId = timeline_ageEvent_event[e].args._eventId;
					let eventInfo = await rarelifeEvents.event_info(eventId, actor);
					let name = (await rarelifeNames.actor_name(actor)).name;

					console.log(chalk.cyan(`${name}`)+` already `+chalk.red(`${age}`)+` years old.`);
					console.log(`[${eventId.toString()}]`+eventInfo);
				}
			}

			//timeline active events
			let timeline_activeEvent_event = await rarelifeTimeline.queryFilter(timeline_activeEvent_filter, block.hash);
			if(timeline_activeEvent_event.length > 0) {
				for(var e=0; e<timeline_activeEvent_event.length; e++) {
					let actor = timeline_activeEvent_event[e].args._actor;
					let age = timeline_activeEvent_event[e].args._age;
					let eventId = timeline_activeEvent_event[e].args._eventId;
					let eventInfo = await rarelifeEvents.event_info(eventId, actor);
					let name = (await rarelifeNames.actor_name(actor)).name;

					console.log(`[${eventId.toString()}]`+eventInfo);
				}
			}

			//timeline branch events
			let timeline_branchEvent_event = await rarelifeTimeline.queryFilter(timeline_branchEvent_filter, block.hash);
			if(timeline_branchEvent_event.length > 0) {
				for(var e=0; e<timeline_branchEvent_event.length; e++) {
					let actor = timeline_branchEvent_event[e].args._actor;
					let age = timeline_branchEvent_event[e].args._age;
					let eventId = timeline_branchEvent_event[e].args._eventId;
					let eventInfo = await rarelifeEvents.event_info(eventId, actor);
					let name = (await rarelifeNames.actor_name(actor)).name;

					console.log(`[${eventId.toString()}]`+eventInfo);
				}
			}

			//name claimed events
			let NameClaimed_event = await rarelifeNames.queryFilter(NameClaimed_filter, block.hash);
			if(NameClaimed_event.length > 0) {
				for(var e=0; e<NameClaimed_event.length; e++) {
					let owner = NameClaimed_event[e].args.owner;
					let actor = NameClaimed_event[e].args.actor.toNumber();
					let name_id = NameClaimed_event[e].args.name_id;
					let first_name = NameClaimed_event[e].args.first_name;
					let last_name = NameClaimed_event[e].args.last_name;
					let name = NameClaimed_event[e].args.name;

					console.log(chalk.cyan(`actor#${actor}`)+` is named `+chalk.red(`${name}`));
				}
			}

			//talents init events
			let talentsInit_event = await rarelifeTalents.queryFilter(talent_init_filter, block.hash);
			if(talentsInit_event.length > 0) {
				for(var e=0; e<talentsInit_event.length; e++) {
					let actor = talentsInit_event[e].args.actor;
					let tlts = talentsInit_event[e].args.ids;
					let name = (await rarelifeNames.actor_name(actor)).name;
			
					console.log(chalk.cyan(`${name}`)+` has talents:`);
					for(var t=0; t<tlts.length; t++) {
						console.log(`  `+chalk.red(await rarelifeTalents.talent_names(tlts[t]))+`(${await rarelifeTalents.talent_descriptions(tlts[t])})`);
					}
				}
			}

			//attribute update events
			let attriUpdate_event = await rarelifeAttributes.queryFilter(attrUpdate_filter, block.hash);
			if(attriUpdate_event.length > 0) {
				for(var e=0; e<attriUpdate_event.length; e++) {
					let actor = attriUpdate_event[e].args.actor;
					let chr = attriUpdate_event[e].args.CHR;
					let int = attriUpdate_event[e].args.INT;
					let str = attriUpdate_event[e].args.STR;
					let mny = attriUpdate_event[e].args.MNY;
					let spr = attriUpdate_event[e].args.SPR;
					let lif = attriUpdate_event[e].args.LIF;
					let name = (await rarelifeNames.actor_name(actor)).name;
					let age = await rarelifeTimeline.ages(actor);
			
					console.log(chalk.cyan(`${name}`)+` is changed：`+
						chalk.red(`Charm=${chr}`)+`，`+chalk.red(`Intelligence=${int}`)+`，`+chalk.red(`Strength=${str}`)+`，`+
						chalk.red(`Money=${mny}`)+`，`+chalk.red(`Happy=${spr}`)+`，`+chalk.red(`Health=${lif}`)+`，`+
						chalk.red(`Age=${age}`)+`，`);
				}
			}

			//gold transfer events
			let gold_transfer_event = await rarelifeGold.queryFilter(gold_transfer_filter, block.hash);
			if(gold_transfer_event.length > 0) {
				for(var e=0; e<gold_transfer_event.length; e++) {
					let from = gold_transfer_event[e].args.from;
					let to = gold_transfer_event[e].args.to;
					let fromName = (await rarelifeNames.actor_name(from)).name;
					let toName = (await rarelifeNames.actor_name(to)).name;
					let amount = gold_transfer_event[e].args.amount;
			
					if(from.eq(to)) {
						console.log(chalk.cyan(`${fromName}`)+` get `+chalk.yellow(`${ethers.utils.formatEther(amount)}`)+` golds!`);
					}
					else {
						console.log(chalk.cyan(`${fromName}`)+` give `+chalk.cyan(`${toName}`)+chalk.yellow(` ${ethers.utils.formatEther(amount)}`)+` golds.`);
					}
				}
			}

			startBlockNum++;
			if(startBlockNum > blockNum)
				break;
		}
	}

	// again in 1 second
	setTimeout(function () {
		startSyncMain(startBlockNum);
	}, 1000);
}

const args = require('minimist')(process.argv.slice(2));

if (args.network) {
	env.changeNetwork(args.network);
}

if (args.start)
	startSyncMain(args.start);
else
	startSyncMain(0);
