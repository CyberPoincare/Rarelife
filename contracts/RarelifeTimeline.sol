// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/RarelifeLibrary.sol";
//import "hardhat/console.sol";

contract RarelifeTimeline is IRarelifeTimeline, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint public constant ACTOR_DESIGNER = 0; //god authority
    uint public override immutable ACTOR_ADMIN; //timeline administrator authority

    mapping(uint => uint) public override ages; //current ages
    mapping(uint => bool) public override character_born;
    mapping(uint => bool) public override character_birthday; //have atleast one birthday

    uint constant ONE_AGE_VSECOND = 86400; //1 day in real means 1 age in rarelife
    mapping(uint => uint) public born_time_stamps;


    //map actor to age to event
    mapping(uint => mapping(uint => uint[])) private actor_events;
    //map actor to event to count
    mapping(uint => mapping(uint => uint)) private actor_events_history;
    //map age to event pool ids
    mapping(uint => uint[]) private event_ids; //age to id list
    mapping(uint => uint[]) private event_probs; //age to prob list

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeTimeline: not approved or owner");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    /* *****************
     * Private Functions
     * *****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {
        IRarelife rl = rlRoute.rl();
        ACTOR_ADMIN = rl.next_actor();
        rl.mint_actor();
    }

    function _expected_age(uint _actor) internal view returns (uint) {
        require(character_born[_actor], "have not born!");
        uint _dt = block.timestamp - born_time_stamps[_actor];
        return _dt / ONE_AGE_VSECOND;
    }

    function _attribute_modify(uint32 _attr, int32 _modifier) internal pure returns (uint32) {
        if(_modifier > 0)
            _attr += uint32(_modifier); 
        else {
            if(_attr < uint32(-_modifier))
                _attr = 0;
            else
                _attr -= uint32(-_modifier); 
        }
        return _attr;
    }

    function _process_talents(uint _actor, uint _age) internal
        onlyApprovedOrOwner(_actor)
    {
        IRarelifeTalents talents = rlRoute.talents();
        IRarelifeAttributes attributes = rlRoute.attributes();

        uint[] memory tlts = talents.actor_talents(_actor);
        for(uint i=0; i<tlts.length; i++) {
            if(talents.can_occurred(_actor, tlts[i], _age)) {
                bool attributesModified = false;
                RarelifeStructs.SAbilityScore memory attrib;
                RarelifeStructs.SAbilityModifiers memory attr_modifier = talents.talent_attribute_modifiers(tlts[i]);
                (attrib, attributesModified) = attributes.apply_modified(_actor, attr_modifier);
                if(attr_modifier._age != 0) {
                    ages[_actor] = uint(_attribute_modify(uint32(_age), attr_modifier._age));
                    attributesModified = true;
                }
                if(attributesModified) {
                    //this will trigger attribute uptate event
                    attributes.set_attributes(_actor, attrib);
                }
            }
        }
    }

    function _run_event_processor(uint _actor, uint _age, address _processorAddress) private {
        //approve event processor the authority of timeline
        rlRoute.rl().approve(_processorAddress, ACTOR_ADMIN);
        IRarelifeEventProcessor(_processorAddress).process(_actor, _age); 
    }

    function _process_event(uint _actor, uint _age, uint eventId, uint _depth) private returns (uint branchEvtId) {

        IRarelifeEvents evts = rlRoute.evts();
        IRarelifeAttributes attributes = rlRoute.attributes();

        actor_events[_actor][_age].push(eventId);
        actor_events_history[_actor][eventId] += 1;

        RarelifeStructs.SAbilityModifiers memory attr_modifier = evts.event_attribute_modifiers(eventId, _actor);
        bool attributesModified = false;
        RarelifeStructs.SAbilityScore memory attrib;
        (attrib, attributesModified) = attributes.apply_modified(_actor, attr_modifier);
        if(attr_modifier._age != 0) { //change age
            ages[_actor] = uint(_attribute_modify(uint32(_age), attr_modifier._age));
            attributesModified = true;
        }

        if(attributesModified) {
            //this will trigger attribute uptate event
            attributes.set_attributes(_actor, attrib);
        }

        //process event if any processor
        address evtProcessorAddress = evts.event_processors(eventId);
        if(evtProcessorAddress != address(0))
            _run_event_processor(_actor, _age, evtProcessorAddress);

        if(_depth == 0)
            emit AgeEvent(_actor, _age, eventId);
        else
            emit BranchEvent(_actor, _age, eventId);

        //check branch
        return evts.check_branch(_actor, eventId, _age);
    }

    function _process_events(uint _actor, uint _age) internal 
        onlyApprovedOrOwner(_actor)
    {
        IRarelifeEvents evts = rlRoute.evts();

        //filter events for occurrence
        uint[] memory events_filtered = new uint[](event_ids[_age].length);
        uint events_filtered_num = 0;
        for(uint i=0; i<event_ids[_age].length; i++) {
            if(evts.can_occurred(_actor, event_ids[_age][i], _age)) {
                events_filtered[events_filtered_num] = i;
                events_filtered_num++;
            }
        }

        uint pCt = 0;
        for(uint i=0; i<events_filtered_num; i++) {
            pCt += event_probs[_age][events_filtered[i]];
        }
        uint prob = 0;
        if(pCt > 0)
            prob = rlRoute.random().dn(_actor, pCt);
        
        pCt = 0;
        for(uint i=0; i<events_filtered_num; i++) {
            pCt += event_probs[_age][events_filtered[i]];
            if(pCt >= prob) {
                uint eventId = event_ids[_age][events_filtered[i]];
                uint branchEvtId = _process_event(_actor, _age, eventId, 0);

                //only support two level branchs
                if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
                    branchEvtId = _process_event(_actor, _age, branchEvtId, 1);
                    if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
                        branchEvtId = _process_event(_actor, _age, branchEvtId, 2);
                        require(branchEvtId == 0, "RarelifeTimeline: only support two level branchs");
                    }
                }

                break;
            }
        }
    }

    function _process(uint _actor, uint _age) internal
        onlyApprovedOrOwner(_actor)
    {
        require(character_born[_actor], "RarelifeTimeline: actor have not born!");
        //require(actor_events[_actor][_age] == 0, "RarelifeTimeline: actor already have event!");
        require(event_ids[_age].length > 0, "RarelifeTimeline: not exist any event in this age!");

        _process_talents(_actor, _age);
        _process_events(_actor, _age);
    }

    function _run_active_event_processor(uint _actor, uint /*_age*/, address _processorAddress, uint[] memory _uintParams) private {
        //approve event processor the authority of timeline
        rlRoute.rl().approve(_processorAddress, ACTOR_ADMIN);
        IRarelifeEventProcessor(_processorAddress).active_trigger(_actor, _uintParams);
    }

    function _process_active_event(uint _actor, uint _age, uint eventId, uint[] memory _uintParams, uint _depth) private returns (uint branchEvtId) {

        IRarelifeEvents evts = rlRoute.evts();
        IRarelifeAttributes attributes = rlRoute.attributes();

        actor_events[_actor][_age].push(eventId);
        actor_events_history[_actor][eventId] += 1;

        RarelifeStructs.SAbilityModifiers memory attr_modifier = evts.event_attribute_modifiers(eventId, _actor);
        bool attributesModified = false;
        RarelifeStructs.SAbilityScore memory attrib;
        (attrib, attributesModified) = attributes.apply_modified(_actor, attr_modifier);
        if(attr_modifier._age != 0) { //change age
            ages[_actor] = uint(_attribute_modify(uint32(_age), attr_modifier._age));
            attributesModified = true;
        }

        if(attributesModified) {
            //this will trigger attribute uptate event
            attributes.set_attributes(_actor, attrib);
        }

        //process active event if any processor
        address evtProcessorAddress = evts.event_processors(eventId);
        if(evtProcessorAddress != address(0))
            _run_active_event_processor(_actor, _age, evtProcessorAddress, _uintParams);

        if(_depth == 0)
            emit ActiveEvent(_actor, _age, eventId);
        else
            emit BranchEvent(_actor, _age, eventId);

        //check branch
        return evts.check_branch(_actor, eventId, _age);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function born_character(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {
        require(!character_born[_actor], "RarelifeTimeline: already born!");
        character_born[_actor] = true;
        born_time_stamps[_actor] = block.timestamp;

        emit Born(msg.sender, _actor);
    }

    function grow(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {
        require(character_born[_actor], "RarelifeTimeline: actor have not born");
        require(character_birthday[_actor] == false || ages[_actor] < _expected_age(_actor), "RarelifeTimeline: actor grow time have not come");
        require(rlRoute.attributes().ability_scores(_actor)._lif > 0, "RarelifeTimeline: actor dead!");

        if(character_birthday[_actor]) {
            //grow one year
            ages[_actor] += 1;
        }
        else {
            //need first birthday
            ages[_actor] = 0;
            character_birthday[_actor] = true;
        }

        //do new year age events
        _process(_actor, ages[_actor]);
    }

    function add_age_event(uint _age, uint _eventId, uint _eventProb) external 
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(_eventId > 0, "RarelifeTimeline: event id must not zero");
        require(event_ids[_age].length == event_probs[_age].length, "RarelifeTimeline: internal ids not match probs");
        event_ids[_age].push(_eventId);
        event_probs[_age].push(_eventProb);
    }

    function set_age_event_prob(uint _age, uint _eventId, uint _eventProb) external 
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(_eventId > 0, "RarelifeTimeline: event id must not zero");
        require(event_ids[_age].length == event_probs[_age].length, "RarelifeTimeline: internal ids not match probs");
        for(uint i=0; i<event_ids[_age].length; i++) {
            if(event_ids[_age][i] == _eventId) {
                event_probs[_age][i] = _eventProb;
                return;
            }
        }
        require(false, "RarelifeTimeline: can not find eventId");
    }

    function active_trigger(uint _eventId, uint _actor, uint[] memory _uintParams) external override
        onlyApprovedOrOwner(_actor)
    {
        IRarelifeEvents evts = rlRoute.evts();

        address evtProcessorAddress = evts.event_processors(_eventId);
        require(evtProcessorAddress != address(0), "RarelifeTimeline: can not find event processor.");

        uint _age = ages[_actor];
        require(evts.can_occurred(_actor, _eventId, _age), "RarelifeTimeline: event check occurrence failed.");
        uint branchEvtId = _process_active_event(_actor, _age, _eventId, _uintParams, 0);

        //only support two level branchs
        if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
            branchEvtId = _process_active_event(_actor, _age, branchEvtId, _uintParams, 1);
            if(branchEvtId > 0 && evts.can_occurred(_actor, branchEvtId, _age)) {
                branchEvtId = _process_active_event(_actor, _age, branchEvtId, _uintParams, 2);
                require(branchEvtId == 0, "RarelifeTimeline: only support two level branchs");
            }
        }
    }

    /* **************
     * View Functions
     * **************
     */

    function expected_age(uint _actor) external override view returns (uint) {
        return _expected_age(_actor);
    }

    function actor_event(uint _actor, uint _age) external override view returns (uint[] memory) {
        return actor_events[_actor][_age];
    }

    function actor_event_count(uint _actor, uint _eventId) external override view returns (uint) {
        return actor_events_history[_actor][_eventId];
    }

    function tokenURI(uint256 _actor) public view returns (string memory) {
        IRarelifeEvents evts = rlRoute.evts();

        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">Age: ', Strings.toString(ages[_actor]), '</text>'));
        parts[2] = '';
        string memory evtJson = '';
        for(uint i=0; i<actor_events[_actor][ages[_actor]].length; i++) {
            uint eventId = actor_events[_actor][ages[_actor]][i];
            uint y = 20*i;
            parts[2] = string(abi.encodePacked(parts[2],
                string(abi.encodePacked('<text x="10" y="', Strings.toString(40+y), '" class="base">', evts.event_info(eventId, _actor), '</text>'))));
            evtJson = string(abi.encodePacked(evtJson, Strings.toString(eventId)));
            if(i < (actor_events[_actor][ages[_actor]].length-1))
                evtJson = string(abi.encodePacked(evtJson, ','));
        }
        //end svg
        parts[3] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), '"'));
        parts[1] = ', "description": "This is not a game"';
        parts[2] = string(abi.encodePacked(', "data": {', '"age": ', Strings.toString(ages[_actor])));
        parts[3] = string(abi.encodePacked(', "events": [', evtJson, ']}'));
        //end json with svg
        parts[4] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURIByAge(uint256 _actor, uint _age) public view returns (string memory) {
        IRarelifeEvents evts = rlRoute.evts();

        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">Age: ', Strings.toString(_age), '</text>'));
        parts[2] = '';
        string memory evtJson = '';
        for(uint i=0; i<actor_events[_actor][_age].length; i++) {
            uint eventId = actor_events[_actor][_age][i];
            uint y = 20*i;
            parts[2] = string(abi.encodePacked(parts[2],
                string(abi.encodePacked('<text x="10" y="', Strings.toString(40+y), '" class="base">', evts.event_info(eventId, _actor), '</text>'))));
            evtJson = string(abi.encodePacked(evtJson, Strings.toString(eventId), ','));
        }
        //end svg
        parts[3] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), '"'));
        parts[1] = ', "description": "This is not a game"';
        parts[2] = string(abi.encodePacked(', "data": {', '"age": ', Strings.toString(_age)));
        parts[3] = string(abi.encodePacked(', "events": [', evtJson, ']}'));
        //end json with svg
        parts[4] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}
