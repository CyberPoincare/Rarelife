// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/RarelifeLibrary.sol";
//import "hardhat/console.sol";

contract RarelifeEventProcessor60002 is DefaultRarelifeEventProcessor, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    string[] private time_labels = [
        "Virgo",
        "Libra",
        "Scorpio",
        "Sagittarius",
        "Capricorn",
        "Aquarius",
        "Pisces",
        "Aries",
        "Taurus",
        "Gemini",
        "Cancer",
        "Leo"
    ];

    mapping(uint => uint) public born_times;
    mapping(uint => bool) public character_born;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeEventProcessor60002: not approved or owner");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {}

    /* *****************
     * Private Functions
     * *****************
     */

    /* ****************
     * External Functions
     * ****************
     */

    function process(uint _actor, uint /*_age*/) external override {
        require(!character_born[_actor], "RarelifeEventProcessor60002: already trigger!");        
        //random time
        uint _time = rlRoute.random().dn(_actor, 12);
        require(_time >=0 && _time <= 11, "RarelifeEventProcessor60002: time not in range");
        born_times[_actor] = _time;
        character_born[_actor] = true;
    }

    // function active_trigger(uint _actor, uint[] memory _uintParams) external override returns (string memory) {
    //     require(_uintParams.length > 0);
    //     require(!character_born[_actor], "RarelifeEventProcessor60002: already trigger!");        
    //     uint _time = _uintParams[0];
    //     require(_time >=0 && _time <= 23, "RarelifeEventProcessor60002: time not in range");
    //     born_times[_actor] = _time;
    //     character_born[_actor] = true;

    //     uint _age = rlRoute.timeline().ages(_actor);
    //     emit ActiveEvent(_actor, _age, 60002, time_labels[_time]);

    //     return time_labels[_time];
    // }

    /* **************
     * View Functions
     * **************
     */

    function time_label(uint _time) external view returns (string memory) {
        return time_labels[_time];
    }

    function event_info(uint _actor) external view override returns (string memory) {
        if(character_born[_actor]) {
            if(born_times[_actor] == 5 || born_times[_actor] == 7)
                return string(abi.encodePacked("You are an ", time_labels[born_times[_actor]], "."));
            else
                return string(abi.encodePacked("You are a ", time_labels[born_times[_actor]], "."));
        }
        else
            return "NA";
    }

    function check_occurrence(uint _actor, uint /*_age*/) external view override returns (bool) {
        bool defaultRt = true;

        IRarelifeTimeline timeline = rlRoute.timeline();

        //"exclude": "EVT?[60002]",
        if(timeline.actor_event_count(_actor, 60002) > 0)
            return false;

        return defaultRt;
    }
}
