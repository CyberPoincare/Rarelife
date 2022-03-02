// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/RarelifeLibrary.sol";

contract RarelifeAttributes is IRarelifeAttributes, RarelifeConfigurable {

    /* *******
     * Globals
     * *******
     */

    uint constant LABEL_CHR = 0; // charm CHR
    uint constant LABEL_INT = 1; // intelligence INT
    uint constant LABEL_STR = 2; // strength STR
    uint constant LABEL_MNY = 3; // money MNY

    uint constant LABEL_HPY = 4; // happy SPR
    uint constant LABEL_HLH = 5; // health LIF
    uint constant LABEL_AGE = 6; // age AGE

    string[] private ability_labels = [
        "Charm",
        "Intelligence",
        "Strength",
        "Money",
        "Happy",
        "Health",
        "Age"
    ];

    mapping(uint => RarelifeStructs.SAbilityScore) public _ability_scores;
    mapping(uint => bool) public override character_points_initiated;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeAttributes: not approved or owner");
        _;
    }

    modifier onlyPointsInitiated(uint _actor) {
        require(character_points_initiated[_actor], "RarelifeAttributes: points have not been initiated yet");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) {
    }

    function calculate_point_buy(uint _chr, uint _int, uint _str, uint _mny) public pure returns (uint) {
        return _chr + _int + _str + _mny;
    }

    /* *****************
     * Private Functions
     * *****************
     */

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

    /* ****************
     * External Functions
     * ****************
     */

    function point_character(uint _actor) external 
        onlyApprovedOrOwner(_actor)
    {        
        IRarelifeTalents talents = rlRoute.talents();
        require(talents.actor_talents_initiated(_actor), "RarelifeAttributes: talents have not initiated");
        require(!character_points_initiated[_actor], "RarelifeAttributes: already init points");

        IRarelifeRandom rand = rlRoute.random();
        uint max_point_buy = talents.actor_attribute_point_buy(_actor);
        uint _str = 0;
        if(max_point_buy > 0)
            _str = rand.dn(_actor, max_point_buy);
        uint _chr = 0;
        if((max_point_buy-_str) > 0)
            _chr = rand.dn(_actor+1, max_point_buy-_str);
        uint _int = 0;
        if((max_point_buy-_str-_chr) > 0)
            _int = rand.dn(_actor+2, max_point_buy-_str-_chr);
        uint _mny = max_point_buy-_str-_chr-_int;

        character_points_initiated[_actor] = true;
        _ability_scores[_actor] = RarelifeStructs.SAbilityScore(uint32(_chr), uint32(_int), uint32(_str), uint32(_mny), 100, 100);

        emit Created(msg.sender, _actor, uint32(_chr), uint32(_int), uint32(_str), uint32(_mny), 100, 100);
    }

    function set_attributes(uint _actor, RarelifeStructs.SAbilityScore memory _attr) external override
        onlyPointsInitiated(_actor)
    {
        IRarelifeTimeline timeline = rlRoute.timeline();
        require(_isActorApprovedOrOwner(timeline.ACTOR_ADMIN()), "RarelifeAttributes: not approved or owner of timeline");

        _ability_scores[_actor] = _attr;

        emit Updated(msg.sender, _actor, _attr._chr, _attr._int, _attr._str, _attr._mny, _attr._spr, _attr._lif);
    }

    /* **************
     * View Functions
     * **************
     */

    function ability_scores(uint _actor) external view override returns (RarelifeStructs.SAbilityScore memory) {
        return _ability_scores[_actor];
    }

    function apply_modified(uint _actor, RarelifeStructs.SAbilityModifiers memory attr_modifier) external view override returns (RarelifeStructs.SAbilityScore memory, bool) {
        bool attributesModified = false;
        RarelifeStructs.SAbilityScore memory attrib = _ability_scores[_actor];
        if(attr_modifier._chr != 0) {
            attrib._chr = _attribute_modify(attrib._chr, attr_modifier._chr);
            attributesModified = true;
        }
        if(attr_modifier._int != 0) {
            attrib._int = _attribute_modify(attrib._int, attr_modifier._int);
            attributesModified = true;
        }
        if(attr_modifier._str != 0) {
            attrib._str = _attribute_modify(attrib._str, attr_modifier._str);
            attributesModified = true;
        }
        if(attr_modifier._mny != 0) {
            attrib._mny = _attribute_modify(attrib._mny, attr_modifier._mny);
            attributesModified = true;
        }
        if(attr_modifier._spr != 0) {
            attrib._spr = _attribute_modify(attrib._spr, attr_modifier._spr);
            attributesModified = true;
        }
        if(attr_modifier._lif != 0) {
            attrib._lif = _attribute_modify(attrib._lif, attr_modifier._lif);
            attributesModified = true;
        }

        return (attrib, attributesModified);
    }

    function tokenURI(uint256 _actor) public view returns (string memory) {
        string[7] memory parts;
        //start svg
        RarelifeStructs.SAbilityScore memory _attr = _ability_scores[_actor];
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">', ability_labels[LABEL_CHR], "=", Strings.toString(_attr._chr), '</text>'));
        parts[2] = string(abi.encodePacked('<text x="10" y="40" class="base">', ability_labels[LABEL_INT], "=", Strings.toString(_attr._int), '</text>'));
        parts[3] = string(abi.encodePacked('<text x="10" y="60" class="base">', ability_labels[LABEL_STR], "=", Strings.toString(_attr._str), '</text>'));
        parts[4] = string(abi.encodePacked('<text x="10" y="80" class="base">', ability_labels[LABEL_MNY], "=", Strings.toString(_attr._mny), '</text>'));
        parts[5] = string(abi.encodePacked('<text x="10" y="100" class="base">', ability_labels[LABEL_HPY], "=", Strings.toString(_attr._spr), '</text>'));
        parts[6] = string(abi.encodePacked('<text x="10" y="120" class="base">', ability_labels[LABEL_HLH], "=", Strings.toString(_attr._lif), '</text>'));
        parts[0] = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        //end svg
        parts[1] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), ' attributes"'));
        parts[1] = ', "description": "This is not a game."';
        parts[2] = string(abi.encodePacked(', "data": {', '"CHR": ', Strings.toString(_attr._chr)));
        parts[3] = string(abi.encodePacked(', "INT": ', Strings.toString(_attr._int)));
        parts[4] = string(abi.encodePacked(', "STR": ', Strings.toString(_attr._str)));
        parts[5] = string(abi.encodePacked(', "MNY": ', Strings.toString(_attr._mny)));
        parts[6] = string(abi.encodePacked(', "SPR": ', Strings.toString(_attr._spr)));
        parts[0] = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        parts[1] = string(abi.encodePacked(', "LIF": ', Strings.toString(_attr._lif), '}'));
        //end json with svg
        parts[2] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}
