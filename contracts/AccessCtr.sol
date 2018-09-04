/// @title accesss control module.
/// @author Lin Van (firmianavan@gmail.com)
/// @dev modified from crypotKitties.
contract AccessCtl {

    //the highest level
    address public ceoAddress;

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

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the adminA. Only available to the current CEO.
    /// @param _adminA The address of the new _adminA
    function setAdminA(address _adminA) external onlyCEO {
        require(_adminA != address(0));

        adminA = _adminA;
    }

    /// @dev Assigns a new address to act as the adminB. Only available to the current CEO.
    /// @param _adminB The address of the new adminB
    function setAdminB(address _adminB) external onlyCEO {
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
    function pause() external onlyAdmin whenNotPaused {
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