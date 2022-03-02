// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/RarelifeLibrary.sol";

contract RarelifeNames is IRarelifeNames, RarelifeConfigurable, ERC721Enumerable {

    /* *******
     * Globals
     * *******
     */

    uint public override next_name = 1;

    mapping(uint => string) public names;  // token => name
    mapping(uint => string) public first_names;  // token => first_name
    mapping(uint => string) public last_names;  // token => last_name
    mapping(uint => uint) public actor_to_name_id; // actor => token
    mapping(uint => uint) public name_id_to_actor; // token => actor
    mapping(string => bool) private _is_name_claimed;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeNames: not approved or owner");
        _;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    // @dev Claim a name for a actor. actor must hold the required gold.
    function claim(string memory firstName, string memory lastName, uint actor) public
        onlyApprovedOrOwner(actor)
        returns (uint name_id)
    {
        //require(rlRoute.timeline().character_born(actor), 'RarelifeNames: character have not born in timeline');
        string memory name = string(abi.encodePacked(lastName,firstName));
        require(validate_name(name), 'RarelifeNames: invalid name');
        string memory lower_name = to_lower(name);
        require(!_is_name_claimed[lower_name], 'RarelifeNames: name taken');

        _mint(msg.sender, next_name);
        name_id = next_name;
        next_name++;
        names[name_id] = name;
        first_names[name_id] = firstName;
        last_names[name_id] = lastName;
        _is_name_claimed[lower_name] = true;
        
        assign_name(name_id, actor);
        
        emit NameClaimed(msg.sender, actor, name_id, name, firstName, lastName);
    }

    // @dev Move a name to a (new) actor
    function assign_name(uint name_id, uint to) public 
        onlyApprovedOrOwner(to)
    {
        require(_isApprovedOrOwner(msg.sender, name_id), "RarelifeNames: !owner or approved name");
        require(actor_to_name_id[to] == 0, "RarelifeNames:  actor already named");
        uint from = name_id_to_actor[name_id];
        if (from > 0)
            actor_to_name_id[from] = 0;
        actor_to_name_id[to] = name_id;
        name_id_to_actor[name_id] = to;

        emit NameAssigned(name_id, from, to);
    }

    // @dev Unlink a name from a actor without transferring it.
    //      Use move_name to reassign the name.
    function clear_actor_name(uint actor) public {
        uint name_id = actor_to_name_id[actor];
        require(_isActorApprovedOrOwner(actor) || _isApprovedOrOwner(msg.sender, name_id), "RarelifeNames: !owner or approved");
        actor_to_name_id[actor] = 0;
        name_id_to_actor[name_id] = 0;

        emit NameAssigned(name_id, actor, 0);
    }

    // @dev Change the capitalization (as it is unique).
    //      Can't change the name.
    function update_capitalization(uint name_id, string memory new_name) public {
        require(_isApprovedOrOwner(msg.sender, name_id), "RarelifeNames: !owner or approved name");
        require(validate_name(new_name), 'RarelifeNames: invalid name');
        string memory name = names[name_id];
        require(keccak256(abi.encodePacked(to_lower(name))) == keccak256(abi.encodePacked(to_lower(new_name))), 'RarelifeNames: name different');
        names[name_id] = new_name;

        emit NameUpdated(name_id, name, new_name);
    }

    // @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    function validate_name(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 last_char = b[0];
        for(uint i; i<b.length; i++){
            bytes1 char = b[i];
            if (char == 0x20 && last_char == 0x20) return false; // Cannot contain continous spaces
            last_char = char;
        }

        return true;
    }

    // @dev Converts the string to lowercase
    function to_lower(string memory str) public pure returns (string memory) {
        bytes memory b_str = bytes(str);
        bytes memory b_lower = new bytes(b_str.length);
        for (uint i = 0; i < b_str.length; i++) {
            // Uppercase character
            if ((uint8(b_str[i]) >= 65) && (uint8(b_str[i]) <= 90)) {
                b_lower[i] = bytes1(uint8(b_str[i]) + 32);
            } else {
                b_lower[i] = b_str[i];
            }
        }
        return string(b_lower);
    }

    /* *****************
     * Private Functions
     * *****************
     */

    constructor(address rlRouteAddress) RarelifeConfigurable(rlRouteAddress) ERC721("Rarelife Names", "NAMES") {
    }

    /* ****************
     * External Functions
     * ****************
     */

    /* **************
     * View Functions
     * **************
     */

    function actor_name(uint _actor) public override view returns (string memory name, string memory firstName, string memory lastName){
        uint id = actor_to_name_id[_actor];
        name = names[id];
        firstName = first_names[id];
        lastName = last_names[id];
    }

    function is_name_claimed(string memory firstName, string memory lastName) external view returns(bool is_claimed) {
        is_claimed = _is_name_claimed[to_lower(string(abi.encodePacked(lastName,firstName)))];
    }

    function tokenURI(uint256 name_id) public override view returns (string memory) {
        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        uint actor = name_id_to_actor[name_id];
        if (actor > 0) {
            parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">Name #', Strings.toString(name_id), ':', names[name_id], '</text>'));
            parts[2] = string(abi.encodePacked('<text x="10" y="40" class="base">Belongs to actor#', Strings.toString(actor), '</text>'));
        }
        //end svg
        parts[3] = string(abi.encodePacked('</svg>'));
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

         //start json
        parts[0] = string(abi.encodePacked('{"name": "Name #', Strings.toString(name_id), '"'));
        parts[1] = ', "description": "This is not a game."';
        parts[2] = string(abi.encodePacked(', "data": {', '"name": "', names[name_id]));
        parts[3] = string(abi.encodePacked('", "firstName": "', first_names[name_id]));
        parts[4] = string(abi.encodePacked('", "lastName": "', last_names[name_id], '"}'));

        //end json with svg
        parts[5] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]))));

        //final output
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}