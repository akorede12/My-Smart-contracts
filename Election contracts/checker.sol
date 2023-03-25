pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

library checker {
    function isValidOption(
        string[] memory voteOptions,
        string memory option
    ) public pure {
        uint optionIndex;
        for (uint i = 0; i < voteOptions.length; i++) {
            if (
                keccak256(abi.encodePacked(voteOptions[i])) ==
                keccak256(abi.encodePacked(option))
            ) {
                optionIndex = i;
                break;
            }
        }
        require(
            keccak256(abi.encodePacked(voteOptions[optionIndex])) ==
                keccak256(abi.encodePacked(option)),
            "Option is not valid"
        );
    }

    function getOptionIndex(
        string[] memory voteOptions,
        string memory option
    ) public pure returns (uint8) {
        for (uint8 i = 0; i < voteOptions.length; i++) {
            if (
                keccak256(abi.encodePacked(voteOptions[i])) ==
                keccak256(abi.encodePacked(option))
            ) {
                return i;
            }
        }
        revert("Invalid vote option.");
    }
}
