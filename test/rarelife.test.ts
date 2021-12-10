//npx hardhat node
//yarn test --network hard
import {ethers} from "hardhat";
import chai, { expect } from 'chai';
import asPromised from 'chai-as-promised';
import { JsonRpcProvider } from '@ethersproject/providers';
import { generatedWallets } from '../utils/generatedWallets';
import { Signer } from 'ethers';
import fs from 'fs-extra';
import * as factory from '../typechain';
import { deploy_all } from '../scripts/deploy_all';
import { BigNumber } from '@ethersproject/abi/node_modules/@ethersproject/bignumber';
import { getAddressBookShareFilePath } from '../address_config';

chai.use(asPromised);

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}

describe('Project',  () => {

    let deployerWallet:Signer;
    let actor0Wallet:Signer;
    async function prepareSigners() {
        [deployerWallet, actor0Wallet] = await ethers.getSigners();
    }

    const sharedAddressPath = getAddressBookShareFilePath();
    let addressBook = {};
    async function getContractAddress(){
        // @ts-ignore
        addressBook = JSON.parse(await fs.readFileSync(sharedAddressPath));
    }

    async function operateRarelifeContractRouteAs(wallet: Signer){return factory.RarelifeContractRoute__factory.connect(addressBook["RarelifeContractRoute"], wallet);}
    async function operateBaseRandomAs(wallet: Signer){return factory.BaseRandom__factory.connect(addressBook["BaseRandom"], wallet);}
    async function operateRarelifeAs(wallet: Signer){return factory.Rarelife__factory.connect(addressBook["Rarelife"], wallet);}
    async function operateRarelifeGoldAs(wallet: Signer){return factory.RarelifeGold__factory.connect(addressBook["RarelifeGold"], wallet);}
    async function operateRarelifeTalentsAs(wallet: Signer){return factory.RarelifeTalents__factory.connect(addressBook["RarelifeTalents"], wallet);}
    async function operateRarelifeEventsAs(wallet: Signer){return factory.RarelifeEvents__factory.connect(addressBook["RarelifeEvents"], wallet);}
    async function operateRarelifeTimelineAs(wallet: Signer){return factory.RarelifeTimeline__factory.connect(addressBook["RarelifeTimeline"], wallet);}
    async function operateRarelifeNamesAs(wallet: Signer){return factory.RarelifeNames__factory.connect(addressBook["RarelifeNames"], wallet);}
    async function operateRarelifeAttributesAs(wallet: Signer){return factory.RarelifeAttributes__factory.connect(addressBook["RarelifeAttributes"], wallet);}

    let actor : any;

    // describe("All Contract", ()=>{
    //     beforeEach(async ()=>{
    //         await prepareSigners();
    //         await getContractAddress();
    //     })

    //     it("Deploy All", async ()=>{
    //         await deploy_all(sharedAddressPath);
    //     }).timeout(60000);
    // })

    describe("CodexBaseRandom", ()=>{
        beforeEach(async ()=>{
            await prepareSigners();
            await getContractAddress();
        })

        it("dn", async ()=>{
            const rand = await operateBaseRandomAs(actor0Wallet);
            console.log(`dn = ${(await rand.dn(0, 100)).toNumber()}`);
        }).timeout(15000);
    })

    describe("Rarelife Manifested", ()=>{
        beforeEach(async ()=>{
            await prepareSigners();
            await getContractAddress();
        })

        it("mint actor", async ()=>{
            const rlm = await operateRarelifeAs(actor0Wallet);
            actor = await rlm.next_actor();
            let res = await rlm.mint_actor({ gasLimit: 5000000 });
            await expect(res.wait()).eventually.fulfilled;
            console.log(`Mint actor: ${actor.toString()} successfully.`);
            let uri = await rlm.tokenURI(actor);
            console.log(`Rarelife Manifested actor #${actor.toString()} uri:`);
            console.log(uri);
        }).timeout(30000);
    })

    describe("RarelifeTimeline Born", ()=>{
        beforeEach(async ()=>{
            await prepareSigners();
            await getContractAddress();
        })

        it("born actor in timeline", async ()=>{
            const timeline = await operateRarelifeTimelineAs(actor0Wallet);
            let tx = await timeline.born_character(actor, { gasLimit: 5000000 });
            await tx.wait();
            let uri = await timeline.tokenURI(actor);
            console.log(`RarelifeTimeline actor #${actor.toString()} uri:`);
            console.log(uri);
        }).timeout(15000);
    })

    describe("RarelifeNames", ()=>{
        beforeEach(async ()=>{
            await prepareSigners();
            await getContractAddress();
        })

        it("clame actor name", async ()=>{
            const names = await operateRarelifeNamesAs(actor0Wallet);
            let nameId = await names.next_name();
            let firstName = `Paticle${Math.round(Math.random()*100)}`;
            console.log(firstName);
            await (await names.claim(firstName, "Cyber", actor, { gasLimit: 5000000 })).wait();
            let actorName = await names.actor_name(actor);
            console.log(`set actor#${actor.toString()} name=${actorName.name}, nameId=${nameId}`);
            let uri = await names.tokenURI(nameId);
            console.log(`RarelifeNames name#${nameId.toString()} uri:`);
            console.log(uri);
        }).timeout(15000);
    })

    describe("RarelifeTimeline Grow", ()=>{
        beforeEach(async ()=>{
            await prepareSigners();
            await getContractAddress();
        })

        it("init actor talents", async ()=>{
            const talents = await operateRarelifeTalentsAs(actor0Wallet);

            let tx = await talents.talent_character(actor, { gasLimit: 5000000 });
            await tx.wait();
            console.log(`init actor#${actor.toString()} talents: ${(await talents.actor_talents(actor)).toString()}`);
            let point_buy = await talents.actor_attribute_point_buy(actor);
            console.log(`modify actor attribute point buy to ${point_buy.toNumber()}`);
            let uri = await talents.tokenURI(actor);
            console.log(`RarelifeTalents actor#${actor.toString()} uri:`);
            console.log(uri);
        }).timeout(30000);

        it("init actor attributes", async ()=>{
            const attributes = await operateRarelifeAttributesAs(actor0Wallet);
            
            let tx = await attributes.point_character(actor, { gasLimit: 5000000 });
            await tx.wait();
            let [_chr, _int, _str, _mny] = await attributes.ability_scores(actor);
            console.log(`init actor#${actor.toString()} attributes: CHR=${_chr}, INT=${_int}, STR=${_str}, MNY=${_mny}`);
            let uri = await attributes.tokenURI(actor);
            console.log(`RarelifeAttributes actor#${actor.toString()} uri:`);
            console.log(uri);
        }).timeout(15000);

        it(`grow actor`, async ()=>{
            for(var _age=0; _age<=5; _age++) {
                const rlm = await operateRarelifeAs(actor0Wallet);
                const age = await operateRarelifeTimelineAs(actor0Wallet);
                const gold = await operateRarelifeGoldAs(actor0Wallet);

                await expect((await age.ages(actor)).toNumber()).to.equal(_age==0?_age:(_age-1));
                console.log(`wait and try grow to age${_age} ...`);
                await delay(2000);
                //approve timeline
                console.log(`approve for all actor#${actor.toString()} to RarelifeTimeline`);
                await (await rlm.setApprovalForAll(age.address, true)).wait();
                console.log(`approve actor#${actor.toString()} to RarelifeTimeline`);
                await (await rlm.approve(age.address, actor)).wait();
                //approve actor's gold to timeline
                await gold.approve(actor, await age.ACTOR_ADMIN(), await gold.balanceOf(actor));
                
                let res = await age.grow(actor, { gasLimit: 5000000 });
                await expect(res.wait()).eventually.fulfilled;
                await expect((await age.ages(actor)).toNumber()).to.equal(_age);
                let uri = await age.tokenURI(actor);
                console.log(`RarelifeTimeline actor #${actor.toString()} age${_age} uri:`);
                console.log(uri);
            }
        }).timeout(180000);
    })
});