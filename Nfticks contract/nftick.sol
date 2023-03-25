// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";


contract NFTick is ERC1155, ERC1155Supply, ERC1155Holder{
    // Owner of the contract
    address payable _owner;

    // Marketplace contract
    address payable MarketAddress;

    // total number of nftick events created on the platform
    uint256 public totalNoOfEvents;

    // NUMBER TO KEEP track of tokenIds
    uint256 tokenId;

    // listing price of Nfts on marketplace
    uint256 public listingPrice = 0.01 ether; // ether is actually because contract will be deployed on matic

    constructor() ERC1155("") {
        _owner = payable(msg.sender);
        MarketAddress = payable(address(this));
        totalNoOfEvents = 0;
        tokenId = 0;
    }
    // struct to store info of all nfticks with the same tokenName
    struct events {
        uint256 totalTokens;
        address payable creator;
        string data;
        uint256 tokenId;
        uint256 listPrice;
    }


    // an event to keep track of when an nftick is created
    event nftickCreated (
        uint256 indexed tokenCount,
        uint256 indexed tokenId,
        address creator,
        uint256 price,
        string indexed data
    );

    // MAPPING from tokenIds to tokenURIs
    mapping (uint256 => string ) public _tokenURIs;

    // mapping from tokenIds to nftick nftickCollection
    mapping(uint256 => events) public AllEventsCreated;

    // allow the owner of the marketplace to update the listing price
    function updateListingPrice(uint _listingPrice) private {
        require(_owner == msg.sender, "only contract owner can call this function");
        listingPrice = _listingPrice;
    }

    // get marketplace listingPrice
    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    // get balance of nfticks for user accounts
    function getBalance(address account, uint256 id) public view {
        balanceOf(account, id);
    }

    // get batch balance of nfticks for user accounts
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");


        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    // convert single numbers to singleton arrays
    function _aSSingletonArray(uint256 element)
    private
    pure
    returns(uint256[] memory){
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    // function to return tokenUri attached to a tokenID
    function uri(uint256 _tokenId) public override view returns (string memory) {
        return(_tokenURIs[_tokenId]);
    }

    // function to set tokenURi
    function _setTokenUri(uint256 _tokenId, string memory tokenURI) private {
        _tokenURIs[_tokenId] = tokenURI;
    }

    // Create event
    function createEvent(
        string memory _data,
        uint256 price,
        uint256 _totalTokens
        )
        public
        payable
    {

    // increase tokenId count
        tokenId ++;

        uint256[] memory ids = _aSSingletonArray(tokenId);
        uint256[] memory amounts = _aSSingletonArray(_totalTokens);
        bytes memory Data = bytes(_data);
    // make sure the event creator pays the full listing price before they run this function
    //    require(msg.value >= listingPrice, "please transfer the listingPrice");

    // operator, from, to, ids, amounts, data
        _beforeTokenTransfer(msg.sender, address(0), MarketAddress, ids, amounts, Data);
    // set token uri before minting
        _setTokenUri(tokenId, _data);
    // to, ids, amounts, data.
        _mintBatch(MarketAddress, ids, amounts, Data);
    // set approval for function caller: owner, operator, approved
        _setApprovalForAll(MarketAddress, msg.sender, true);// not too sure if I want to use this function
    // operator, from, to, id, value
        emit TransferBatch(msg.sender, address(0), MarketAddress,  ids, amounts);
    // operator, from, ids, values, data
        onERC1155BatchReceived(msg.sender, address(0), ids, amounts, Data);

    // update AllEventsCreated mapping
        AllEventsCreated[totalNoOfEvents] = events(
            _totalTokens,
            payable(msg.sender),
            _data,
            tokenId,
            price
        );

    // increment totalNoOfEvents
        totalNoOfEvents++;

    // emit nftickCreated event
        emit nftickCreated (
            _totalTokens,
            tokenId,
            msg.sender,
            price,
            _data
        );

    }

    // function to buy nfticks
    function buyNftick(
        uint256 _tokenId
        ) public payable returns(bool approved)
    {

    // get the price of each NFTick
        uint256 Price = AllEventsCreated[_tokenId].listPrice;
    // get the data of each nftick
        bytes memory Data = bytes(AllEventsCreated[_tokenId].data);
    // make sure the payment is equal to the price of the nftick
        require(msg.value >= Price, "Not enough funds for transaction");
    //transfer nftick to buyer.
        _safeTransferFrom(MarketAddress, msg.sender, _tokenId, 1, Data);
    // operator, from, to, id, value
        emit TransferSingle(MarketAddress, MarketAddress, msg.sender, _tokenId, 1);
    // operator, from, id, value, data
        onERC1155Received(MarketAddress, MarketAddress, _tokenId, 1, Data);

        return true;
    }

    // function to get all nftick events that have been created by function caller on the marketplace
    function fetchAllMyEvents() public view returns(events[] memory) {
        // variable to store the number of collections that have been created by function caller
        uint collectionCount = 0;
        // variable to store the current index of events in collection array
        uint currentIndex = 0;

        // a loop to get the number of events the function caller has created
        for(uint i = 0; i < totalNoOfEvents ; i++) {
            if(AllEventsCreated[i].creator == msg.sender) {
                collectionCount += 1;
           }
        }

        // a struck array to store each collection that has been created by function caller
        events[] memory collection = new events[](collectionCount);
        // loop to get all the events created by function caller and store them in collection array
        for(uint256 i = 0; i < totalNoOfEvents ; i++){
            if(AllEventsCreated[i].creator == msg.sender){
                uint256 currentId = i;
            // reference current collection
                events storage currentCollection = AllEventsCreated[currentId];
            // store collection in the array
                collection[currentIndex] = currentCollection;
            // increment item index
                currentIndex += 1;
            }
        }
        return collection;

    }

    // function to get all nftick Events that have been created
    function fetchAllEventsCreated() public view returns(events[] memory) {

        // variable to store the current index of events in collection array
        uint currentIndex = 0;
        // a struck array to store each collection that has been created
        events[] memory collection = new events[](totalNoOfEvents);
        // loop to get all the events created and store them in collection array
        for(uint i = 0; i < totalNoOfEvents ; i++){
            uint currentId = i;
            // reference current collection
            events storage currentCollection = AllEventsCreated[currentId];
            // store collection in the array
            collection[currentIndex] = currentCollection;
            // increment item index
            currentIndex += 1;

        }
        return collection;

    }

    // function to fetch all nfticks owned by the function caller
    function fetchAllMyNfticks() public view returns( uint256[] memory) {

        uint256[] memory userBalance = new uint256[](tokenId);

        for(uint i = 0; i <= tokenId; i++ ){
            uint currentId = i;
            userBalance[i] = balanceOf(msg.sender, currentId);
        }

        return userBalance;
    }

    function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC1155, ERC1155Receiver)
    returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {}

}