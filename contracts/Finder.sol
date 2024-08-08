// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    enum AccountType {
        BUYER,
        SELLER
    }
    enum RequestLifecycle {
        PENDING,
        ACCEPTED_BY_SELLER,
        ACCEPTED_BY_BUYER,
        REQUEST_LOCKED,
        COMPLETED
    }

    struct Location {
        string state;
        string lga;
        string market;
    }

    struct Store {
        string name;
        string description;
        Location location;
    }

    struct User {
        string id;
        string username;
        string email;
        string phone;
        Location location;
        uint256 createdAt;
        AccountType accountType;
        Store[] stores;
    }

    struct Request {
        string id;
        string name;
        string buyerId;
        uint256 sellersPriceQuote;
        string[] sellerIds;
        string lockedSellerId;
        string description;
        string[] images;
        uint256 createdAt;
        RequestLifecycle lifecycle;
        string market;
        string lga;
        string state;
        uint256 updatedAt;
    }

    struct Offer {
        string id;
        uint256 price;
        string[] images;
        string requestId;
        string storeName;
        string sellerId;
        bool isAccepted;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // Custom errors with Marketplace__ prefix
    error Marketplace__OnlySellersAllowed();
    error Marketplace__OnlyBuyersAllowed();
    error Marketplace__OfferAlreadyAccepted();
    error Marketplace__InvalidAccountType();

    mapping(address => User) public users;
    mapping(string => Request) public requests;
    mapping(string => Offer) public offers;

    function createUser(
        string memory _id,
        string memory _username,
        string memory _email,
        string memory _phone,
        string memory _state,
        string memory _lga,
        string memory _market,
        AccountType _accountType
    ) public {
        if (
            _accountType != AccountType.BUYER &&
            _accountType != AccountType.SELLER
        ) {
            revert Marketplace__InvalidAccountType();
        }

        Location memory userLocation = Location(_state, _lga, _market);
        User memory newUser = User(
            _id,
            _username,
            _email,
            _phone,
            userLocation,
            block.timestamp,
            _accountType,
            new Store[]()
        );
        users[msg.sender] = newUser;
    }

    function createStore(
        string memory _name,
        string memory _description,
        string memory _state,
        string memory _lga,
        string memory _market
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        Location memory storeLocation = Location(_state, _lga, _market);
        Store memory newStore = Store(_name, _description, storeLocation);
        users[msg.sender].stores.push(newStore);
    }

    function createRequest(
        string memory _id,
        string memory _name,
        string memory _buyerId,
        string memory _description,
        string[] memory _images,
        string memory _market,
        string memory _lga,
        string memory _state
    ) public {
        if (users[msg.sender].accountType != AccountType.BUYER) {
            revert Marketplace__OnlyBuyersAllowed();
        }

        Request memory newRequest = Request(
            _id,
            _name,
            _buyerId,
            0,
            new string,
            _description,
            _images,
            block.timestamp,
            RequestLifecycle.PENDING,
            _market,
            _lga,
            _state,
            block.timestamp
        );
        requests[_id] = newRequest;
    }

    function createOffer(
        string memory _id,
        uint256 _price,
        string[] memory _images,
        string memory _requestId,
        string memory _storeName,
        string memory _sellerId
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        Offer memory newOffer = Offer(
            _id,
            _price,
            _images,
            _requestId,
            _storeName,
            _sellerId,
            false,
            block.timestamp,
            block.timestamp
        );
        offers[_id] = newOffer;
    }

    function acceptOffer(string memory _offerId) public {
        Offer storage offer = offers[_offerId];
        if (offer.isAccepted) {
            revert Marketplace__OfferAlreadyAccepted();
        }

        offer.isAccepted = true;
        offer.updatedAt = block.timestamp;

        Request storage request = requests[offer.requestId];
        request.lockedSellerId = offer.sellerId;
        request.sellersPriceQuote = offer.price;
        request.lifecycle = RequestLifecycle.ACCEPTED_BY_SELLER;
        request.updatedAt = block.timestamp;
    }
}
