import * as factory from '../typechain';
import { BigNumberish } from '@ethersproject/abi/node_modules/@ethersproject/bignumber';

export async function addTimeline(era: factory.RarelifeTimeline, age: BigNumberish, ageEvts: any) {

    for(var i=0; i<ageEvts.length; i++) {
        process.stdout.write(`\u001B[1000Dage ${age} ${Math.round(i*100.0/ageEvts.length)}%`);
        let tx = await era.add_age_event(age, ageEvts[i][0], `${ageEvts[i][1]}`, { gasLimit: 5000000 });
        //await tx.wait();
    }

    process.stdout.write(`\u001B[1000Dage ${age} 100%`);
}
