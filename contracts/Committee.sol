pragma solidity 0.4.24;

import "./AccessCtrl.sol";
import "./BaseInterface.sol";
/**
 * @title committee voting
 * @author Lin Van <firmianavan@gmail.com>
 */
contract Committee is AccessCtrl{

    //用来表示一个选民的所有投票
    struct Voter {
        mapping(address => uint) votes;
    }

    struct MemberRound {
        uint rank; //
        mapping(uint => int) voteLogs;//voteId => 投票内容 0:未投票 1:赞成 2:反对
    }

    struct Candidate {
        uint weight; // 当前轮次计票的权重=投票者转入的etf金额
        uint rank; //   当前轮次得票排名（members数组中的索引+1） rank为0意味着未注册或已注销
        uint guaranty;   // 剩余保证金
        mapping(uint => MemberRound) rounds; //参与的轮次
    }

    struct Option {
        uint round; //此配置生效时的轮次
        //constants
        //1×30×24×3600/18, 约一月后重新竞选理事   
        uint roundSpan;
        uint withdrawRound;
        uint memberCnt;
        uint memberSalary;//会员每轮次可领奖励
        uint guaranty; // 参选抵押
        uint minGuaranty; // 参选抵押下限（被罚至该范围后无法投票/被选举/从members中移除）
        uint fineForUnvote; // 未投票罚金
        uint fineForWrongVote; // 与最终结果不一致罚金
        uint awardForVote; // 与最终结果一致的奖励
    }
    address public baseContract;

    mapping(address => Voter)  voters;
    mapping(address => Candidate) public candidates;

    address[] public members; //根据当前得票数由大到小的顺序数组
    address[] public onTerm; //在任委员
    Option[] public options;//配置历史

    uint public fromHeight; //当前轮次起始高度
    uint public round=0;    //当前轮次


    //-----------------configuring---------------------------
    function setBaseContract(address addr) public onlyCEO {
        baseContract = addr;
    }

    function getOption(uint _round) internal view returns(Option) {
        for (uint i = options.length; i > 0; i--){
            if (_round > options[i-1].round){
                return options[i-1];
            }
        }
        //should never reach here
        assert(false);
    }

    function setRoundSpan(uint rs, uint _round) public onlyAdmin{
        uint l = options.length;
        options.push(options[l-1]);
        options[l].roundSpan = rs;
        if (_round == 0){
            options[l].round = round+2;
        }else{
            options[l].round = _round;
        }
    }
    function setWithdrawRound(uint wr, uint _round) public onlyAdmin{
        uint l = options.length;
        options.push(options[l-1]);
        options[l].withdrawRound = wr;
        if (_round == 0){
            options[l].round = round+2;
        }else{
            options[l].round = _round;
        }
    }
    function setMemberCnt(uint nc, uint _round) public onlyAdmin{
        uint l = options.length;
        options.push(options[l-1]);
        options[l].memberCnt = nc;
        if (_round == 0){
            options[l].round = round+2;
        }else{
            options[l].round = _round;
        }
    }

    function setBonusAndPenalty(uint memberSalary, uint guaranty, uint minGuaranty, uint fineForUnvote, uint fineForWrongVote, uint awardForVote, uint _round) public onlyAdmin{
        uint l = options.length;
        options.push(options[l-1]);
        options[l].memberSalary = memberSalary;
        options[l].guaranty = guaranty;
        options[l].minGuaranty = minGuaranty;
        options[l].fineForUnvote = fineForUnvote;
        options[l].fineForWrongVote = fineForWrongVote;
        options[l].awardForVote = awardForVote;
        if (_round == 0){
            options[l].round = round+1;
        }else{
            options[l].round = _round;
        }
    }


    ///uint round = 0;
    // uint roundSpan = 144000;
    // uint withdrawRound = 72000;
    // uint memberCnt = 9;
    // uint memberSalary = 1000000000000000000*200;//会员每轮次可领奖励
    // uint guaranty = 1000000000000000000*5000; // 参选抵押
    // uint minGuaranty = 1000000000000000000*2000; // 参选抵押
    // uint fineForUnvote = 1000000000000000000*500; // 未投票罚金
    // uint fineForWrongVote = 1000000000000000000*300; // 与最终结果不一致罚金
    // uint awardForVote = 1000000000000000000*600; // 与最终结果一致的奖励
    constructor() public {
        ceoAddress = msg.sender;
        fromHeight = block.number;
        options.push(Option({
            round : 0,
            roundSpan : 144000,
            withdrawRound : 72000,
            memberCnt : 9,
            memberSalary : 200 ether,
            guaranty : 5000 ether,
            minGuaranty : 2000 ether,
            fineForUnvote : 500 ether,
            fineForWrongVote : 300 ether,
            awardForVote : 600 ether
        }));
        members.length = options[0].memberCnt;
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

    /// @dev auto check if is in new round
    modifier checkRound() {
        while (block.number >= (getOption(round)).roundSpan + fromHeight){
            round++;
            fromHeight += (getOption(round)).roundSpan;

            onTerm.length = (getOption(round)).memberCnt;
            assert(members.length >= onTerm.length);
            for (uint i = 0; i < onTerm.length; i++){
                onTerm[i] = members[i];
                candidates[onTerm[i]].rounds[round] = MemberRound(i+1);
            }

            emit NewRoundEvent(onTerm, round);
        }
        _;
    }

    /// TODO 保证金不够时从members中移除
    modifier checkGuaranty(address candiAddr) {
        require(candidates[candiAddr].guaranty >= getOption(round).minGuaranty, "should provide enough guaranty"); 
        _;
    }

    /// 候选人须保证充足的保证金，补充保证金也可调用此方法
    function guaranteeForCandidate() public payable{
        require(msg.value + candidates[msg.sender].guaranty >= getOption(round).guaranty, "should provide enough guaranty");

        if (candidates[msg.sender].rank == 0){ //rank为0意味着未注册或已注销
            members.push(msg.sender);
            candidates[msg.sender].rank = members.length;
            onChangeWeight(msg.sender);//针对已注销用户重新注册，保留的weight仍可用
        }
        candidates[msg.sender].guaranty += msg.value;
    }
    function unregister() public {
        for (uint i = candidates[msg.sender].rank; i<members.length; i++){
            members[i-1] = members[i];
        }
        members.length = members.length-1;
        candidates[msg.sender].rank = 0;
        BaseInterface(baseContract).unregister(msg.sender);
    }
    /// @dev withdraw all(ie. total - guaranty)
    function receiveAwards() public {
        BaseInterface(baseContract).withdrawMemberAccountUnit(msg.sender, getOption(round).guaranty);
    }

    /// @dev 排序前置 保证members始终是有序的. 
    /// 原因是希望solidy不存在一种后台调度系统定时发放发放轮次奖励，而若将轮次结算放到每次vote，getMember动作中，仍会面临整个轮次中没有任何vote或getMeber动作， 是被动的有member发起，
    function onChangeWeight(address mem) internal checkRound{

        uint r = candidates[mem].rank-1; //members中的索引
        if ( r>0 && candidates[members[r-1]].weight < candidates[mem].weight){ //weight 增加，向前遍历
            for (uint i = r; i>0; i--){
                if (candidates[members[i-1]].weight < candidates[members[i]].weight){
                    candidates[members[i]].rank--;
                    candidates[members[i-1]].rank++;
                    address t = members[i];
                    members[i] = members[i-1];
                    members[i-1] = t;
                    assert(candidates[members[i]].rank == i+1 && candidates[members[i-1]].rank == i);
                }
            }
        }else if (r < members.length-1 && candidates[members[r+1]].weight > candidates[mem].weight){ //weight 减少， 向后遍历
            for (i = r; i < members.length-1; i++){
                if (candidates[members[i+1]].weight > candidates[members[i]].weight){
                    candidates[members[i]].rank++;
                    candidates[members[i+1]].rank--;
                    t = members[i];
                    members[i] = members[i+1];
                    members[i+1] = t;
                    assert(candidates[members[i]].rank == i+1 && candidates[members[i+1]].rank == i+2);
                }
            }
        }
    }
    function vote(address candidateAddr) public payable checkGuaranty(candidateAddr){
        BaseInterface(baseContract).lock.value(msg.value)(msg.sender);

        candidates[candidateAddr].weight += msg.value;
        voters[msg.sender].votes[candidateAddr] += msg.value;
        onChangeWeight(candidateAddr);        

        emit VoteEvent(msg.sender,candidateAddr,msg.value,round);
    }
    function revote(address from, address to, uint value) public checkGuaranty(to){
        require(candidates[from].weight >= value, "you do not have enough votes");
        require(voters[msg.sender].votes[from] >= value, "you do not have enough votes");

        candidates[from].weight -= value;
        voters[msg.sender].votes[from] -= value;
        onChangeWeight(from);
        emit UnvoteEvent(msg.sender,from,value,round);

        candidates[to].weight += value;
        voters[msg.sender].votes[to] += value;
        onChangeWeight(to);
        emit VoteEvent(msg.sender,to,value,round);

    }

    function withdraw(address from, uint value) public {
        require(candidates[from].weight >= value, "you do not have enough votes");
        require(voters[msg.sender].votes[from] >= value, "you do not have enough votes");
        require(block.number - fromHeight >= getOption(round).withdrawRound, "your funds is still locked now");

        BaseInterface(baseContract).withdraw(msg.sender,value);

        onChangeWeight(from);
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
    function getMembers() public  checkRound returns (address[] ret) {
        return onTerm;
    }
    function isMember(address addr) external  checkRound returns (bool){
        for (uint i = 0; i < onTerm.length; i++){
            if(addr == onTerm[i]){
                return true;
            }
        }
        return false;
    }
}