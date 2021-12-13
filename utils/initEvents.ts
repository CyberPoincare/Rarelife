import * as factory from '../typechain';
import { Signer } from 'ethers';
import { BigNumber } from '@ethersproject/abi/node_modules/@ethersproject/bignumber';
import * as age_events from "../doc/ages.json";

export async function deploy_Events(evtMaps: any, route: factory.RarelifeContractRoute, events: factory.RarelifeEvents, wallet: Signer, addressBook: any) {    
    //set event processor
    let keys = Object.keys(evtMaps);
    for(var i=0; i<keys.length; i++) {
        process.stdout.write(`\u001B[1000D${Math.round(i*100.0/keys.length)}%`);
        let eventId = keys[i];
  
        if(eventId != undefined) {
            let factoryFuncStr = `function gen_factory(wallet, factory, rlAddress) { return new factory.RarelifeEventProcessor${eventId}__factory(wallet).deploy(rlAddress); }`;
            let factoryFun = new Function('return ' + factoryFuncStr);
            const deployTx = await (await factoryFun()(wallet, factory, addressBook["RarelifeContractRoute"], )).deployed();
            addressBook[`RarelifeEventProcessor${eventId}`] = deployTx.address;

            let tx = await events.set_event_processor(eventId, deployTx.address);
            //await tx.wait();
        }
    }
    process.stdout.write(`\u001B[1000D`);

    return addressBook;
}

export async function initEvents(route: factory.RarelifeContractRoute, events: factory.RarelifeEvents, wallet: Signer, addressBook: any) {    
    //events must be included
    let keymaps = {
    };
    //read ages to init events automatically, most for development and debug
    let ages = Object.keys(age_events);
    for(var ageId=0; ageId<ages.length; ageId++) {
        let age = ages[ageId];
        let ageEvts = age_events[age].event;
        if(ageEvts != undefined) {
            ageEvts = ageEvts.map(v=>{
                const value = `${v}`.split('*').map( n => Number(n) );
                return value;
            });

            for(var i=0; i<ageEvts.length; i++) {
                keymaps[ageEvts[i][0]] = ageEvts[i][0];
            }
        }
    }

    //set event processors
    let keys = Object.keys(keymaps);
    for(var i=0; i<keys.length; i++) {
        process.stdout.write(`\u001B[1000D${Math.round(i*100.0/keys.length)}%`);
        let eventId = keys[i];
  
        if(eventId != undefined) {
            let factoryFuncStr = `function gen_factory(wallet, factory, rlAddress) { return new factory.RarelifeEventProcessor${eventId}__factory(wallet).deploy(rlAddress); }`;
            let factoryFun = new Function('return ' + factoryFuncStr);
            const deployTx = await (await factoryFun()(wallet, factory, addressBook["RarelifeContractRoute"])).deployed();
            addressBook[`RarelifeEventProcessor${eventId}`] = deployTx.address;

            let tx = await events.set_event_processor(eventId, deployTx.address);
            //await tx.wait();
        }
    }
    process.stdout.write(`\u001B[1000D`);

    return addressBook;
}
