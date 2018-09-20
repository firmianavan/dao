pragma solidity 0.4.24;

import "./IBase.sol";
import "./AccessCtrl.sol";


/**
 * @title proposal voting
 * @author Lin Van <firmianavan@gmail.com>
 * @dev 考虑要添加后台及交互页面，设计为把部分逻辑(智能合约不太支持定时任务)转移到后台执行，保持合约的简单，不容易有漏洞
 */
contract Ballot is SubCtrl{

    struct VoteRound {
        uint id;
        address[] member;//投票启动是的在任理事（出现投票跨理事任期的时候以启动时在任历史为准）
        mapping(address => uint) vote; //对应member的投票结果 0:未投票 1:投赞成 2:投反对 3:投弃权
        uint finalPass; // 0 投票期间 1:投票结束且最终通过 2:投票结束且最终被拒
        uint startHeight; //启动时高度
        uint span;  //持续时间（以高度跨度计量）
    }
    
    uint constant voting = 0;
    uint constant ballotPass = 1;
    uint constant ballotFail = 2;
    uint constant unvote = 0;
    uint constant approve = 1;
    uint constant reject = 2;
    uint constant Abstain = 3;
    address public ownner;
    
    mapping(uint => VoteRound) rounds;
    

    //------------------------------settings-----------------------------------------------
    uint public defaultHeightSpan;  //每个投票轮次的高度跨度

    uint public awardForVote;
    uint public fineForUnvote;
    uint public fineForMisvote;

    function setDefaultHeightSpan(uint _a) public onlyAdmin{
        defaultHeightSpan = _a;
    }   
    function setAwardForVote(uint _a) public onlyAdmin{
        awardForVote = _a;
    }
    function setFineForUnvote(uint _a) public onlyAdmin{
        fineForUnvote = _a;
    }
    function setFineForMisvote(uint _a) public onlyAdmin{
        fineForMisvote = _a;
    }
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
        ownner = baseAddr;
        baseContract = baseAddr;
        defaultHeightSpan = 3600*24/9;//大约2天
        fineForUnvote = 500 ether;
        fineForMisvote = 300 ether;
        awardForVote = 600 ether;
    }

    /**
     * @dev init proposal on chain  可以重复开启（项目延期的情况）
     */
    function startRound(uint id) public onlyAdmin {
        rounds[id].id = id;
        rounds[id].member = IBase(baseContract).getMembers();
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
        require(rounds[id].startHeight + rounds[id].span >= block.number, "Proposal must still be in progress");
        require(opinion == ballotPass || opinion == ballotFail, "");
        rounds[id].vote[msg.sender] = opinion;
        
        emit VoteEvent(msg.sender,id,opinion);
    }
    
    /// @dev TODO 使用salt加密用户投票信息，使得别人不能看到当前投票情况
    function voteInfo(uint id) public onlyAdmin returns(address[] members, uint[] opinion, uint finalPass, uint endHeight){
        members = new address[](rounds[id].member.length);
        opinion = new uint[](members.length);
        for (uint i = 0; i < members.length; i++){
            members[i] = rounds[id].member[i];
            opinion[i] = rounds[id].vote[members[i]];
        }
        finalPass = rounds[id].finalPass;
        endHeight = rounds[id].startHeight + rounds[id].span;
    }

    /// @dev 结算：
    /// 1. 余额不足不应报错
    /// @param oneVoteVeto 一票否决 0:未行使
    /// @param supplemental 补充投票 正反双方票数相等时起作用
    function clear(uint id, uint supplemental, bool oneVoteVeto) public onlyAdmin{
        require(rounds[id].startHeight + rounds[id].span < block.number, "vote must be finished");
        uint approves = 0;
        uint rejects = 0;
        for(uint i = 0; i < rounds[id].member.length; i++){
            if (rounds[id].vote[rounds[id].member[i]] == approve){ //未投票
                approves++;
            }else if (rounds[id].vote[rounds[id].member[i]] == reject){
                rejects++;
            }
        }
        require(!(approves == rejects && oneVoteVeto == false && (supplemental == approve || supplemental == reject )), "the number of approve and reject are equal, you should provide your opinion");
        uint finalResult;
        if (oneVoteVeto){ //对项目行驶一票否决权
            finalResult = reject;
        }else if (approves > reject){
            finalResult = approve;
        }else if (approves < reject){
            finalResult = reject;
        }else {
            finalResult = supplemental;
        }
        //奖惩
        for(i = 0; i < rounds[id].member.length; i++){
            if (rounds[id].vote[rounds[id].member[i]] == unvote){ //未投票者
                IBase(baseContract).penalize(rounds[id].member[i], fineForUnvote);
            }else if(rounds[id].vote[rounds[id].member[i]] == finalResult){ //奖励
                IBase(baseContract).award(rounds[id].member[i], awardForVote);
            }else{ //惩罚
                IBase(baseContract).penalize(rounds[id].member[i], fineForMisvote);
            }
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