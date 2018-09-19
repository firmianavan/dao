pragma solidity 0.4.24;

import "./BaseInterface.sol";
import "./AccessCtrl.sol";


/**
 * @title proposal voting
 * @author Lin Van <firmianavan@gmail.com>
 * @dev 考虑要添加后台及交互页面，设计为把部分逻辑(智能合约不太支持定时任务)转移到后台执行，保持合约的简单，不容易有漏洞
 */
contract Ballot is AccessCtrl{

    struct VoteRound {
        uint id;
        address[] member;//投票启动是的在任理事（出现投票跨理事任期的时候以启动时在任历史为准）
        mapping(address => uint) vote; //对应member的投票结果 0:未投票 1:投赞成 2:投反对 3:投弃权
        uint finalPass; // 0 投票期间 1:投票结束且最终通过 2:投票结束且最终被拒
        uint startHeight; //启动时高度
        uint span;  //持续时间（以高度跨度计量）
    }
    
    uint constant voting = 0;
    uint constant votePass = 1;
    uint constant voteFail = 2;
    address public ownner;
    
    mapping(uint => VoteRound) rounds;
    

    //------------------------------settings-----------------------------------------------
    uint defaultHeightSpan;  //每个投票轮次的高度跨度
    address baseContract;    //理事会合约地址
    //------------------------------events--------------------------------------------------

    event VoteEvent(
        address _from,
        uint _id,
        uint _opinion
    );
    event NewProposalEvent(
        address _from,
        address _target,
        uint _value,
        uint _round
    );
    //------------------------------events--------------------------------------------------

    constructor(address baseAddr) public {
        ownner = msg.sender;
        baseContract = baseAddr;
        defaultHeightSpan = 3600*24/9;//大约2天
    }

    /**
     * @dev init proposal on chain  可以重复开启（项目延期的情况）
     */
    function startRound(uint id) public {
        rounds[id].id = id;
        rounds[id].member = BaseInterface(baseContract).getMembers();
        rounds[id].finalPass = voting;
        rounds[id].startHeight = block.number;
        rounds[id].span = defaultHeightSpan;
    }
    
    /** 
    * @dev 结束之前可以重复投票，后面的结果覆盖前面的
    */
    function vote(uint id,uint opinion) public{
        require(contains(rounds[id].member, msg.sender), "Must be a member of committe");
        require(rounds[id].finalPass == 0, "Proposal must still be in progress");
        rounds[id].vote[msg.sender] = opinion;
        
        emit VoteEvent(msg.sender,id,opinion);
    }
    
    /// @param stage start from zero
    function voteInfo(uint proposalId, uint stage) public returns(uint[50] votes, uint memberCnt, uint endHeight){
        memberCnt = BaseInterface(baseContract).memberCount();
        endHeight = proposals[proposalId].stages[stage].startHeight + defaultHeightSpan;
        for(uint i = 0; i < proposals[proposalId].stages[stage].approve.length; i++){
            votes[i] = 1;
        }
        for(i = 0; i < proposals[proposalId].stages[stage].reject.length; i++){
            votes[i] = 2;
        }
    }

    function sumerize(uint proposalId, uint stage, bool ifAccept) public onlyAdmin{
        proposals[proposalId].stages[stage].finalPass = ifAccept;
        //奖惩
        for(uint i = 0; i < proposals[proposalId].stages[stage].approve.length; i++){
            
        }
        for(i = 0; i < proposals[proposalId].stages[stage].reject.length; i++){
            votes[i] = 2;
        }
    }

    function contains(address[] storage src,address addr) internal view returns(bool){
        for (uint i = 0; i < src.length; i++){
            if(addr == src[i]){
                return true;
            }
        }
        return false;
    }
}