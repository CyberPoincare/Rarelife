// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//import "hardhat/console.sol";
import "./interfaces/RarelifeLibrary.sol";

contract Rarelife is IRarelife, ERC721Enumerable {

    /* *******
     * Globals
     * *******
     */

    uint public _next_actor;

    mapping(uint => uint) public mint_time;
    mapping(uint => uint) public status;    //0=nonexist，1=dead（but exist），2=live active

    string[] private status_labels = [
        "Not Exist",
        "Dead",
        "Active"
    ];
    
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isApprovedOrOwner(msg.sender, _actor), "Rarelife: not approved or owner");
        _;
    }

    modifier onlyDeath(uint _actor) {
        require(status[_actor] == 1, "Rarelife: not death actor");
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

    constructor() ERC721("Rarelife Manifested", "RLM") {
    }

    /* ****************
     * External Functions
     * ****************
     */

    function mint_actor() external override
    {
        //console.log("mint log");
        _safeMint(msg.sender, _next_actor);
        mint_time[_next_actor] = block.timestamp;
        status[_next_actor] = 2;

        emit actorMinted(msg.sender, _next_actor, mint_time[_next_actor]);
        _next_actor++;
    }

    /* **************
     * View Functions
     * **************
     */

    function actor(uint _actor) external override view returns (uint _mintTime, uint _status) 
    {
        _mintTime = mint_time[_actor];
        _status = status[_actor];
    }

    function next_actor() external override view returns (uint) {
        return _next_actor;
    }

    function tokenURI(uint256 _actor) public override view returns (string memory) {
        //console.log("view log: _actor=%s, ", _actor);
        string[7] memory parts;
        //start svg
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="20" class="base">Mint time:', Strings.toString(mint_time[_actor]), '</text>'));
        parts[2] = string(abi.encodePacked('<text x="10" y="40" class="base">', status_labels[status[_actor]], '</text>'));
        //end svg
        parts[3] = '</svg>';
        string memory svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));

        //start json
        parts[0] = string(abi.encodePacked('{"name": "Actor #', Strings.toString(_actor), '"'));
        parts[1] = ', "description": "This is not a game."';
        parts[2] = string(abi.encodePacked(', "data": {', '"mint_time": ', Strings.toString(mint_time[_actor])));
        parts[3] = string(abi.encodePacked(', "status": ', Strings.toString(status[_actor]), '}'));
        //end json with svg
        parts[4] = string(abi.encodePacked(', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]))));

        //final output
        return string(abi.encodePacked('data:application/json;charset=utf-8;base64,', json));
    }
}
