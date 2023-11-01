pragma solidity ^0.8.20;

import "../.deps/npm/@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public status;
    uint public winningProposalId;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus,WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    constructor() Ownable(msg.sender) {
        status = WorkflowStatus.RegisteringVoters;
    }

    modifier onlyAtStatus(WorkflowStatus differentstatus) {
        require(status == differentstatus, "invalid workflow status");
        _; // the program continues to execute
    }

    function startProposalsRegistration() external onlyOwner onlyAtStatus(WorkflowStatus.RegisteringVoters) {
        require(msg.sender == owner(), "only the owner can stert proposals registration");
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }
    
    function endProposalsRegistration() external onlyOwner onlyAtStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession()
        external
        onlyOwner
        onlyAtStatus(WorkflowStatus.ProposalsRegistrationEnded)
    {
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession()
        external
        onlyOwner
        onlyAtStatus(WorkflowStatus.VotingSessionStarted)
    {
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    function tallyVotes()
        external
        onlyOwner
        onlyAtStatus(WorkflowStatus.VotingSessionEnded)
    {
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded,WorkflowStatus.VotesTallied);
        uint winningVoteCount = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
    }

    function registerVoter(address addressVoter) external onlyOwner onlyAtStatus(WorkflowStatus.RegisteringVoters) {
        require(!voters[addressVoter].isRegistered, "Voter is already registered");
        voters[addressVoter].isRegistered = true;
        emit VoterRegistered(addressVoter);
    }

    function submitProposal(string memory descriptionProposal) external onlyAtStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        proposals.push(Proposal({description: descriptionProposal, voteCount: 0}));
        emit ProposalRegistered(proposals.length - 1);
    }

    function vote(uint proposalId) external onlyAtStatus(WorkflowStatus.VotingSessionStarted) {
        require(proposalId < proposals.length, "Invalid proposal ID"); 
        require(voters[msg.sender].isRegistered, "Voter is not registered");
        require(!voters[msg.sender].hasVoted, "Voter has already voted");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;
        proposals[proposalId].voteCount++;
        emit Voted(msg.sender, proposalId);
    }

    function getWinner() public view onlyAtStatus(WorkflowStatus.VotesTallied) returns (uint){
        require(
            status == WorkflowStatus.VotesTallied,
            "Voting is not yet complete"
        );
        return winningProposalId;
    }
}