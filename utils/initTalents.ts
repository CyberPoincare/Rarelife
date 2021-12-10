import * as factory from '../typechain';
import { BigNumber } from '@ethersproject/abi/node_modules/@ethersproject/bignumber';

export async function setTalents(tlts: factory.RarelifeTalents, new_list: any) {    
    let keys = Object.keys(new_list);
    for(var i=0; i<keys.length; i++) {
        process.stdout.write(`\u001B[1000D${Math.round(i*100.0/keys.length)}%`);
        let tlt = new_list[keys[i]];
        let name = tlt.name;
        let description = tlt.description;
        let attr_modifyer = BigNumber.from(tlt.status?tlt.status:0);
        let exclusive = tlt.exclusive?tlt.exclusive:[];
        let exclusivity = [];
        for(var e=0; e<exclusive.length; e++) {
            exclusivity.push(BigNumber.from(exclusive[e]));
        }
        let effect = tlt.effect?tlt.effect:{};
        let _chr = BigNumber.from(effect.CHR?effect.CHR:0);
        let _int = BigNumber.from(effect.INT?effect.INT:0);
        let _str = BigNumber.from(effect.STR?effect.STR:0);
        let _mny = BigNumber.from(effect.MNY?effect.MNY:0);
        let _spr = BigNumber.from(effect.SPR?effect.SPR:0);
        let _lif = BigNumber.from(effect.LIF?effect.LIF:0);
        let _age = BigNumber.from(effect.AGE?effect.AGE:0);
  
        if(tlt.id != undefined) {
            let tx = await tlts.set_talent(tlt.id, name, description, {_chr, _int, _str, _mny, _spr, _lif, _age}, attr_modifyer, { gasLimit: 5000000 });
            //await tx.wait();
            tx = await tlts.set_talent_exclusive(tlt.id, exclusive, { gasLimit: 5000000 });
            //await tx.wait();
        }
    }
    process.stdout.write(`\u001B[1000D`);
}
