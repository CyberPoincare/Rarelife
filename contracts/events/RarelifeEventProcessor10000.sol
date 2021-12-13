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

contract RarelifeEventProcessor10000 is DefaultRarelifeEventProcessor, RarelifeConfigurable {
    uint[] public deadActors;
    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {}
    function event_info(uint /*_actor*/) external view override returns (string memory) {
        return "You are dead.";
    }
    function event_attribute_modifiers(uint /*_actor*/) external view override returns (RarelifeStructs.SAbilityModifiers memory) {
        //"LIF": -1000
        return RarelifeStructs.SAbilityModifiers(0,0,0,0,0,-1000,0);
    }
    function process(uint _actor, uint /*_age*/) external override {
        deadActors.push(_actor);
    }
    function deadNum() external view returns (uint) {
        return deadActors.length;
    }
}
