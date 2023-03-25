pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./checker.sol";

contract Voting {
    // contract owner
    address public owner;

    // name of election
    string electionName;
    // address of election creator
    address electionCreator;

    // mapping of voter address
    mapping(address => bool) public voters;
    mapping(address => uint) public votes;
    string[] public voteOptions;

    // add an array to keep track of voters
    address[] public allowedVoters;

    // struct to order data getVotes function data
    struct voterAndVotes {
        address validVoter;
        uint votedFor;
    }

    // struct to order vote options and vote count for each count
    struct votesForVoteOptions {
        string voteOption;
        uint voteCount;
    }

    constructor(string memory _electionName, address electionCretor) {
        owner = msg.sender;
        electionName = _electionName;
        electionCreator = electionCretor;
    }

    modifier onlyOwnerOrSecondary() {
        require(
            msg.sender == owner || msg.sender == electionCreator,
            "Caller is not authorized."
        );
        _;
    }

    // events
    event newVote(address voter, string voteOption);

    event newVoterAdded(address[] voterAddress);

    event voterRemoved(address voterAddress);

    event addedVoteOption(string voteOption);

    // set details of elections
    function setElectionDetails(
        string memory _electionName
    ) public onlyOwnerOrSecondary returns (string memory, address) {
        electionName = _electionName;
        electionCreator = msg.sender;
        return (electionName, electionCreator);
    }

    // get election details
    function getElectionDetails() public view returns (string memory, address) {
        return (electionName, electionCreator);
    }

    // add new voters to the allowedVoters array
    function addAllowedVoter(address newVoter) internal onlyOwnerOrSecondary {
        allowedVoters.push(newVoter);
    }

    function registerVoter(
        address[] memory newVoter
    ) public onlyOwnerOrSecondary {
        // the person registering voters should be election creator not owner

        for (uint i = 0; i < newVoter.length; i++) {
            if (!voters[newVoter[i]]) {
                voters[newVoter[i]] = true;
                // add new voters to the array
                addAllowedVoter(newVoter[i]);
            }
        }

        emit newVoterAdded(newVoter);
    }

    function viewVoters() public view returns (address[] memory) {
        return (allowedVoters);
    }

    function unregisterVoter(address voter) public onlyOwnerOrSecondary {
        require(voters[voter]);
        voters[voter] = false;

        // delete voter from array
        for (uint i = 0; i < allowedVoters.length; i++) {
            if (allowedVoters[i] == voter) {
                allowedVoters[i] = allowedVoters[allowedVoters.length - 1];
                allowedVoters.pop();
            }
        }
        emit voterRemoved(voter);
    }

    function addVoteOption(string memory option) public {
        voteOptions.push(option);
        emit addedVoteOption(option);
    }

    // castVotes doesn't prevent multi voting.
    function castVote(string memory option) public {
        //voters[msg.sender] = false;
        require(voters[msg.sender], "voter is not registered.");
        require(votes[msg.sender] == 0, " Voter has already voted.");
        // use checker library to check if user option is valid
        checker.isValidOption(voteOptions, option);
        // get the index of the options in voteOptions array
        uint optionIndex = checker.getOptionIndex(voteOptions, option);
        // update votes mapping
        votes[msg.sender] = optionIndex + 1;
        // adding + 1 because it helps to solve the multiple votes bug.
        // users who vote for the first voteOptions can vote multiple times
        // until they choose a different option.
        emit newVote(msg.sender, option);
    }

    function getVotes() public view returns (voterAndVotes[] memory) {
        // uint variable to keep track of dynamic array
        uint voterVoteCount = 0;
        // for loop to iterate through the allowedVoters arrays,
        // for loop to chack if the users gotten from the allowedVoters have voted, with votes mapping
        for (uint i = 0; i < allowedVoters.length; i++) {
            // check
            if (voters[allowedVoters[i]] == true) {
                voterVoteCount++;
            }
        }
        //
        voterAndVotes[] memory voterVotesArray = new voterAndVotes[](
            voterVoteCount
        );

        //
        uint count = 0;

        // for loop to iterate through the allowedVoters arrays,
        // for loop to check if the users gotten from the allowedVoters have voted, with votes mapping
        for (uint i = 0; i < allowedVoters.length; i++) {
            // check
            if (voters[allowedVoters[i]] == true) {
                address currentVoter = allowedVoters[i];
                uint currentVote = votes[currentVoter];

                voterVotesArray[count] = voterAndVotes(
                    currentVoter,
                    currentVote
                );
                count++;
            }
        }
        return voterVotesArray;
    }

    function getVoteOptionVoteCount(
        string memory option
    ) public view returns (uint) {
        // use checker library to check if user option is valid
        checker.isValidOption(voteOptions, option);
        // get the index of the options in voteOptions array
        uint optionIndex = checker.getOptionIndex(voteOptions, option);
        // Add one to option index to prevent index from starting from 0
        optionIndex + 1;

        // variable to keep track of vote count
        uint voteCount = 0;

        // votes[msg.sender] = optionIndex + 1;
        // for loop to loop through allowedVoters array and votes mapping
        for (uint i = 0; i < allowedVoters.length; i++) {
            if (votes[allowedVoters[i]] == optionIndex + 1) {
                voteCount++;
            }
        }
        return voteCount;
    }

    function getElectionWinner() public view returns (string memory) {
        // struct array of votes and vote Options
        votesForVoteOptions[]
            memory votesForVoteOptionsArray = new votesForVoteOptions[](
                voteOptions.length
            ); //= new votesForVoteOptions[]

        // loop count
        uint count = 0;

        for (uint i = 0; i < voteOptions.length; i++) {
            string memory currentOption = voteOptions[i];
            uint optionVoteCount = getVoteOptionVoteCount(voteOptions[i]);
            votesForVoteOptionsArray[count] = votesForVoteOptions(
                currentOption,
                optionVoteCount
            );

            count++;
        }

        // Find the option with the highest vote count
        string memory winner = "";
        uint maxVotes = 0;
        bool isTie = false;
        for (uint i = 0; i < votesForVoteOptionsArray.length; i++) {
            if (votesForVoteOptionsArray[i].voteCount > maxVotes) {
                maxVotes = votesForVoteOptionsArray[i].voteCount;
                winner = votesForVoteOptionsArray[i].voteOption;
                isTie = false;
            } else if (votesForVoteOptionsArray[i].voteCount == maxVotes) {
                isTie = true;
            }
        }

        if (isTie) {
            return "Tie between top vote options";
        } else {
            return winner;
        }
    }
}
