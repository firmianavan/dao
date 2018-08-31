pragma solidity ^0.4.22;

/// @title 提案表决
contract Ballot {

    //用来表示一个选民的所有投票
    struct Voter {
        mapping(address => uint) votes;
    }

    // 提案
    struct Proposal {
        uint id; // 提案id
        string url;   // 提案地址
        string desc; //简单描述
        uint stages; //分为几个阶段
        uint currentStage;
        uint status; //0 进行中，1成功完成，2失败
    }
    address public ownner;

    mapping(address => Voter)  voters;
    

    //------------------------------events--------------------------------------------------

    event VoteEvent(
        address _from,
        address _target,
        uint _value,
        uint _round
    );
    event UnvoteEvent(
        address _from,
        address _target,
        uint _value,
        uint _round
    );
    event NewRoundEvent(
        address[] _members,
        uint _round
    );
    //------------------------------events--------------------------------------------------

    
}