pragma solidity 0.4.24;

/// @title base interface for its sub-contracts.
/// @author Lin Van (firmianavan@gmail.com)
contract IBase {
    function balanceOf(address addr) public view returns(uint);
    function voterBalanceOf(address addr) public view returns(uint);
    function memberBalanceOf(address addr) public view returns(uint);
    //--------------member funds operations--------------
    function voterWithdraw(address addr, uint value) external;
    function voterDeposit(address addr) external payable;
    function memberDeposit(address addr) external payable;
    function memberWithdraw(address addr, uint value) external;
    function award(address memberAddr, uint value) external;
    function penalize(address memberAddr, uint value) external;

    //--------------voter funds operations--------------
    function getVote(address from, address to) external view returns(uint);
    function getVoteSum(address member) external view returns(uint);
    function setVote(address from, address to, uint vote) external;

    //-----------------ballot-----------------------
    function getMembers() public view returns (address[] ret);
}