// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    event UserCreated(
        address indexed userAddress,
        string userId,
        string username,
        uint8 accountType
    );
    event StoreCreated(
        address indexed sellerAddress,
        string storeName,
        uint256 latitude,
        uint256 longitude
    );
    event RequestCreated(
        string indexed requestId,
        address indexed buyerAddress,
        string requestName,
        uint256 latitude,
        uint256 longitude
    );
    event OfferCreated(
        string indexed offerId,
        address indexed sellerAddress,
        string storeName,
        uint256 price,
        string requestId
    );

    event RequestAccepted(
        string indexed requestId,
        string indexed offerId,
        address indexed sellerAddress
    );

    event OfferRemoved(string indexed offerId, address indexed sellerAddress);

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
        uint256 latitude;
        uint256 longitude;
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
        Location location;
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
    mapping(address => mapping(string => bool)) public buyerOffers; // Tracks offers created by each buyer for each request

    uint256 constant TIME_TO_LOCK = 900;

    function createUser(
        string memory _id,
        string memory _username,
        string memory _email,
        string memory _phone,
        uint256 _latitude,
        uint256 _longitude,
        AccountType _accountType
    ) public {
        if (
            _accountType != AccountType.BUYER &&
            _accountType != AccountType.SELLER
        ) {
            revert Marketplace__InvalidAccountType();
        }

        Location memory userLocation = Location(_latitude, _longitude);
        User memory newUser = User(
            _id,
            _username,
            _email,
            _phone,
            userLocation,
            block.timestamp,
            _accountType,
            new Store[](0)
        );
        users[msg.sender] = newUser;
        emit UserCreated(msg.sender, _id, _username, uint8(_accountType));
    }

    function createStore(
        string memory _name,
        string memory _description,
        uint256 _latitude,
        uint256 _longitude
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        Location memory storeLocation = Location(_latitude, _longitude);
        Store memory newStore = Store(_name, _description, storeLocation);
        users[msg.sender].stores.push(newStore);
        emit StoreCreated(msg.sender, _name, _latitude, _longitude);
    }

    function createRequest(
        string memory _id,
        string memory _name,
        string memory _buyerId,
        string memory _description,
        string[] memory _images,
        uint256 _latitude,
        uint256 _longitude
    ) public {
        if (users[msg.sender].accountType != AccountType.BUYER) {
            revert Marketplace__OnlyBuyersAllowed();
        }

        Location memory requestLocation = Location(_latitude, _longitude);
        Request memory newRequest = Request(
            _id,
            _name,
            _buyerId,
            0,
            new string[](0),
            "",
            _description,
            _images,
            block.timestamp,
            RequestLifecycle.PENDING,
            requestLocation,
            block.timestamp
        );
        requests[_id] = newRequest;
        emit RequestCreated(_id, msg.sender, _name, _latitude, _longitude);
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

        if (buyerOffers[msg.sender][_requestId]) {
            revert Marketplace__OfferAlreadyExists();
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
        buyerOffers[msg.sender][_requestId] = true; // Mark that the buyer has created an offer for this request

        emit OfferCreated(_id, msg.sender, _storeName, _price, _requestId);
    }

    function acceptOffer(string memory _offerId) public {
        Offer memory offer = offers[_offerId];
        if (offer.isAccepted) {
            revert Marketplace__OfferAlreadyAccepted();
        }

        Request memory request = requests[offer.requestId];
        for (int i = 0; i < request.sellerIds.length; i++) {
            string memory previousSellerId = request.sellerIds[i];
            Offer storage previousOffer = offers[previousSellerId];
            previousOffer.isAccepted = false;
        }

        offer.isAccepted = true;
        offer.updatedAt = block.timestamp;
        request.sellerIds.push(offer.sellerId);
        request.lockedSellerId = offer.sellerId;
        request.sellersPriceQuote = offer.price;
        request.lifecycle = RequestLifecycle.ACCEPTED_BY_SELLER;
        request.updatedAt = block.timestamp;
        emit RequestAccepted(request.id, offer.id, offer.sellerId);
    }

    function removeOffer(string memory _offerId) public {
        Offer storage offer = offers[_offerId];

        // Check if the sender is the seller who created the offer
        if (
            keccak256(abi.encodePacked(offer.sellerId)) !=
            keccak256(abi.encodePacked(users[msg.sender].id))
        ) {
            revert Marketplace__UnauthorizedRemoval();
        }

        if (block.timestamp > offer.updatedAt + TIME_TO_LOCK) {
            revert Marketplace__OfferNotRemovable();
        }

        // Delete the offer
        delete offers[_offerId];
        buyerOffers[msg.sender][offer.requestId] = false; // Allow buyer to create another offer for the same request

        // Emit the event
        emit OfferRemoved(_offerId, msg.sender);
    }
}
