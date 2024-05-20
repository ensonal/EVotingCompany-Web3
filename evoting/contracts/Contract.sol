// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Evoting {
    // Struct to represent a voter
    struct Voter {
        uint vote; // Index of the voted proposal
        uint weight; // Weight of the vote
        bool voted; // True if the voter has already voted
    }

    // Struct to represent a proposal
    struct Proposal {
        bytes32 name; // Short name of the proposal
        uint voteCount; // Number of accumulated votes
    }
    
    // Array of proposals
    Proposal[] public proposals;
    
    // Mapping to store voters' information
    mapping(address => Voter) public voters;

    // Address of the person who started the voting process (chairperson)
    address public chairperson;

    // Constructor to initialize the contract
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;

        voters[chairperson].weight = 1; // Chairperson starts with a weight of 1

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        } 
    }

    // Function to give the right to vote to a shareholder
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only the Chairperson can give access to vote");
        require(!voters[voter].voted, "The voter has already voted");
        require(voters[voter].weight == 0, "Voter's weight must be zero");
        
        // Set the voting weight based on the voter's shares (assumed to be 1 for simplicity)
        voters[voter].weight = 1; // In practice, set this to the number of shares the voter holds
    }

    // Function for shareholders to vote on a proposal
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");

        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    // Function to delegate vote to another voter
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You have already voted");
        require(sender.weight != 0, "You have no right to vote");

        Voter storage delegateTo = voters[to];
        require(!delegateTo.voted, "Delegatee has already voted");

        delegateTo.weight += sender.weight;
        sender.weight = 0;
    }

    // Function to get the index of the winning proposal
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    // Function to get the name of the winning proposal
    function winningName() public view returns (bytes32 winningName_) {
        winningName_ = proposals[winningProposal()].name;
    }
}
