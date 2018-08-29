pragma solidity ^0.4.22;

/// @title 理事会选举
contract Committee {

    //用来表示一个选民的所有投票
    struct Voter {
        mapping(address => uint) votes;
    }

    // 一个投票单元，投谁投多少
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
    uint public roundSpan = 432000;
    uint public withdrawRound = 144000;
    uint public memberCnt = 9;

    ///startFrom，区块高度，用来定义第一次选举的时间，如，round是3月，startFrom是两月前的高度，则第一次选举大约有一月的时间
    constructor() public {
        fromHeight = block.number;
        ownner = msg.sender;
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
                for (uint j = memberCnt-1; j>=0; j--){
                    if (candidates[candidateIndex[i]].weight <= candidates[members[j]].weight){                        
                        break;
                    }else{
                        members[j+1] = members[j];
                        members[j] = candidateIndex[i];
                    }
                }
            }

        }
        emit NewRoundEvent(members,round);
    }

    function vote(address candidateAddr) public payable {
        require(block.number - candidates[candidateAddr].refreshHeight < roundSpan, "The candidate you vote did not register in this round");
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
    function getMembers() public returns (address[20] ret, uint length) {
        newRound();
        require(candidates[members[memberCnt]].weight > 0, "no enough vote, some candidate has no votes");
        for (uint i = 0; i < memberCnt; i++){
            ret[i] = members[i];
        }
        return (ret,memberCnt);
    }
}