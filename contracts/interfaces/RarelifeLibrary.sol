// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RarelifeInterfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
//-----------------------------------------------------------------------------
/**
 * @dev String operations.
 */
library RarelifeStrings {
    
    function toString(int value) internal pure returns (string memory) {
        string memory _string = '';
        if (value < 0) {
            _string = '-';
            value = value * -1;
        }
        return string(abi.encodePacked(_string, Strings.toString(uint(value))));
    }
}
//-----------------------------------------------------------------------------
library RarelifeConstants {

    //time constants
    uint public constant DAY = 1 days;
    uint public constant HOUR = 1 hours;
    uint public constant MINUTE = 1 minutes;
    uint public constant SECOND = 1 seconds;
}
//-----------------------------------------------------------------------------
contract RarelifeContractRoute {
    // Deployment Address
    address internal _owner;    
 
    address                 public randomAddress;
    IRarelifeRandom         public random;
 
    address                 public rlAddress;
    IRarelife               public rl;
 
    address                 public evtsAddress;
    IRarelifeEvents         public evts;

    address                 public timelineAddress;
    IRarelifeTimeline       public timeline;

    address                 public namesAddress;
    IRarelifeNames          public names;

    address                 public attributesAddress;
    IRarelifeAttributes     public attributes;

    address                 public talentsAddress;
    IRarelifeTalents        public talents;

    address                 public goldAddress;
    IRarelifeGold           public gold;

    constructor() {
        _owner = msg.sender;
    }

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyContractOwner() {
        require(msg.sender == _owner, "RarelifeContractRoute: Only contract owner");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "RarelifeContractRoute: cannot set contract as zero address");
        _;
    }

    /* ****************
     * External Functions
     * ****************
     */

    function registerRandom(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(randomAddress == address(0), "RarelifeContractRoute: address already registered.");
        randomAddress = _address;
        random = IRarelifeRandom(_address);
    }

    function registerRLM(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(rlAddress == address(0), "RarelifeContractRoute: address already registered.");
        rlAddress = _address;
        rl = IRarelife(_address);
    }

    function registerEvents(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(evtsAddress == address(0), "RarelifeContractRoute: address already registered.");
        evtsAddress = _address;
        evts = IRarelifeEvents(_address);
    }

    function registerTimeline(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(timelineAddress == address(0), "RarelifeContractRoute: address already registered.");
        timelineAddress = _address;
        timeline = IRarelifeTimeline(_address);
    }

    function registerNames(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(namesAddress == address(0), "RarelifeContractRoute: address already registered.");
        namesAddress = _address;
        names = IRarelifeNames(_address);
    }

    function registerAttributes(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(attributesAddress == address(0), "RarelifeContractRoute: address already registered.");
        attributesAddress = _address;
        attributes = IRarelifeAttributes(_address);
    }

    function registerTalents(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(talentsAddress == address(0), "RarelifeContractRoute: address already registered.");
        talentsAddress = _address;
        talents = IRarelifeTalents(_address);
    }

    function registerGold(address _address) external 
        onlyContractOwner()
        onlyValidAddress(_address)
    {
        require(goldAddress == address(0), "RarelifeContractRoute: address already registered.");
        goldAddress = _address;
        gold = IRarelifeGold(_address);
    }
}
//-----------------------------------------------------------------------------
contract RarelifeConfigurable {
    // Deployment Address
    address internal _owner;    

    // Address of the Reallife Contract Route
    address public rlRouteContract;
    RarelifeContractRoute internal rlRoute;

    constructor(address rlRouteAddress) {
        _owner = msg.sender;
        require(rlRouteAddress != address(0), "RarelifeConfigurable: cannot set contract as zero address");
        rlRouteContract = rlRouteAddress;
        rlRoute = RarelifeContractRoute(rlRouteAddress);
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        IRarelife rl = rlRoute.rl();
        return (rl.getApproved(_actor) == msg.sender || rl.ownerOf(_actor) == msg.sender) || rl.isApprovedForAll(rl.ownerOf(_actor), msg.sender);
    }
}
