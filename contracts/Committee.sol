pragma solidity 0.4.24;

/**
 * @title committee voting
 * @author Lin Van <firmianavan@gmail.com>
 */
contract Committee {

    //用来表示一个选民的所有投票
    struct Voter {
        mapping(address => uint) votes;
    }

    struct Candidate {
        uint weight; // 计票的权重=投票者转入的etf金额
        uint refreshHeight;   // 最新一次激活高度
    }
    address public ownner;

    mapping(address => Voter)  voters;
    mapping(address => Candidate) public candidates;

    // 在任理事
    address[] public members;
    address[] public candidateIndex;
    uint public fromHeight;
    uint public round=0;

    //constants
    //3×30×24×3600/18, 约三月后重新竞选理事
    uint public roundSpan = 144000;
    uint public withdrawRound = 72000;
    uint public memberCnt = 9;

    //-----------------configuring---------------------------
    function setRoundSpan(uint rs) public{
        require(msg.sender==ownner,"no permission");
        roundSpan = rs;
    }
    function setWithdrawRound(uint wr) public{
        require(msg.sender==ownner,"no permission");
        withdrawRound = wr;
    }
    function setMemberCnt(uint nc) public{
        require(msg.sender==ownner,"no permission");
        memberCnt = nc;
        members.length = nc;
    }


    ///
    constructor() public {
        fromHeight = block.number;
        ownner = msg.sender;
        members.length = memberCnt;
    }

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
    event TestEvent(
        string _msg,
        uint _num
    );
    //------------------------------events--------------------------------------------------

    /// 候选人在第一次注册后须定期(每个投票周期内)激活
    function registerCandidate() public {
        for (uint i = 0;i < candidateIndex.length;i++){
            if (candidateIndex[i] == msg.sender){
                candidates[msg.sender].refreshHeight = block.number;
                return;
            }
        }
        candidateIndex.push(msg.sender);
        candidates[msg.sender] = Candidate(0,block.number);
    }

    function newRound() internal {
        if (block.number-fromHeight >= round){
            //排序得出得票最高的前memberCnt个
            for (uint i = 0;i < candidateIndex.length;i++){
                for (uint j = memberCnt; j>0; j--){
                    if (candidates[candidateIndex[i]].weight <= candidates[members[j-1]].weight){                        
                        break;
                    }else{
                        if (j < memberCnt){
                            members[j] = members[j-1];
                        }
                        members[j-1] = candidateIndex[i];
                    }
                }
            }

        }
        emit NewRoundEvent(members,round);
    }

    function test() public pure returns (uint,uint){
        uint i = 0;
        uint j = 2;
        while ( i < 3){
            while (j>=0){
                j = j-1;
            }
            i = i+1;
        }
        return (i,j);
    }

    function vote(address candidateAddr) public payable {
        //  require(block.number - candidates[candidateAddr].refreshHeight < roundSpan, "The candidate you vote did not register in this round");
        candidates[candidateAddr].weight += msg.value;
        voters[msg.sender].votes[candidateAddr] += msg.value;

        emit VoteEvent(msg.sender,candidateAddr,msg.value,round);
    }
    function revote(address from, address to, uint value) public {
        require(block.number - candidates[to].refreshHeight < roundSpan, "The candidate you vote did not register in this round");
        require(candidates[from].weight >= value, "you do not have enough votes");
        require(voters[msg.sender].votes[from] >= value, "you do not have enough votes");
        candidates[from].weight -= value;
        candidates[to].weight += value;
        voters[msg.sender].votes[from] -= value;
        voters[msg.sender].votes[to] += value;

        emit UnvoteEvent(msg.sender,from,value,round);
        emit VoteEvent(msg.sender,to,value,round);

    }

    function withdraw(address from, uint value) public {
        require(candidates[from].weight >= value, "you do not have enough votes");
        require(voters[msg.sender].votes[from] >= value, "you do not have enough votes");
        require(block.number - fromHeight >= withdrawRound, "you do not have enough votes");
        msg.sender.transfer(value);
        emit UnvoteEvent(msg.sender,from,value,round);
    }
    ///获取投票人对某个candidate的投票数
    function getVoterVotes(address voter, address candidate) public view returns (uint) {
        return (voters[voter].votes)[candidate];
    }
    ///获取某个candidate的总得票数
    function getCandidateVotes(address candidate) public view returns (uint) {
        return (candidates[candidate]).weight;
    }
    function getMembers() public returns (address[] ret) {
        newRound();
        require(candidates[members[memberCnt-1]].weight > 0, "no enough vote, some candidate has no votes");
        return members;
    }
    function isMember(address addr) external returns (bool){
        newRound();
        require(candidates[members[memberCnt-1]].weight > 0, "no enough vote, some candidate has no votes");
        for (uint i = 0; i < members.length; i++){
            if(addr == members[i]){
                return true;
            }
        }
        return false;
    }
}