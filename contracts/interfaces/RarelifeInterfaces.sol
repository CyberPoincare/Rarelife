// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./RarelifeStructs.sol";

interface IRarelifeRandom {
    function dn(uint _actor, uint _number) external view returns (uint);
    function d20(uint _actor) external view returns (uint);
}

interface IRarelife is IERC721 {

    event actorMinted(address indexed _owner, uint indexed _actor, uint indexed _time);

    function actor(uint _actor) external view returns (uint _mintTime, uint _status);
    function next_actor() external view returns (uint);
    function mint_actor() external;
}

interface IRarelifeTimeline {

    event Born(address indexed creator, uint indexed actor);
    event AgeEvent(uint indexed _actor, uint indexed _age, uint indexed _eventId);
    event BranchEvent(uint indexed _actor, uint indexed _age, uint indexed _eventId);
    event ActiveEvent(uint indexed _actor, uint indexed _age, uint indexed _eventId);

    function ACTOR_ADMIN() external view returns (uint);
    function ages(uint _actor) external view returns (uint); //current age
    function expected_age(uint _actor) external view returns (uint); //age should be
    function character_born(uint _actor) external view returns (bool);
    function character_birthday(uint _actor) external view returns (bool);
    function actor_event(uint _actor, uint _age) external view returns (uint[] memory);
    function actor_event_count(uint _actor, uint _eventId) external view returns (uint);

    function active_trigger(uint _eventId, uint _actor, uint[] memory _uintParams) external;
}

interface IRarelifeNames is IERC721Enumerable {

    event NameClaimed(address indexed owner, uint indexed actor, uint indexed name_id, string name, string first_name, string last_name);
    event NameUpdated(uint indexed name_id, string old_name, string new_name);
    event NameAssigned(uint indexed name_id, uint indexed previous_actor, uint indexed new_actor);

    function next_name() external view returns (uint);
    function actor_name(uint _actor) external view returns (string memory name, string memory firstName, string memory lastName);
}

interface IRarelifeAttributes {

    event Created(address indexed creator, uint indexed actor, uint32 CHR, uint32 INT, uint32 STR, uint32 MNY, uint32 SPR, uint32 LIF);
    event Updated(address indexed executor, uint indexed actor, uint32 CHR, uint32 INT, uint32 STR, uint32 MNY, uint32 SPR, uint32 LIF);

    function set_attributes(uint _actor, RarelifeStructs.SAbilityScore memory _attr) external;
    function ability_scores(uint _actor) external view returns (RarelifeStructs.SAbilityScore memory);
    function character_points_initiated(uint _actor) external view returns (bool);
    function apply_modified(uint _actor, RarelifeStructs.SAbilityModifiers memory attr_modifier) external view returns (RarelifeStructs.SAbilityScore memory, bool);
}

interface IRarelifeTalents {

    event Created(address indexed creator, uint indexed actor, uint[] ids);

    function talents(uint _id) external view returns (string memory _name, string memory _description);
    function talent_attribute_modifiers(uint _id) external view returns (RarelifeStructs.SAbilityModifiers memory);
    function talent_attr_points_modifiers(uint _id) external view returns (int);
    function set_talent(uint _id, string memory _name, string memory _description, RarelifeStructs.SAbilityModifiers memory _attribute_modifiers, int _attr_point_modifier) external;
    function set_talent_exclusive(uint _id, uint[] memory _exclusive) external;
    function set_talent_condition(uint _id, address _conditionAddress) external;
    function talent_exclusivity(uint _id) external view returns (uint[] memory);

    function actor_attribute_point_buy(uint _actor) external view returns (uint);
    function actor_talents(uint _actor) external view returns (uint[] memory);
    function actor_talents_initiated(uint _actor) external view returns (bool);
    function actor_talents_exist(uint _actor, uint[] memory _talents) external view returns (bool[] memory);
    function can_occurred(uint _actor, uint _id, uint _age) external view returns (bool);
}

interface IRarelifeTalentChecker {
    function check(uint _actor, uint _age) external view returns (bool);
}

interface IRarelifeEvents {
    function event_info(uint _id, uint _actor) external view returns (string memory);
    function event_attribute_modifiers(uint _id, uint _actor) external view returns (RarelifeStructs.SAbilityModifiers memory);
    function event_processors(uint _id) external view returns(address);
    function set_event_processor(uint _id, address _address) external;
    function can_occurred(uint _actor, uint _id, uint _age) external view returns (bool);
    function check_branch(uint _actor, uint _id, uint _age) external view returns (uint);
}

interface IRarelifeEventProcessor {
    function event_info(uint _actor) external view returns (string memory);
    function event_attribute_modifiers(uint _actor) external view returns (RarelifeStructs.SAbilityModifiers memory);
    function check_occurrence(uint _actor, uint _age) external view returns (bool);
    function process(uint _actor, uint _age) external;
    function active_trigger(uint _actor, uint[] memory _uintParams) external;
    function check_branch(uint _actor, uint _age) external view returns (uint);
}

abstract contract DefaultRarelifeEventProcessor is IRarelifeEventProcessor {
    function event_attribute_modifiers(uint /*_actor*/) virtual external view override returns (RarelifeStructs.SAbilityModifiers memory) {
        return RarelifeStructs.SAbilityModifiers(0,0,0,0,0,0,0);
    }
    function check_occurrence(uint /*_actor*/, uint /*_age*/) virtual external view override returns (bool) { return true; }
    function process(uint _actor, uint _age) virtual external override {}
    function check_branch(uint /*_actor*/, uint /*_age*/) virtual external view override returns (uint) { return 0; }
    function active_trigger(uint /*_actor*/, uint[] memory /*_uintParams*/) virtual external override { }
} 

interface IRarelifeFungible {
    event Transfer(uint indexed from, uint indexed to, uint amount);
    event Approval(uint indexed from, uint indexed to, uint amount);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(uint owner) external view returns (uint);
    function allowance(uint owner, uint spender) external view returns (uint);

    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface IRarelifeGold is IRarelifeFungible {
    function claim(uint _actor, uint _amount) external;
}
