pragma solidity 0.4.24;

/// @title base interface for its sub-contracts.
/// @author Lin Van (firmianavan@gmail.com)
contract BaseInterface {

    //--------------member funds operations--------------
    function register(address memberAddr) external payable;
    function unregister(address memberAddr) external;
    function withdrawMemberAccountUnit(address memberAddr, uint threshold) external;
    function award(address memberAddr, uint value) external;
    function penalize(address memberAddr, uint value) external;

    //--------------voter funds operations--------------
    function withdraw(address voter, uint val) external;
    function lock(address voter) external payable;
}