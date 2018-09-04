pragma solidity 0.4.24;

/// @title interface of committee contract
contract Committee {
    function isMember(address addr) external returns (bool);
}

/**
 * @title proposal voting
 * @author Lin Van <firmianavan@gmail.com>
 */
contract Ballot {

    struct Stage {
        uint startTimeStamp; //当前投票轮次开始时的时间戳
        uint startHeight; //起始高度
        address[] approve; //赞成者
        address[] reject; //反对者
    }

    // 提案
    struct Proposal {
        uint id; // 提案id
        string url;   // 提案地址
        string desc; //简单描述
        Stage[] stages; //分为几个阶段
        uint currentStage;
        uint status; //0 进行中，1成功完成，2失败
    }
    address public ownner;
    Proposal[] proposals;
    uint[]  done;
    uint[]  running;
    

    //------------------------------settings-----------------------------------------------
    uint defaultHeightSpan;  //每个投票轮次的高度跨度
    address committeeAddr;    //理事会合约地址
    //------------------------------events--------------------------------------------------

    event VoteEvent(
        address _from,
        uint _proposalId,
        uint _stage,
        bool _ifAccept
    );
    event NewProposalEvent(
        address _from,
        address _target,
        uint _value,
        uint _round
    );
    //------------------------------events--------------------------------------------------

    constructor() public {
        ownner = msg.sender;
    }

    /**
     * @dev init proposal on chain
     * @return id of this proposal 
     */
    function addProposal(string url,string desc,uint[] stageStartTime)public returns (uint proposalId) {
        require(stageStartTime.length>0,"Must have more than one stage!");
        uint id = proposals.length;
        proposals.push(Proposal(id,url,desc,new Stage[](0),0,0));
        for (uint i = 0; i<stageStartTime.length; i++){
            proposals[id].stages.push(Stage(stageStartTime[i],defaultHeightSpan,new address[](0),new address[](0)));
        }
        running.push(id);
        return id;
    }
    
    /** 
    * @dev proposalId, stage and your attitude must be provided when voting
    */
    function vote(uint proposalId,uint stage,bool ifAccept) public{
        require(Committee(committeeAddr).isMember(msg.sender), "Must be a member of committe");
        require(proposals[proposalId].status == 0, "Proposal must still be in progress");
        require(proposals[proposalId].currentStage+1 == stage, "Voting on wrong stage");

        if (ifAccept){
            proposals[proposalId].stages[stage-1].approve.push(msg.sender);
        }else{
            proposals[proposalId].stages[stage-1].reject.push(msg.sender);
        }
        
        emit VoteEvent(msg.sender,proposalId,stage,ifAccept);
    }
}