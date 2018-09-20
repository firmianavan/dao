pragma solidity 0.4.24;

import "./AccessCtrl.sol";
import "./IBase.sol";
/**
 * @title committee voting
 * @author Lin Van <firmianavan@gmail.com>
 */
contract Committee is SubCtrl{

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
    }

    IBase ib;

    mapping(address => uint) ranks;
    address[] public members; //根据当前得票数由大到小的顺序数组
    address[] public onTerm; //在任委员
    Option[] public options;//配置历史

    uint public fromHeight; //当前轮次起始高度
    uint public round=0;    //当前轮次


    //-----------------configuring---------------------------


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

    function setBonusAndPenalty(uint memberSalary, uint guaranty, uint minGuaranty, uint _round) public onlyAdmin{
        uint l = options.length;
        options.push(options[l-1]);
        options[l].memberSalary = memberSalary;
        options[l].guaranty = guaranty;
        options[l].minGuaranty = minGuaranty;
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
    constructor(address baseAddr) public {
        baseContract = baseAddr;
        ib = IBase(baseContract);
        fromHeight = block.number;
        options.push(Option({
            round : 0,
            roundSpan : 144000,
            withdrawRound : 72000,
            memberCnt : 9,
            memberSalary : 200 ether,
            guaranty : 5000 ether,
            minGuaranty : 2000 ether
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
                //发放奖励
                ib.award(members[i],getOption(round).memberSalary);
            }

            emit NewRoundEvent(onTerm, round);
        }
        _;
    }
    /// @dev 仅从member中移除（不参与记票）并更改其状态
    function removeFromCandidate(address addr) internal{
        if (ranks[addr] != 0){
            for (uint i = ranks[addr]; i<members.length; i++){
                members[i-1] = members[i];
            }
            members.length = members.length-1;
            ranks[addr] = 0;
        }
    }
    /// @dev 保证金不够时从members中移除
    modifier checkGuaranty(address candiAddr) {
        bool isEnough = (ib.memberBalanceOf(candiAddr)) >= getOption(round).minGuaranty;
        if (!isEnough){
            removeFromCandidate(candiAddr);
        }
        require(isEnough, "should provide enough guaranty"); 
        _;
    }
    
    /// @dev 不正常投票罚款时用到，如保证金不足，仅删除候选人资格，不可以抛异常
    function guarante(address member,uint left) external {
        require(msg.sender == baseContract);
        if (left < getOption(round).minGuaranty){
            removeFromCandidate(member);
        }
    }
    /// 候选人须保证充足的保证金，补充保证金也可调用此方法
    function guaranteeForCandidate() public payable whenNotPaused{
        require(msg.value + ib.memberBalanceOf(msg.sender) >= getOption(round).guaranty, "should provide enough guaranty");

        if (ranks[msg.sender] == 0){ //rank为0意味着未注册或已注销
            members.push(msg.sender);
            ranks[msg.sender] = members.length;
            onChangeWeight(msg.sender);//针对已注销用户重新注册，保留的weight仍可用
        }
        ib.memberDeposit.value(msg.value)(msg.sender);
    }
    /// @dev 理事会成员注销
    function unregister() public  whenNotPaused{
        removeFromCandidate(msg.sender);
        uint val = ib.memberBalanceOf(msg.sender);
        ib.memberWithdraw(msg.sender,val);
    }
    /// @dev 理事会提取奖励等，需保证提现后guaranty大于起始的guaranty
    function candidateWithdraw(uint val) public whenNotPaused {
        require(ib.memberBalanceOf(msg.sender) >= val + getOption(round).guaranty, "should have enough guaranty after withdraw");
        ib.memberWithdraw(msg.sender,val);
    }
    /// @dev withdraw all(ie. total - guaranty)
    function candidateWithdrawAll() public whenNotPaused {
        uint bal = ib.memberBalanceOf(msg.sender);
        require(bal >= getOption(round).guaranty, "should have enough guaranty after withdraw");
        ib.memberWithdraw(msg.sender, bal-getOption(round).guaranty);
    }

    /// @dev 排序前置 保证members始终是有序的. (插入排序)
    /// 原因是希望solidy不存在一种后台调度系统定时发放发放轮次奖励，而若将轮次结算放到每次vote，getMember动作中，仍会面临整个轮次中没有任何vote或getMeber动作， 是被动的有member发起，
    function onChangeWeight(address mem) internal checkRound{

        uint r = ranks[mem]-1; //members中的索引
        if ( r>0 && ib.getVoteSum(members[r-1]) < ib.getVoteSum(mem)){ //weight 增加，向前遍历
            for (uint i = r; i>0; i--){
                if (ib.getVoteSum(members[i-1]) < ib.getVoteSum(members[i])){
                    ranks[members[i]]--;
                    ranks[members[i-1]]++;
                    address t = members[i];
                    members[i] = members[i-1];
                    members[i-1] = t;
                    assert(ranks[members[i]] == i+1 && ranks[members[i-1]] == i);
                }
            }
        }else if (r < members.length-1 && ib.getVoteSum(members[r+1]) > ib.getVoteSum(mem)){ //weight 减少， 向后遍历
            for (i = r; i < members.length-1; i++){
                if (ib.getVoteSum(members[i+1]) > ib.getVoteSum(members[i])){
                    ranks[members[i]]++;
                    ranks[members[i+1]]--;
                    t = members[i];
                    members[i] = members[i+1];
                    members[i+1] = t;
                    assert(ranks[members[i]] == i+1 && ranks[members[i+1]] == i+2);
                }
            }
        }
    }
    function vote(address candidateAddr) public payable whenNotPaused checkGuaranty(candidateAddr){
        ib.voterDeposit.value(msg.value)(msg.sender);
        uint ori = ib.getVote(msg.sender,candidateAddr);
        ib.setVote(msg.sender,candidateAddr,ori+msg.value);
        onChangeWeight(candidateAddr);        

        emit VoteEvent(msg.sender,candidateAddr,msg.value,round);
    }
    function revote(address from, address to, uint value) whenNotPaused public checkGuaranty(to){
        uint fv = ib.getVote(msg.sender, from);
        require(fv >= value, "you do not have enough votes");

        ib.setVote(msg.sender,from,fv-value);
        onChangeWeight(from);
        emit UnvoteEvent(msg.sender,from,value,round);

        ib.setVote(msg.sender,to,fv+value);
        onChangeWeight(to);
        emit VoteEvent(msg.sender,to,value,round);

    }

    function voterWithdraw(address from, uint value) whenNotPaused public {
        uint fv = ib.getVote(msg.sender, from);
        require(fv >= value, "you do not have enough votes");
        require(block.number - fromHeight >= getOption(round).withdrawRound, "your funds is still locked now");
        ib.setVote(msg.sender, from, fv-value);
        ib.voterWithdraw(msg.sender,value);

        onChangeWeight(from);
        emit UnvoteEvent(msg.sender,from,value,round);
    }


    ///获取投票人对某个candidate的投票数
    function getVoterVotes(address voter, address candidate) public view returns (uint) {
        return ib.getVote(voter, candidate);
    }
    ///获取某个candidate的总得票数
    function getCandidateVotes(address candidate) public view returns (uint) {
        return ib.getVoteSum(candidate);
    }
    function getMembers() public  checkRound returns (address[] ret) {
        ret = new address[](getOption(round).memberCnt);
        for (uint i = 0; i < onTerm.length; i++){
            ret[i] = onTerm[i];
        }
        return ret;
    }

}