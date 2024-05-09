// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Evoting {
    // a struct to represent a voter
    // vote and weight are declared one n' after so that we can couple them. This will affect the ethereum optimization[source: Cryptozombies]
    struct Voter {
        uint vote;
        uint weight;
        bool voted;
    }

    // a struct to represent a proposals.
    // Proposals are the things we are voting for
    // name is a byte, because of this you will need to convert between string and bytes before using
    struct Proposal {
        bytes32 name;
        uint voteCount;
    }
    
    // a public array to keep record of proposals
    Proposal[] public proposals;
    
    // a public hashmap to keep record of voters
    mapping(address => Voter) public voters;

    // address of the person who started the voting, chairwoman-chairman
    address public chairperson;

    // This constructor initializes chairperson variable and voters, proposals arrays-hashmaps
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;

        voters[chairperson].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        } 
    }

    // This function despite being a public function, is going to be used by the owner to give rights to people to vote
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only the Chairperson can give access to vote");
        // require that the voter hasn't voted yet
        require(!voters[voter].voted, "The voter has already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    // This function is public and can be used by anyone to vote, but of course if you are not eligible to vote it will raise an exception
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    // this function can be queried after the vote ends
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for(uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }
    // this function can be queried after the vote ends and it will return the name of the winning proposal
    function winningName() public view returns (bytes32 winningName_) {
        winningName_ = proposals[winningProposal()].name;
    }
}