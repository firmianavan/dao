pragma solidity 0.4.24;

/// @title accesss control module.
/// @author Lin Van (firmianavan@gmail.com)
/// @dev modified from crypotKitties.
contract AccessCtrl {

    //the highest level
    address public ceoAddress;

    address public committeeAddr;
    address public ballotAddr;

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public adminA;
    address public adminB;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyAdmin() {
        require(
            msg.sender == adminA ||
            msg.sender == adminB
        );
        _;
    }

   /// @dev Access modifier for call only from sub-contract
    modifier fromSub() {
        require(msg.sender == ballotAddr || msg.sender == committeeAddr);
        _;
    }

    function setCommitteeAddr(address newCommitteeAddr) public onlyCEO{
        require(newCommitteeAddr != address(0));
        require(adminA != address(0) && adminB != address(0));
        committeeAddr = newCommitteeAddr;
        SubCtrl(committeeAddr).setAdminA(adminA);
        SubCtrl(committeeAddr).setAdminB(adminB);
    }
    function setBallotAddr(address newBallotAddr) public onlyCEO{
        require(newBallotAddr != address(0));
        require(adminA != address(0) && adminB != address(0));
        ballotAddr = newBallotAddr;
        SubCtrl(ballotAddr).setAdminA(adminA);
        SubCtrl(ballotAddr).setAdminB(adminB);
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the adminA. Only available to the current CEO.
    /// @param _adminA The address of the new _adminA
    function setAdminA(address _adminA) public onlyCEO {
        require(_adminA != address(0));

        adminA = _adminA;
        SubCtrl(ballotAddr).setAdminA(adminA);
        SubCtrl(committeeAddr).setAdminA(adminA);
    }

    /// @dev Assigns a new address to act as the adminB. Only available to the current CEO.
    /// @param _adminB The address of the new adminB
    function setAdminB(address _adminB) public onlyCEO {
        require(_adminB != address(0));

        adminB = _adminB;
        SubCtrl(ballotAddr).setAdminB(adminB);
        SubCtrl(committeeAddr).setAdminB(adminB);
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any admin role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() public onlyAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyAdmin whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

contract SubCtrl {


    address public baseContract;

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public adminA;
    address public adminB;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;


    /// @dev Access modifier for CEO-only functionality
    modifier onlyBase() {
        require(msg.sender == baseContract);
        _;
    }
    modifier onlyAdmin() {
        require(
            msg.sender == adminA ||
            msg.sender == adminB
        );
        _;
    }


    /// @dev Assigns a new address to act as the adminA. Only available to the current CEO.
    /// @param _adminA The address of the new _adminA
    function setAdminA(address _adminA) public onlyBase {
        require(_adminA != address(0));

        adminA = _adminA;
    }

    /// @dev Assigns a new address to act as the adminB. Only available to the current CEO.
    /// @param _adminB The address of the new adminB
    function setAdminB(address _adminB) public onlyBase {
        require(_adminB != address(0));

        adminB = _adminB;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any admin role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() public onlyAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyAdmin whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}