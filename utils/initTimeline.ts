import * as factory from '../typechain';
import { BigNumberish } from '@ethersproject/abi/node_modules/@ethersproject/bignumber';
import * as events from "../doc/ages.json";

export async function addTimeline(era: factory.RarelifeTimeline, age: BigNumberish, ageEvts: any) {

    for(var i=0; i<ageEvts.length; i++) {
        process.stdout.write(`\u001B[1000Dage ${age} ${Math.round(i*100.0/ageEvts.length)}%`);
        let tx = await era.add_age_event(age, ageEvts[i][0], `${ageEvts[i][1]}`, { gasLimit: 5000000 });
        //await tx.wait();
    }

    process.stdout.write(`\u001B[1000Dage ${age} 100%`);
}

export async function initTimeline(era: factory.RarelifeTimeline) {
    //read age list to init events in certain age automatically, most for development and debug
    let ages = Object.keys(events);
    for(var ageId=0; ageId<ages.length; ageId++) {
        let age = ages[ageId];
        let ageEvts = events[age].event;
        if(ageEvts != undefined) {
            ageEvts = ageEvts.map(v=>{
                const value = `${v}`.split('*').map( n => Number(n) );
                if(value.length==1) value.push(1);
                value[1] = Math.round(value[1]*100); //avoid fractional part, make to 3 precision int
                return value;
            });

            for(var i=0; i<ageEvts.length; i++) {
                process.stdout.write(`\u001B[1000Dage ${age} ${Math.round(i*100.0/ageEvts.length)}%`);
                let tx = await era.add_age_event(age, ageEvts[i][0], `${ageEvts[i][1]}`, { gasLimit: 5000000 });
                //await tx.wait();
            }
        }
    }

    process.stdout.write(`\u001B[1000D`);
}
