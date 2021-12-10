// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/RarelifeLibrary.sol";

contract RarelifeGold is IRarelifeGold, RarelifeConfigurable {
    /* *******
     * Globals
     * *******
     */

    string public override constant name = "Rarelife Gold";
    string public override constant symbol = "RLG";
    uint8 public override constant decimals = 18;

    uint public override totalSupply = 0;

    mapping(uint => mapping (uint => uint)) public override allowance;
    mapping(uint => uint) public override balanceOf;

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "RarelifeGold: not approved or owner");
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

    function _mint(uint dst, uint amount) internal {
        totalSupply += amount;
        balanceOf[dst] += amount;

        emit Transfer(dst, dst, amount);
    }

    function _transferTokens(uint from, uint to, uint amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function claim(uint _actor, uint _amount) external override {
        require(_amount > 0, "RarelifeGold: amount must not be zero");        
        require(_isActorApprovedOrOwner(rlRoute.timeline().ACTOR_ADMIN()), "RarelifeGold: not approved or owner of timeline");

        _mint(_actor, _amount);
    }

    function approve(uint from, uint spender, uint amount) external override
        onlyApprovedOrOwner(from)
        returns (bool)
    {
        allowance[from][spender] = amount;

        emit Approval(from, spender, amount);
        return true;
    }

    function transfer(uint from, uint to, uint amount) external override
        onlyApprovedOrOwner(from)
        returns (bool)
    {
        _transferTokens(from, to, amount);
        return true;
    }

    function transferFrom(uint executor, uint from, uint to, uint amount) external override
        onlyApprovedOrOwner(executor)
        returns (bool)
    {
        uint spender = executor;
        uint spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint).max) {
            require(spenderAllowance >= amount, "RarelifeGold: spenderAllowance not ennough for amount.");
            uint newAllowance = spenderAllowance - amount;
            allowance[from][spender] = newAllowance;

            emit Approval(from, spender, newAllowance);
        }

        _transferTokens(from, to, amount);
        return true;
    }

    /* **************
     * View Functions
     * **************
     */
}
