// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

interface IHederaTokenService {
    function associateToken(
        address account,
        address token
    ) external returns (int64);
}

contract Marketplace {
    event UserCreated(
        address indexed userAddress,
        uint256 userId,
        string username,
        uint8 accountType
    );
    event UserUpdated(
        address indexed userAddress,
        uint256 userId,
        string username,
        uint8 accountType
    );
    event StoreCreated(
        address indexed sellerAddress,
        uint256 storeId,
        string storeName,
        int256 latitude,
        int256 longitude
    );

    event OfferAccepted(
        uint256 indexed offerId,
        address indexed buyerAddress,
        bool isAccepted
    );
    event RequestCreated(
        uint256 indexed requestId,
        address indexed buyerAddress,
        string requestName,
        int256 latitude,
        int256 longitude,
        string[] images,
        uint8 lifecycle,
        string description,
        uint256 buyerId,
        uint256[] sellerIds,
        int256 sellersPriceQuote,
        uint256 lockedSellerId,
        uint256 createdAt,
        uint256 updatedAt
    );

    event RequestDeleted(uint256 indexed requestId);

    event RequestMarkedAsCompleted(uint256 indexed requestId);

    event OfferCreated(
        uint256 indexed offerId,
        address indexed sellerAddress,
        string storeName,
        uint256 price,
        uint256 requestId,
        string[] images,
        uint256 sellerId,
        uint256[] sellerIds
    );

    event RequestAccepted(
        uint256 indexed requestId,
        uint256 indexed offerId,
        uint256 indexed sellerId,
        uint256 updatedAt,
        uint256 sellersPriceQuote
    );
    event RequestPaymentTransacted(
        uint256 timestamp,
        uint256 amount,
        uint8 token,
        uint256 requestId,
        uint256 sellerId,
        uint256 buyerId,
        uint256 createdAt,
        uint256 updatedAt
    );

    event OfferRemoved(uint256 indexed offerId, address indexed sellerAddress);

    event AssociationSuccessful(
        address indexed contractAddress,
        address indexed tokenAddress,
        int64 result
    );

    enum AccountType {
        BUYER,
        SELLER
    }

    enum CoinPayment {
        ETH,
        USDC
    }
    enum RequestLifecycle {
        PENDING,
        ACCEPTED_BY_SELLER,
        ACCEPTED_BY_BUYER,
        REQUEST_LOCKED,
        PAID,
        COMPLETED
    }

    struct Location {
        int256 latitude;
        int256 longitude;
    }

    struct Store {
        uint256 id;
        string name;
        string description;
        string phone;
        Location location;
    }

    struct PaymentInfo {
        address authority;
        uint256 requestId;
        address buyer;
        address seller;
        uint256 amount;
        CoinPayment token;
        uint256 createdAt;
        uint256 updatedAt;
    }

    mapping(address => mapping(uint256 => Store)) public userStores;
    mapping(address => uint256[]) public userStoreIds;

    struct User {
        uint256 id;
        string username;
        string phone;
        Location location;
        uint256 createdAt;
        uint256 updatedAt;
        AccountType accountType;
        bool location_enabled;
        address authority;
    }

    struct Request {
        uint256 id;
        string name;
        uint256 buyerId;
        uint256 sellersPriceQuote;
        uint256[] sellerIds;
        uint256[] offerIds;
        uint256 lockedSellerId;
        string description;
        string[] images;
        uint256 createdAt;
        RequestLifecycle lifecycle;
        Location location;
        uint256 updatedAt;
        bool paid;
        uint256 acceptedOfferId;
    }

    struct Offer {
        uint256 id;
        uint256 price;
        string[] images;
        uint256 requestId;
        string storeName;
        uint256 sellerId;
        bool isAccepted;
        uint256 createdAt;
        uint256 updatedAt;
        address authority;
    }

    // Custom errors with Marketplace__ prefix
    error Marketplace__OnlySellersAllowed();
    error Marketplace__UnauthorizedBuyer();
    error Marketplace__OnlyBuyersAllowed();
    error Marketplace__UnSupportedChainId();
    error Marketplace__OfferAlreadyAccepted();
    error Marketplace__InvalidAccountType();
    error Marketplace__OfferAlreadyExists();
    error Marketplace__UnauthorizedRemoval();
    error Marketplace__RequestNotAccepted();
    error Marketplace__RequestAlreadyPaid();
    error Marketplace__InsufficientAllowance();
    error Marketplace__RequestNotLocked();
    error Marketplace__RequestNotPaid();
    error Marketplace__InsufficientFunds();
    error Marketplace__OfferNotRemovable();
    error Marketplace__IndexOutOfBounds();
    error Marketplace__RequestLocked();
    error Marketplace_InvalidUser();
    error Marketplace_UserAlreadyExists();
    error Marketplace__TokenAssociationFailed();
    error Marketplace__PriceCannotBeZero();
    error Marketplace__UnknownPaymentType();
    error Marketplace__StoreNeededToCreateOffer();

    mapping(address => User) public users;
    mapping(uint256 => User) public usersById;
    mapping(uint256 => Request) public requests;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => PaymentInfo) public requestPaymentInfo;

    uint256 private _userCounter;
    uint256 private _storeCounter;
    uint256 private _requestCounter;
    uint256 private _offerCounter;
    mapping(address => uint256) public balanceOfETH;
    mapping(address => uint256) public balanceOfUSDC;

    uint256 constant TIME_TO_LOCK = 60;
    address constant USDC_ADDR =
        address(0x0000000000000000000000000000000000068cDa);

    IHederaTokenService private hederaTokenService =
        IHederaTokenService(address(0x167));

    AggregatorV3Interface constant HBAR_USD_PRICE_FEED =
        AggregatorV3Interface(0x59bC155EB6c6C415fE43255aF66EcF0523c92B4a);

    function associateToken(address tokenAddress) public {
        int64 result = hederaTokenService.associateToken(
            address(this),
            tokenAddress
        );

        if (result != 22) {
            revert Marketplace__TokenAssociationFailed();
        }

        emit AssociationSuccessful(address(this), tokenAddress, result);
    }

    function createUser(
        string memory _username,
        string memory _phone,
        int256 _latitude,
        int256 _longitude,
        AccountType _accountType
    ) public {
        User storage user = users[msg.sender];
        if (user.id != 0) {
            revert Marketplace_UserAlreadyExists();
        }

        if (
            _accountType != AccountType.BUYER &&
            _accountType != AccountType.SELLER
        ) {
            revert Marketplace__InvalidAccountType();
        }

        Location memory userLocation = Location(_latitude, _longitude);

        _userCounter++;
        uint256 userId = _userCounter;

        users[msg.sender] = User(
            userId,
            _username,
            _phone,
            userLocation,
            block.timestamp,
            block.timestamp,
            _accountType,
            true,
            msg.sender
        );
        usersById[userId] = users[msg.sender];

        emit UserCreated(msg.sender, userId, _username, uint8(_accountType));
    }

    function updateUser(
        string memory _username,
        string memory _phone,
        int256 _latitude,
        int256 _longitude,
        AccountType _accountType
    ) public {
        User storage user = users[msg.sender];

        if (user.id == 0) {
            revert Marketplace_InvalidUser();
        }

        // Update user information
        user.username = _username;
        user.phone = _phone;
        user.location = Location(_latitude, _longitude);
        user.updatedAt = block.timestamp;
        user.accountType = _accountType;

        usersById[user.id] = user;

        emit UserUpdated(
            msg.sender,
            user.id,
            _username,
            uint8(user.accountType)
        );
    }

    function createStore(
        string memory _name,
        string memory _description,
        string memory _phone,
        int256 _latitude,
        int256 _longitude
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        Location memory storeLocation = Location(_latitude, _longitude);

        _storeCounter++;
        uint256 storeId = _storeCounter;

        Store memory newStore = Store(
            storeId,
            _name,
            _description,
            _phone,
            storeLocation
        );
        userStores[msg.sender][storeId] = newStore;
        userStoreIds[msg.sender].push(storeId);
        emit StoreCreated(msg.sender, storeId, _name, _latitude, _longitude);
    }

    function createRequest(
        string memory _name,
        string memory _description,
        string[] memory _images,
        int256 _latitude,
        int256 _longitude
    ) public {
        if (users[msg.sender].accountType != AccountType.BUYER) {
            revert Marketplace__OnlyBuyersAllowed();
        }

        Location memory requestLocation = Location(_latitude, _longitude);

        _requestCounter++;
        uint256 requestId = _requestCounter;

        Request memory newRequest = Request(
            requestId,
            _name,
            users[msg.sender].id,
            0,
            new uint256[](0),
            new uint256[](0),
            0,
            _description,
            _images,
            block.timestamp,
            RequestLifecycle.PENDING,
            requestLocation,
            block.timestamp,
            false,
            0
        );

        requests[requestId] = newRequest;
        emit RequestCreated(
            requestId,
            msg.sender,
            _name,
            _latitude,
            _longitude,
            _images,
            uint8(RequestLifecycle.PENDING),
            _description,
            users[msg.sender].id,
            new uint256[](0),
            0,
            0,
            block.timestamp,
            block.timestamp
        );
    }

    function deleteRequest(uint256 _requestId) public {
        Request storage request = requests[_requestId];

        if (request.buyerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedRemoval();
        }

        if (request.lifecycle != RequestLifecycle.PENDING) {
            revert Marketplace__RequestLocked();
        }

        delete requests[_requestId];

        emit RequestDeleted(_requestId);
    }

    function markRequestAsCompleted(uint256 _requestId) public {
        Request storage request = requests[_requestId];

        if (request.buyerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedRemoval();
        }

        if (request.lifecycle != RequestLifecycle.PAID) {
            revert Marketplace__RequestNotPaid();
        }

        if (request.updatedAt + TIME_TO_LOCK > block.timestamp) {
            revert Marketplace__RequestNotLocked();
        }

        request.lifecycle = RequestLifecycle.COMPLETED;
        request.updatedAt = block.timestamp;

        // transfer funds to seller
        PaymentInfo storage paymentInfo = requestPaymentInfo[_requestId];

        if (paymentInfo.amount > 0) {
            if (paymentInfo.token == CoinPayment.USDC) {
                balanceOfUSDC[paymentInfo.seller] += paymentInfo.amount;
            } else if (paymentInfo.token == CoinPayment.ETH) {
                balanceOfETH[paymentInfo.seller] += paymentInfo.amount;
            } else {
                revert Marketplace__UnknownPaymentType();
            }
        }

        emit RequestMarkedAsCompleted(_requestId);
    }

    function withdrawSellerProfit(CoinPayment coin) public {
        if (coin == CoinPayment.ETH) {
            uint256 amount = balanceOfETH[msg.sender];
            if (amount == 0) {
                revert Marketplace__InsufficientFunds();
            }
            balanceOfETH[msg.sender] = 0;
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
            if (!sent) {
                revert Marketplace__InsufficientFunds();
            }
        } else if (coin == CoinPayment.USDC) {
            uint256 amount = balanceOfUSDC[msg.sender];
            if (amount == 0) {
                revert Marketplace__InsufficientFunds();
            }
            balanceOfUSDC[msg.sender] = 0;
            IERC20 usdc = IERC20(USDC_ADDR);
            if (!usdc.transfer(msg.sender, amount)) {
                revert Marketplace__InsufficientFunds();
            }
        } else {
            revert Marketplace__UnknownPaymentType();
        }
    }

    function getConversionRate(
        uint256 requestId,
        CoinPayment coin
    ) public view returns (uint256) {
        Request storage request = requests[requestId];
        Offer storage offer = offers[request.acceptedOfferId];

        if (coin == CoinPayment.USDC) {
            (, int256 price, , , ) = HBAR_USD_PRICE_FEED.latestRoundData();
            uint256 usdcAmount = (offer.price * uint256(price)) / 1e10;
            return usdcAmount;
        } else {
            revert Marketplace__UnknownPaymentType();
        }
    }

    function payForRequestToken(
        uint256 requestId,
        CoinPayment coin
    ) external payable {
        Request storage request = requests[requestId];
        Offer storage offer = offers[request.acceptedOfferId];

        if (request.paid) {
            revert Marketplace__RequestAlreadyPaid();
        }
        if (request.buyerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedBuyer();
        }

        if (request.lifecycle != RequestLifecycle.ACCEPTED_BY_BUYER) {
            revert Marketplace__RequestNotAccepted();
        }

        if (request.updatedAt + TIME_TO_LOCK > block.timestamp) {
            revert Marketplace__RequestNotLocked();
        }

        if (!offer.isAccepted) {
            revert Marketplace__RequestNotAccepted();
        }

        request.paid = true;
        request.lifecycle = RequestLifecycle.PAID;

        PaymentInfo memory newPaymentInfo = PaymentInfo(
            msg.sender,
            requestId,
            msg.sender,
            offer.authority,
            0,
            coin,
            block.timestamp,
            block.timestamp
        );

        if (coin == CoinPayment.USDC) {
            (, int256 price, , , ) = HBAR_USD_PRICE_FEED.latestRoundData();
            uint256 usdcAmount = (offer.price * uint256(price)) / 1e10;

            IERC20 usdcErc20 = IERC20(USDC_ADDR);
            uint256 allowance = usdcErc20.allowance(msg.sender, address(this));
            uint256 slippageToleranceBps = 200; // 200 basis points = 2%

            uint256 minUsdcAmount = (usdcAmount *
                (10000 - slippageToleranceBps)) / 10000;
            uint256 maxUsdcAmount = (usdcAmount *
                (10000 + slippageToleranceBps)) / 10000;

            uint256 transferAmount = 0;
            if (allowance >= minUsdcAmount && allowance <= maxUsdcAmount) {
                transferAmount = allowance;
            } else if (allowance >= usdcAmount) {
                transferAmount = usdcAmount;
            } else {
                revert Marketplace__InsufficientAllowance();
            }

            newPaymentInfo.amount = transferAmount;

            if (
                !usdcErc20.transferFrom(
                    msg.sender,
                    address(this),
                    transferAmount
                )
            ) {
                revert Marketplace__InsufficientFunds();
            }
        } else {
            revert Marketplace__UnknownPaymentType();
        }
        requestPaymentInfo[requestId] = newPaymentInfo;

        emit RequestPaymentTransacted(
            block.timestamp,
            newPaymentInfo.amount,
            uint8(coin),
            requestId,
            users[offer.authority].id,
            users[msg.sender].id,
            block.timestamp,
            block.timestamp
        );
    }

    function payForRequest(
        uint256 requestId,
        CoinPayment coin
    ) external payable {
        Request storage request = requests[requestId];
        Offer storage offer = offers[request.acceptedOfferId];

        if (request.paid) {
            revert Marketplace__RequestAlreadyPaid();
        }

        if (request.buyerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedBuyer();
        }

        if (request.lifecycle != RequestLifecycle.ACCEPTED_BY_BUYER) {
            revert Marketplace__RequestNotAccepted();
        }

        if (request.updatedAt + TIME_TO_LOCK > block.timestamp) {
            revert Marketplace__RequestNotLocked();
        }

        if (!offer.isAccepted) {
            revert Marketplace__RequestNotAccepted();
        }

        request.paid = true;
        request.lifecycle = RequestLifecycle.PAID;

        PaymentInfo memory newPaymentInfo = PaymentInfo(
            msg.sender,
            requestId,
            msg.sender,
            offer.authority,
            0,
            coin,
            block.timestamp,
            block.timestamp
        );

        if (coin == CoinPayment.ETH) {
            if (msg.value < offer.price) {
                revert Marketplace__InsufficientFunds();
            }
            newPaymentInfo.amount = offer.price;
        } else {
            revert Marketplace__UnknownPaymentType();
        }
        requestPaymentInfo[requestId] = newPaymentInfo;

        emit RequestPaymentTransacted(
            block.timestamp,
            newPaymentInfo.amount,
            uint8(coin),
            requestId,
            users[offer.authority].id,
            users[msg.sender].id,
            block.timestamp,
            block.timestamp
        );
    }

    function toggleLocation(bool enabled) public {
        users[msg.sender].location_enabled = enabled;
    }

    function getLocationPreference() public view returns (bool) {
        return users[msg.sender].location_enabled;
    }

    function createOffer(
        uint256 _price,
        string[] memory _images,
        uint256 _requestId,
        string memory _storeName
    ) public {
        if (users[msg.sender].accountType != AccountType.SELLER) {
            revert Marketplace__OnlySellersAllowed();
        }

        if (_price == 0) {
            revert Marketplace__PriceCannotBeZero();
        }

        if (userStoreCount(msg.sender) == 0) {
            revert Marketplace__StoreNeededToCreateOffer();
        }

        Request storage request = requests[_requestId];

        if (
            block.timestamp > request.updatedAt + TIME_TO_LOCK &&
            request.lifecycle == RequestLifecycle.ACCEPTED_BY_BUYER
        ) {
            revert Marketplace__RequestLocked();
        }

        _offerCounter++;
        uint256 offerId = _offerCounter;

        Offer memory newOffer = Offer(
            offerId,
            _price,
            _images,
            _requestId,
            _storeName,
            users[msg.sender].id,
            false,
            block.timestamp,
            block.timestamp,
            msg.sender
        );
        offers[offerId] = newOffer;
        request.sellerIds.push(newOffer.sellerId);

        if (request.lifecycle == RequestLifecycle.PENDING) {
            request.lifecycle = RequestLifecycle.ACCEPTED_BY_SELLER;
        }

        emit OfferCreated(
            offerId,
            msg.sender,
            _storeName,
            _price,
            _requestId,
            _images,
            users[msg.sender].id,
            request.sellerIds
        );
        // mapping(address => mapping(uint256 => Offer)) offers;
    }

    function acceptOffer(uint256 _offerId) public {
        Offer storage offer = offers[_offerId];
        Request storage request = requests[offer.requestId];

        if (users[msg.sender].accountType != AccountType.BUYER) {
            revert Marketplace__OnlyBuyersAllowed();
        }

        if (requests[offer.requestId].buyerId != users[msg.sender].id) {
            revert Marketplace__UnauthorizedBuyer();
        }

        if (offer.isAccepted) {
            revert Marketplace__OfferAlreadyAccepted();
        }

        if (
            block.timestamp > request.updatedAt + TIME_TO_LOCK &&
            request.lifecycle == RequestLifecycle.ACCEPTED_BY_BUYER
        ) {
            revert Marketplace__RequestLocked();
        }

        for (uint i = 0; i < request.offerIds.length; i++) {
            uint256 offerId = request.offerIds[i];
            Offer storage previousOffer = offers[offerId];
            previousOffer.isAccepted = false;
            emit OfferAccepted(previousOffer.id, msg.sender, false);
        }

        offer.isAccepted = true;
        offer.updatedAt = block.timestamp;
        request.offerIds.push(offer.id);
        request.lockedSellerId = offer.sellerId;
        request.sellersPriceQuote = offer.price;
        request.acceptedOfferId = offer.id;
        request.lifecycle = RequestLifecycle.ACCEPTED_BY_BUYER;
        request.updatedAt = block.timestamp;

        emit RequestAccepted(
            request.id,
            offer.id,
            offer.sellerId,
            request.updatedAt,
            request.sellersPriceQuote
        );
        emit OfferAccepted(offer.id, msg.sender, true);
    }

    function userStoreCount(address user) public view returns (uint256) {
        return userStoreIds[user].length;
    }

    function getRequestImagesLength(
        uint256 requestId
    ) public view returns (uint256) {
        return requests[requestId].images.length;
    }

    function getRequestImageByIndex(
        uint256 requestId,
        uint256 index
    ) public view returns (string memory) {
        if (index >= requests[requestId].images.length) {
            revert Marketplace__IndexOutOfBounds();
        }
        return requests[requestId].images[index];
    }

    function getRequestSellerIdsLength(
        uint256 requestId
    ) public view returns (uint256) {
        return requests[requestId].sellerIds.length;
    }

    function getRequestSellerIdByIndex(
        uint256 requestId,
        uint256 index
    ) public view returns (uint256) {
        if (index >= requests[requestId].sellerIds.length) {
            revert Marketplace__IndexOutOfBounds();
        }
        return requests[requestId].sellerIds[index];
    }

    function getOfferImagesLength(
        uint256 offerId
    ) public view returns (uint256) {
        return offers[offerId].images.length;
    }

    function getOfferImageByIndex(
        uint256 offerId,
        uint256 index
    ) public view returns (string memory) {
        if (index >= offers[offerId].images.length) {
            revert Marketplace__IndexOutOfBounds();
        }
        return offers[offerId].images[index];
    }
}
