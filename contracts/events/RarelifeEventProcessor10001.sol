// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/RarelifeLibrary.sol";
//import "hardhat/console.sol";

/*
default return init to be true;
check order:
    NoRadom --> false
    exclude --> false
    include --> set default return to be false, and return true if match condition
    return default
*/

contract RarelifeEventProcessor10001 is DefaultRarelifeEventProcessor, RarelifeConfigurable {
    uint[] public maleActors;
    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {}
    function event_info(uint /*_actor*/) external view override returns (string memory) {
        return "You were born a boy.";
    }
    function check_occurrence(uint _actor, uint /*_age*/) external view override returns (bool) {
        bool defaultRt = true;

        IRarelifeTalents talents = rlRoute.talents();

        //"exclude": "TLT?[1002]"
        uint[] memory tlts = talents.actor_talents(_actor);
        for(uint i=0; i<tlts.length; i++) {
            if(tlts[i] == 1002)
                return false;
        }

        return defaultRt;
    }
    // "branch": [60002]
    function check_branch(uint /*_actor*/, uint /*_age*/) external view override returns (uint) {        
        return 60002;
    }
    function process(uint _actor, uint /*_age*/) external override {
        maleActors.push(_actor);
    }
    function maleNum() external view returns (uint) {
        return maleActors.length;
    }
}
