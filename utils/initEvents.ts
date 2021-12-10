import * as factory from '../typechain';
import { Signer } from 'ethers';
import { BigNumber } from '@ethersproject/abi/node_modules/@ethersproject/bignumber';

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
