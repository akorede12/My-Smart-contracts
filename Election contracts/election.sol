pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./voting.sol";

contract Election is Voting {
    // count of all elections
    uint public electionCount;

    // mapping to keep track of election count to election contract address
    mapping(uint => address) electionAddresses;

    function getElectionCount() public view returns (uint _electionCount) {
        return electionCount;
    }

    constructor() Voting("", msg.sender) {}

    // modify function to pass in an address to use as contract creator
    function createElection(
        string memory _electionName,
        address electionCreator
    ) public returns (address _electionAddress) {
        // create new instance of voting contract (an election)
        Voting newElection = new Voting(_electionName, electionCreator);
        // update electionAddresses mapping
        electionAddresses[electionCount] = address(newElection);
        electionCount++;
        _electionAddress = address(newElection);

        return _electionAddress;
    }

    function viewElectionAddress(
        uint _index
    ) public view returns (address _electionAddress) {
        return electionAddresses[_index];
    }

    function viewLastDeployedElection()
        public
        view
        returns (address _electionAddress)
    {
        return electionAddresses[electionCount - 1];
    }

    function allElections() public view returns (address[] memory) {
        // variable to keep track of dynamic array
        uint count = 0;

        for (uint i = 0; i < electionCount; i++) {
            count++;
        }

        address[] memory allElectionAddress = new address[](count);

        uint count2 = 0;

        for (uint i = 0; i < electionCount; i++) {
            address currentElection = electionAddresses[i];
            allElectionAddress[count2] = currentElection;
            count2++;
        }
        return allElectionAddress;
    }
}
