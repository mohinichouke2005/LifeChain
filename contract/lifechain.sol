// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LifeChain
 * @dev A decentralized platform for recording and verifying life events on the blockchain
 * @author LifeChain Development Team
 */
contract LifeChain {
    
    // Struct to represent a life event
    struct LifeEvent {
        uint256 id;
        address owner;
        string eventType;
        string description;
        uint256 timestamp;
        bool isVerified;
        address verifier;
        string ipfsHash; // For storing additional documents/media
    }
    
    // State variables
    uint256 private eventCounter;
    mapping(uint256 => LifeEvent) public lifeEvents;
    mapping(address => uint256[]) public userEvents;
    mapping(address => bool) public authorizedVerifiers;
    address public admin;
    
    // Events
    event EventRecorded(
        uint256 indexed eventId,
        address indexed owner,
        string eventType,
        uint256 timestamp
    );
    
    event EventVerified(
        uint256 indexed eventId,
        address indexed verifier,
        uint256 timestamp
    );
    
    event VerifierAdded(address indexed verifier, uint256 timestamp);
    event VerifierRemoved(address indexed verifier, uint256 timestamp);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Not an authorized verifier");
        _;
    }
    
    modifier onlyEventOwner(uint256 _eventId) {
        require(lifeEvents[_eventId].owner == msg.sender, "Not the event owner");
        _;
    }
    
    modifier eventExists(uint256 _eventId) {
        require(_eventId > 0 && _eventId <= eventCounter, "Event does not exist");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        eventCounter = 0;
        // Add admin as initial verifier
        authorizedVerifiers[admin] = true;
    }
    
    /**
     * @dev Core Function 1: Record a new life event
     * @param _eventType Type of life event (birth, education, marriage, etc.)
     * @param _description Detailed description of the event
     * @param _ipfsHash IPFS hash for additional documents
     */
    function recordLifeEvent(
        string memory _eventType,
        string memory _description,
        string memory _ipfsHash
    ) external returns (uint256) {
        require(bytes(_eventType).length > 0, "Event type cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        eventCounter++;
        
        LifeEvent storage newEvent = lifeEvents[eventCounter];
        newEvent.id = eventCounter;
        newEvent.owner = msg.sender;
        newEvent.eventType = _eventType;
        newEvent.description = _description;
        newEvent.timestamp = block.timestamp;
        newEvent.isVerified = false;
        newEvent.ipfsHash = _ipfsHash;
        
        userEvents[msg.sender].push(eventCounter);
        
        emit EventRecorded(eventCounter, msg.sender, _eventType, block.timestamp);
        
        return eventCounter;
    }
    
    /**
     * @dev Core Function 2: Verify a life event
     * @param _eventId ID of the event to verify
     */
    function verifyLifeEvent(uint256 _eventId) 
        external 
        onlyAuthorizedVerifier 
        eventExists(_eventId) 
    {
        LifeEvent storage eventToVerify = lifeEvents[_eventId];
        require(!eventToVerify.isVerified, "Event already verified");
        require(eventToVerify.owner != msg.sender, "Cannot verify your own event");
        
        eventToVerify.isVerified = true;
        eventToVerify.verifier = msg.sender;
        
        emit EventVerified(_eventId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Core Function 3: Get complete life timeline for a user
     * @param _user Address of the user
     * @return Array of event IDs belonging to the user
     */
    function getLifeTimeline(address _user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userEvents[_user];
    }
    
    /**
     * @dev Get detailed information about a specific life event
     * @param _eventId ID of the event
     * @return Complete LifeEvent struct data
     */
    function getLifeEvent(uint256 _eventId) 
        external 
        view 
        eventExists(_eventId) 
        returns (LifeEvent memory) 
    {
        return lifeEvents[_eventId];
    }
    
    /**
     * @dev Add a new authorized verifier (admin only)
     * @param _verifier Address to be added as verifier
     */
    function addVerifier(address _verifier) external onlyAdmin {
        require(_verifier != address(0), "Invalid verifier address");
        require(!authorizedVerifiers[_verifier], "Already a verifier");
        
        authorizedVerifiers[_verifier] = true;
        emit VerifierAdded(_verifier, block.timestamp);
    }
    
    /**
     * @dev Remove a verifier (admin only)
     * @param _verifier Address to be removed as verifier
     */
    function removeVerifier(address _verifier) external onlyAdmin {
        require(_verifier != admin, "Cannot remove admin as verifier");
        require(authorizedVerifiers[_verifier], "Not a verifier");
        
        authorizedVerifiers[_verifier] = false;
        emit VerifierRemoved(_verifier, block.timestamp);
    }
    
    /**
     * @dev Get total number of events recorded
     */
    function getTotalEvents() external view returns (uint256) {
        return eventCounter;
    }
    
    /**
     * @dev Check if an address is an authorized verifier
     */
    function isAuthorizedVerifier(address _address) external view returns (bool) {
        return authorizedVerifiers[_address];
    }
}
