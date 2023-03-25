pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

contract payment {
    address payable Market;
    address owner;
    uint balance = 0;

    constructor() {
        // set the shoppieMarket address to the contract deployer address
        Market = payable(msg.sender);
    }

    // mapping to keep track of users and their payments
    mapping(address => uint) userAddressToPayments;
    // mapping to keep track of users to successful payments
    mapping(address => bool) userAddressToSentSuccess;
    // mapping to keep track of users and items purchased
    mapping(address => string) itemIdToUserAddress;

    // event to keep track of sales
    event buyAlert(string itemId, address buyer, bool sent, uint price);

    function pay(string memory itemId) public payable returns (bool) {
        // instantiate a bool, set the value to false
        bool sent = false;
        // require the payment to be greater than zero
        require(msg.value > 0, "Price cannot be zero");

        // store user payment in price variable
        uint price = msg.value;
        payable(Market).transfer(msg.value);
        // update bool
        sent = true;
        // update balance
        balance += msg.value;
        // update userAddressToPayments mapping
        userAddressToPayments[msg.sender] = price;
        // update userAddressToSentSuccess mapping
        userAddressToSentSuccess[msg.sender] = sent;
        // update itemIdToUserAddress mapping
        itemIdToUserAddress[msg.sender] = itemId;
        // emit buyAlert event
        emit buyAlert(itemId, msg.sender, sent, msg.value);
        // return boolean
        return sent;
    }

    // reveal mapping data
    function checkUserPayment(
        address _user,
        string memory _itemId
    ) public view returns (uint, bool, address) {
        // define user payment value
        // uint userPayment = userAddressToPayments[_user]._itemId;
        // define user item
        string memory userItem = itemIdToUserAddress[_user];
        require(
            keccak256(abi.encodePacked(userItem)) ==
                keccak256(abi.encodePacked(_itemId)),
            "Item not found"
        );
        require(
            userAddressToSentSuccess[_user],
            "User has not made any payment"
        );
        return (
            userAddressToPayments[_user],
            userAddressToSentSuccess[_user],
            _user
        );
    }
}
