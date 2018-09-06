pragma solidity 0.4.24;

import "./AccessCtrl.sol";

///@dev main contract, maintains 2 sub-contracts and their results, funds of the committee 
contract Base is AccessCtrl {

    address[] public members;
    mapping(uint => bool) public ballotResult;
    mapping(address => uint) public balance;
    mapping(address => uint) public memberBalance;

    address public committeeAddr;
    address public ballotAddr;

    constructor () public{
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

    /// @dev Access modifier for call only from committee contract
    modifier fromCommittee() {
        require(msg.sender == committeeAddr);
        _;
    }
    /// @dev Access modifier for call only from ballot contract
    modifier fromBallot() {
        require(msg.sender == ballotAddr);
        _;
    }
    function () public payable {}


    //--------------------------------- committee related -----------------------------------------------
 
    //--------------voter funds operations--------------
    /// @dev used to retrieve funds of voter
    function withdraw(address voter, uint val) external fromCommittee{
        require(balance[voter] >= val);
        voter.transfer(val);
    }

    /// @dev used to receive fund for voting
    function lock(address voter) external payable{
        balance[voter] += msg.value;
    }

    //--------------member funds operations--------------
    function register(address memberAddr) external payable{
        memberBalance[memberAddr] += msg.value;
    }
    function unregister(address memberAddr) external{
        memberAddr.transfer(memberBalance[memberAddr]);
    }
    function withdrawMemberAccountUnit(address memberAddr, uint threshold) external fromCommittee{
        require(memberBalance[memberAddr] >= threshold);
        memberAddr.transfer(memberBalance[memberAddr] - threshold);
    }
    function award(address memberAddr, uint value) external{
        memberBalance[memberAddr] += value;
    }
    function penalize(address memberAddr, uint value) external{
        memberBalance[memberAddr] += value;
    }
    
    
    function setMembers(address[] _members) external fromCommittee{
        members = _members;
    }

    function getMembers() public view returns (address[] ret) {
        return members;
    }

    function isMember(address addr) external view returns (bool){
        for (uint i = 0; i < members.length; i++){
            if(addr == members[i]){
                return true;
            }
        }
        return false;
    }

    //--------------------------------- ballot related --------------------------------------------------
    function setBallotResult(uint ballotId, bool isAccepted) external fromBallot{
        ballotResult[ballotId] = isAccepted;
    }
}