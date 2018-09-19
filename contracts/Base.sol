pragma solidity 0.4.24;

import "./AccessCtrl.sol";
import "./iterable_mapping.sol";

///@dev main contract, maintains 2 sub-contracts and their results, funds of the committee 
contract Base is AccessCtrl {

    string public name;
    string public symbol;
    address public committeeAddr;
    address public ballotAddr;

    //投票及收益均以etf的形式放在主合约
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public memberbalanceOf;
    mapping(address => uint) public voterbalanceOf;



    constructor () public{
        name = "locked etf";
        symbol = "ETF";
        ceoAddress = msg.sender;
    }

    function setCommitteeAddr(address newCommitteeAddr) public onlyAdmin{
        require(newCommitteeAddr != address(0));
        committeeAddr = newCommitteeAddr;
    }
    function setBallotAddr(address newBallotAddr) public onlyAdmin{
        require(newBallotAddr != address(0));
        ballotAddr = newBallotAddr;
    }


    /// @dev Access modifier for call only from sub-contract
    modifier fromSub() {
        require(msg.sender == ballotAddr || msg.sender == committeeAddr);
        _;
    }
    function () public payable {}


    //--------------voter funds operations--------------
    /// @dev used to retrieve funds of voter
    function voterWithdraw(address voter, uint val) external fromSub whenNotPaused{
        require(balanceOf[voter] >= val);
        require(voterbalanceOf[voter] >= val);
        voterbalanceOf[voter] -= val;
        balanceOf[voter] -= val;
        voter.transfer(val);
    }

    /// @dev used to receive fund for voting
    function voterDeposit(address voter) external payable fromSub whenNotPaused{
        balanceOf[voter] += msg.value;
        voterbalanceOf[voter] += msg.value;
    }

    //--------------member funds operations--------------
    function memberDeposit(address memberAddr) external payable fromSub whenNotPaused{
        balanceOf[memberAddr] += msg.value;
        memberbalanceOf[memberAddr] += msg.value;
    }
    function memberWithdraw(address memberAddr, uint val) external fromSub whenNotPaused{
        require(memberbalanceOf[memberAddr] >= val);
        require(balanceOf[memberAddr] >= val);
        memberbalanceOf[memberAddr] -= val;
        balanceOf[memberAddr] -= val;
        memberAddr.transfer(val);
    }
    function award(address memberAddr, uint value) external fromSub whenNotPaused{
        memberbalanceOf[memberAddr] += value;
        balanceOf[memberAddr] += value;
    }
    function penalize(address memberAddr, uint value) external fromSub whenNotPaused{
        require(memberbalanceOf[memberAddr] >= value);
        require(balanceOf[memberAddr] >= value);
        memberbalanceOf[memberAddr] -= value;
        balanceOf[memberAddr] -= value;
    }

    // --------------------------------------------- 存储并读写理事会核心数据，方便升级理事会选举合约 ----------------------------------------------
    struct VoterInfo {
        // uint idx;
        IterableMapping.itmap vote; //对别人的投票
    }
    struct CandidateInfo {
        uint sum;
        IterableMapping.itmap votee;//来自别人的投票
    }
    mapping(address => VoterInfo) voters;
    mapping(address => CandidateInfo) candidates;
    address[]  voterAddrs;
    address[]  candidateAddrs;

    //用来从主合约读取数据的公共分页函数
    function getLimitedVoterdAddrs(uint256 from, uint len) public view returns (address[], uint256){
        return limit(voterAddrs, from, len);
    }
    function getLimitedCandidateAddrs(uint256 from, uint len) public view returns (address[], uint256){
        return limit(candidateAddrs, from, len);
    }
    function getVoterInfo(address v,uint256 from, uint len) public view returns (address[] addrs, uint[] votes ,uint256 to, bool isDone){
        return IterableMapping.iterate_limit(voters[v].vote,from,len);
    }
    function getCandInfo(address v,uint256 from, uint len) public view returns (address[] addrs, uint[] votes ,uint256 to, bool isDone){
        return IterableMapping.iterate_limit((candidates[v]).votee,from,len);
    }

    //子合约用来读写数据
    function getVote(address from, address to) external view returns(uint) {
        return IterableMapping.get(voters[from].vote,to);
    }
    /// @dev 获取候选人的当前总得票数
    function getVoteSum(address member) external view returns(uint) {
        return candidates[member].sum;
    }
    ///@dev 须由调用方协调使用上面的withdraw和deposit，保证voterBalanceOf与其所有投票的和一致
    function setVote(address from, address to, uint vote) external fromSub whenNotPaused{
        IterableMapping.insert(voters[from].vote,to,vote);
        uint ori = IterableMapping.get(candidates[to].votee, from);
        if (ori > vote){
            candidates[to].sum -= (ori-vote);
        }else{
            candidates[to].sum += (vote-ori);
        }
        IterableMapping.insert(candidates[to].votee,from,vote);
        assert(IterableMapping.get(voters[from].vote,to) == IterableMapping.get(candidates[to].votee,from));
    }
    
    //-----------------------------------------------------------------------------------------------------------------------------------
    
    //--------------------------- tool ----------------------------------
    function limit(address[] storage src, uint256 from, uint len) internal view returns(address[] addrs,uint256 to) {
        uint256 length = len;
        if (length > src.length - from) {
            length = src.length - from;
        }
        addrs = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addrs[i] = src[from + i];
        }

        return (addrs, from + length);
    }
    // function balanceOf(address addr) public view returns(uint);
    // function voterBalanceOf(address addr) public view returns(uint);
    // function memberBalanceOf(address addr) public view returns(uint);

    // function setMembers(address[] _members) external fromCommittee{
    //     members = _members;
    // }

    function getMembers() public view returns (address[] ret) {
        return ICommittee(committeeAddr).getMembers();
    }

    // function isMember(address addr) external view returns (bool){
    //     for (uint i = 0; i < members.length; i++){
    //         if(addr == members[i]){
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // //--------------------------------- ballot related --------------------------------------------------
    // function setBallotResult(uint ballotId, bool isAccepted) external fromBallot{
    //     ballotResult[ballotId] = isAccepted;
    // }
}
contract ICommittee{
    function getMembers() public view returns (address[]);
}