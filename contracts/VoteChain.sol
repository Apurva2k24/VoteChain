// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VoteChain
 * @dev A decentralized voting system smart contract
 * @author VoteChain Team
 */
contract VoteChain {
    
    // Struct to represent a candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        bool exists;
    }
    
    // Struct to represent a voting session
    struct VotingSession {
        string title;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        mapping(uint256 => Candidate) candidates;
        uint256 candidateCount;
        mapping(address => bool) hasVoted;
        uint256 totalVotes;
    }
    
    // State variables
    address public owner;
    uint256 public sessionCounter;
    mapping(uint256 => VotingSession) public votingSessions;
    mapping(address => bool) public authorizedVoters;
    
    // Events
    event VotingSessionCreated(uint256 indexed sessionId, string title);
    event CandidateAdded(uint256 indexed sessionId, uint256 candidateId, string name);
    event VoteCast(uint256 indexed sessionId, uint256 candidateId, address voter);
    event VoterAuthorized(address voter);
    event VotingSessionEnded(uint256 indexed sessionId);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVoter() {
        require(authorizedVoters[msg.sender], "You are not authorized to vote");
        _;
    }
    
    modifier validSession(uint256 _sessionId) {
        require(_sessionId < sessionCounter, "Invalid session ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        sessionCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new voting session
     * @param _title Title of the voting session
     * @param _duration Duration of voting in seconds
     */
    function createVotingSession(string memory _title, uint256 _duration) 
        public 
        onlyOwner 
        returns (uint256) 
    {
        require(_duration > 0, "Duration must be greater than 0");
        
        uint256 sessionId = sessionCounter;
        VotingSession storage newSession = votingSessions[sessionId];
        
        newSession.title = _title;
        newSession.startTime = block.timestamp;
        newSession.endTime = block.timestamp + _duration;
        newSession.isActive = true;
        newSession.candidateCount = 0;
        newSession.totalVotes = 0;
        
        sessionCounter++;
        
        emit VotingSessionCreated(sessionId, _title);
        return sessionId;
    }
    
    /**
     * @dev Core Function 2: Add candidate to a voting session
     * @param _sessionId ID of the voting session
     * @param _candidateName Name of the candidate
     */
    function addCandidate(uint256 _sessionId, string memory _candidateName) 
        public 
        onlyOwner 
        validSession(_sessionId) 
    {
        require(bytes(_candidateName).length > 0, "Candidate name cannot be empty");
        require(votingSessions[_sessionId].isActive, "Voting session is not active");
        
        VotingSession storage session = votingSessions[_sessionId];
        uint256 candidateId = session.candidateCount;
        
        session.candidates[candidateId] = Candidate({
            id: candidateId,
            name: _candidateName,
            voteCount: 0,
            exists: true
        });
        
        session.candidateCount++;
        
        emit CandidateAdded(_sessionId, candidateId, _candidateName);
    }
    
    /**
     * @dev Core Function 3: Cast vote for a candidate
     * @param _sessionId ID of the voting session
     * @param _candidateId ID of the candidate
     */
    function castVote(uint256 _sessionId, uint256 _candidateId) 
        public 
        onlyAuthorizedVoter 
        validSession(_sessionId) 
    {
        VotingSession storage session = votingSessions[_sessionId];
        
        require(session.isActive, "Voting session is not active");
        require(block.timestamp <= session.endTime, "Voting period has ended");
        require(!session.hasVoted[msg.sender], "You have already voted in this session");
        require(_candidateId < session.candidateCount, "Invalid candidate ID");
        require(session.candidates[_candidateId].exists, "Candidate does not exist");
        
        session.candidates[_candidateId].voteCount++;
        session.hasVoted[msg.sender] = true;
        session.totalVotes++;
        
        emit VoteCast(_sessionId, _candidateId, msg.sender);
    }
    
    /**
     * @dev Core Function 4: Authorize voter
     * @param _voter Address of the voter to authorize
     */
    function authorizeVoter(address _voter) 
        public 
        onlyOwner 
    {
        require(_voter != address(0), "Invalid voter address");
        require(!authorizedVoters[_voter], "Voter is already authorized");
        
        authorizedVoters[_voter] = true;
        emit VoterAuthorized(_voter);
    }
    
    /**
     * @dev Core Function 5: Get voting results for a session
     * @param _sessionId ID of the voting session
     * @return candidateNames Array of candidate names
     * @return voteCounts Array of vote counts corresponding to candidates
     * @return totalVotes Total number of votes cast
     */
    function getVotingResults(uint256 _sessionId) 
        public 
        view 
        validSession(_sessionId) 
        returns (string[] memory candidateNames, uint256[] memory voteCounts, uint256 totalVotes) 
    {
        VotingSession storage session = votingSessions[_sessionId];
        
        candidateNames = new string[](session.candidateCount);
        voteCounts = new uint256[](session.candidateCount);
        
        for (uint256 i = 0; i < session.candidateCount; i++) {
            candidateNames[i] = session.candidates[i].name;
            voteCounts[i] = session.candidates[i].voteCount;
        }
        
        return (candidateNames, voteCounts, session.totalVotes);
    }
    
    // Additional utility functions
    
    /**
     * @dev End a voting session manually
     * @param _sessionId ID of the voting session to end
     */
    function endVotingSession(uint256 _sessionId) 
        public 
        onlyOwner 
        validSession(_sessionId) 
    {
        require(votingSessions[_sessionId].isActive, "Session is already inactive");
        
        votingSessions[_sessionId].isActive = false;
        emit VotingSessionEnded(_sessionId);
    }
    
    /**
     * @dev Check if a voter has voted in a specific session
     * @param _sessionId ID of the voting session
     * @param _voter Address of the voter
     * @return bool Whether the voter has voted
     */
    function hasVotedInSession(uint256 _sessionId, address _voter) 
        public 
        view 
        validSession(_sessionId) 
        returns (bool) 
    {
        return votingSessions[_sessionId].hasVoted[_voter];
    }
    
    /**
     * @dev Get candidate details
     * @param _sessionId ID of the voting session
     * @param _candidateId ID of the candidate
     * @return name Candidate name
     * @return voteCount Number of votes received
     */
    function getCandidate(uint256 _sessionId, uint256 _candidateId) 
        public 
        view 
        validSession(_sessionId) 
        returns (string memory name, uint256 voteCount) 
    {
        require(_candidateId < votingSessions[_sessionId].candidateCount, "Invalid candidate ID");
        
        Candidate storage candidate = votingSessions[_sessionId].candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }
}
