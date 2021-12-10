// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/RarelifeLibrary.sol";

contract RarelifeTalents is IRarelifeTalents, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint public immutable ACTOR_DESIGNER = 0; //God authority
    uint constant POINT_BUY = 20;

    uint[]                  public talent_ids;
    mapping(uint => string) public talent_names;
    mapping(uint => string) public talent_descriptions;
    mapping(uint => uint[]) public _talent_exclusivity;
    mapping(uint => int)    public override talent_attr_points_modifiers;
    mapping(uint => RarelifeStructs.SAbilityModifiers) public _talent_attribute_modifiers;
    mapping(uint => address) private talent_conditions;

    //map actor to talents 
    mapping(uint => uint[]) public _actor_talents;
    mapping(uint => mapping(uint => bool)) public _actor_talents_map;
    mapping(uint => bool) public override actor_talents_initiated;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeTalents: not approved or owner");
        _;
    }

    modifier onlyTalentsInitiated(uint _actor) {
        require(actor_talents_initiated[_actor], "RarelifeTalents: not initiated yet");
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

    function _point_modify(uint _p, int _modifier) internal pure returns (uint) {
        if(_modifier > 0)
            _p += uint(_modifier); 
        else {
            if(_p < uint(-_modifier))
                _p = 0;
            else
                _p -= uint(-_modifier); 
        }
        return _p;
    }

    /* ****************
     * External Functions
     * ****************
     */

    function set_talent(uint _id, string memory _name, string memory _description, RarelifeStructs.SAbilityModifiers memory _attribute_modifiers, int _attr_point_modifier) external override
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "RarelifeTalents: invalid name");
        //require(keccak256(abi.encodePacked(talent_names[_id])) == keccak256(abi.encodePacked("")), "RarelifeTalents: already have talent");

        if(keccak256(abi.encodePacked(talent_names[_id])) == keccak256(abi.encodePacked(""))) {
            //first time
            talent_ids.push(_id);
        }

        talent_names[_id] = _name;
        talent_descriptions[_id] = _description;
        _talent_attribute_modifiers[_id] = _attribute_modifiers;
        talent_attr_points_modifiers[_id] = _attr_point_modifier;
    }

    function set_talent_exclusive(uint _id, uint[] memory _exclusive) external override
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(keccak256(abi.encodePacked(talent_names[_id])) != keccak256(abi.encodePacked("")), "RarelifeTalents: talent have not set");
        _talent_exclusivity[_id] = _exclusive;
    }

    function set_talent_condition(uint _id, address _conditionAddress) external override
        onlyApprovedOrOwner(ACTOR_DESIGNER)
    {
        require(keccak256(abi.encodePacked(talent_names[_id])) != keccak256(abi.encodePacked("")), "RarelifeTalents: talent have not set");
        talent_conditions[_id] = _conditionAddress;        
    }

    function talent_character(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {        
        require(!actor_talents_initiated[_actor], "RarelifeTalents: already init talents");

        IRarelifeRandom rand = rlRoute.random();
        uint tltCt = rand.dn(_actor, 4);
        if(tltCt > talent_ids.length)
            tltCt = talent_ids.length;
        if(tltCt > 0) {
            for(uint i=0; i<tltCt; i++) {
                uint ch = rand.dn(_actor+i, talent_ids.length);
                uint _id = talent_ids[ch];
                //REVIEW: check exclusivity at first
                bool isConflicted = false;
                if(_talent_exclusivity[_id].length > 0) {
                    for(uint k=0; k<_talent_exclusivity[_id].length; k++) {
                        for(uint j=0; j<_actor_talents[_actor].length; j++) {
                            if(_actor_talents[_actor][j] == _talent_exclusivity[_id][k]) {
                                isConflicted = true;
                                break;
                            }
                        }
                        if(isConflicted)
                            break;
                    }
                }

                if(!isConflicted && !_actor_talents_map[_actor][_id]) {
                    _actor_talents_map[_actor][_id] = true;
                    _actor_talents[_actor].push(_id);
                }
            }
        }

        actor_talents_initiated[_actor] = true;

        emit Created(msg.sender, _actor, _actor_talents[_actor]);
    }

    /* **************
     * View Functions
     * **************
     */

    function actor_attribute_point_buy(uint _actor) external view override returns (uint) {
        uint point = POINT_BUY;
        for(uint i=0; i<_actor_talents[_actor].length; i++) {
            uint tlt = _actor_talents[_actor][i];
            point = _point_modify(point, talent_attr_points_modifiers[tlt]);
        }
        return point;
    }

    function actor_talents(uint _actor) external view override returns (uint[] memory) {
        return _actor_talents[_actor];
    }

    function actor_talents_exist(uint _actor, uint[] memory _talents) external view override returns (bool[] memory) {
        bool[] memory exists = new bool[](_talents.length);
        for(uint i=0; i<_talents.length; i++)
            exists[i] = _actor_talents_map[_actor][_talents[i]];
        return exists;
    }

    function talents(uint _id) external view override returns (string memory _name, string memory _description) {
        _name = talent_names[_id];
        _description = talent_descriptions[_id];
    }

    function talent_attribute_modifiers(uint _id) external view override returns (RarelifeStructs.SAbilityModifiers memory) {
        return _talent_attribute_modifiers[_id];
    }

    function talent_exclusivity(uint _id) external view override returns (uint[] memory) {
        return _talent_exclusivity[_id];
    }

    function can_occurred(uint _actor, uint _id, uint _age) external view override
        onlyTalentsInitiated(_actor)
        returns (bool)
    {
        //REVIEW: check exclusivity at first
        if(_talent_exclusivity[_id].length > 0) {
            for(uint i=0; i<_talent_exclusivity[_id].length; i++) {
                for(uint j=0; j<_actor_talents[_actor].length; j++) {
                    if(_actor_talents[_actor][j] == _talent_exclusivity[_id][i])
                        return false;
                }
            }
        }

        if(talent_conditions[_id] == address(0)) {
            if(_age == 0) //no condition and only age 0
                return true;
            else
                return false;
        }

        return IRarelifeTalentChecker(talent_conditions[_id]).check(_actor, _age);
    }

    function tokenURI(uint256 _actor) public view returns (string memory) {
        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = '';
        string memory tltJson = '';
        for(uint i=0; i<_actor_talents[_actor].length; i++) {
            uint tlt = _actor_talents[_actor][i];
            uint y = 40*i;
            parts[1] = string(abi.encodePacked(parts[1],
                string(abi.encodePacked('<text x="10" y="', Strings.toString(20+y), '" class="base" stroke="yellow">', talent_names[tlt], '</text>')),
                string(abi.encodePacked('<text x="10" y="', Strings.toString(40+y), '" class="base">', talent_descriptions[tlt], '</text>'))));
            tltJson = string(abi.encodePacked(tltJson, Strings.toString(tlt), ','));
        }
        //end svg
        parts[2] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), ' talents:"'));
        parts[1] = ', "description": "This is not a game"';
        parts[2] = string(abi.encodePacked(', "data": {', '"TLT": [', tltJson, ']}'));
        //end json with svg
        parts[3] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]))));

        //final output
        return string(abi.encodePacked('data:application/json;charset=utf-8;base64,', json));
    }
}
