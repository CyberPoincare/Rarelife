// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/RarelifeLibrary.sol";

contract RarelifeEvents is IRarelifeEvents, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint public constant ACTOR_DESIGNER = 0; //God authority

    mapping(uint => address) public override event_processors;
    
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeEvents: not approved or owner");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {
    }

    /* *****************
     * Private Functions
     * *****************
     */

    /* ****************
     * External Functions
     * ****************
     */

    function set_event_processor(uint _id, address _address) external override
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        event_processors[_id] = _address;        
    }

    /* **************
     * View Functions
     * **************
     */

    function event_info(uint _id, uint _actor) external view override returns (string memory) {
        string memory info;
        if(event_processors[_id] != address(0))
            info = IRarelifeEventProcessor(event_processors[_id]).event_info(_actor);
        return info;
    }

    function event_attribute_modifiers(uint _id, uint _actor) external view override returns (RarelifeStructs.SAbilityModifiers memory) {
        RarelifeStructs.SAbilityModifiers memory attr;
        if(event_processors[_id] != address(0))
            attr = IRarelifeEventProcessor(event_processors[_id]).event_attribute_modifiers(_actor);
        return attr;
    }

    function can_occurred(uint _actor, uint _id, uint _age) external view override returns (bool) {
        if(event_processors[_id] == address(0))
            return true;
        return IRarelifeEventProcessor(event_processors[_id]).check_occurrence(_actor, _age);
    }

    function check_branch(uint _actor, uint _id, uint _age) external view override returns (uint) {
        if(event_processors[_id] == address(0))
            return 0;
        return IRarelifeEventProcessor(event_processors[_id]).check_branch(_actor, _age); 
    }

}
