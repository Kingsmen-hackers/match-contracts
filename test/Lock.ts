const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace", function () {
  let Marketplace, marketplace;
  let owner, buyer, seller;

  beforeEach(async function () {
    [owner, buyer, seller] = await ethers.getSigners();
    Marketplace = await ethers.getContractFactory("Marketplace");
    marketplace = await Marketplace.deploy();
    await marketplace.deployed();
  });

  describe("User Management", function () {
    it("Should create a buyer", async function () {
      await marketplace.connect(buyer).createUser(
        "buyer1",
        "buyerUser",
        "buyer@example.com",
        "123456789",
        "State1",
        "LGA1",
        "Market1",
        0 // 0 = BUYER
      );

      const user = await marketplace.users(buyer.address);
      expect(user.username).to.equal("buyerUser");
      expect(user.accountType).to.equal(0); // 0 = BUYER
    });

    it("Should create a seller", async function () {
      await marketplace.connect(seller).createUser(
        "seller1",
        "sellerUser",
        "seller@example.com",
        "987654321",
        "State2",
        "LGA2",
        "Market2",
        1 // 1 = SELLER
      );

      const user = await marketplace.users(seller.address);
      expect(user.username).to.equal("sellerUser");
      expect(user.accountType).to.equal(1); // 1 = SELLER
    });

    it("Should revert when creating a user with an invalid account type", async function () {
      await expect(
        marketplace.connect(buyer).createUser(
          "invalidUser",
          "invalid",
          "invalid@example.com",
          "000000000",
          "InvalidState",
          "InvalidLGA",
          "InvalidMarket",
          2 // Invalid account type
        )
      ).to.be.revertedWith("Marketplace__InvalidAccountType");
    });
  });

  describe("Store Management", function () {
    beforeEach(async function () {
      await marketplace.connect(seller).createUser(
        "seller1",
        "sellerUser",
        "seller@example.com",
        "987654321",
        "State2",
        "LGA2",
        "Market2",
        1 // 1 = SELLER
      );
    });

    it("Should allow a seller to create a store", async function () {
      await marketplace.connect(seller).createStore(
        "Store1",
        "This is a test store",
        "State2",
        "LGA2",
        "Market2"
      );

      const user = await marketplace.users(seller.address);
      expect(user.stores.length).to.equal(1);
      expect(user.stores[0].name).to.equal("Store1");
    });

    it("Should revert when a buyer tries to create a store", async function () {
      await marketplace.connect(buyer).createUser(
        "buyer1",
        "buyerUser",
        "buyer@example.com",
        "123456789",
        "State1",
        "LGA1",
        "Market1",
        0 // 0 = BUYER
      );

      await expect(
        marketplace.connect(buyer).createStore(
          "BuyerStore",
          "Buyer's store",
          "State1",
          "LGA1",
          "Market1"
        )
      ).to.be.revertedWith("Marketplace__OnlySellersAllowed");
    });
  });

  describe("Request and Offer Management", function () {
    beforeEach(async function () {
      await marketplace.connect(buyer).createUser(
        "buyer1",
        "buyerUser",
        "buyer@example.com",
        "123456789",
        "State1",
        "LGA1",
        "Market1",
        0 // 0 = BUYER
      );

      await marketplace.connect(seller).createUser(
        "seller1",
        "sellerUser",
        "seller@example.com",
        "987654321",
        "State2",
        "LGA2",
        "Market2",
        1 // 1 = SELLER
      );

      await marketplace.connect(seller).createStore(
        "Store1",
        "This is a test store",
        "State2",
        "LGA2",
        "Market2"
      );
    });

    it("Should allow a buyer to create a request", async function () {
      await marketplace.connect(buyer).createRequest(
        "request1",
        "Need a product",
        "buyer1",
        "Looking for a specific product",
        [],
        "Market1",
        "LGA1",
        "State1"
      );

      const request = await marketplace.requests("request1");
      expect(request.name).to.equal("Need a product");
      expect(request.buyerId).to.equal("buyer1");
    });

    it("Should revert when a seller tries to create a request", async function () {
      await expect(
        marketplace.connect(seller).createRequest(
          "invalidRequest",
          "Invalid",
          "seller1",
          "Invalid request",
          [],
          "Market2",
          "LGA2",
          "State2"
        )
      ).to.be.revertedWith("Marketplace__OnlyBuyersAllowed");
    });

    it("Should allow a seller to create an offer", async function () {
      await marketplace.connect(buyer).createRequest(
        "request1",
        "Need a product",
        "buyer1",
        "Looking for a specific product",
        [],
        "Market1",
        "LGA1",
        "State1"
      );

      await marketplace.connect(seller).createOffer(
        "offer1",
        ethers.utils.parseEther("1.0"),
        [],
        "request1",
        "Store1",
        "seller1"
      );

      const offer = await marketplace.offers("offer1");
      expect(offer.price.toString()).to.equal(ethers.utils.parseEther("1.0").toString());
      expect(offer.storeName).to.equal("Store1");
    });

    it("Should allow a buyer to accept an offer", async function () {
      await marketplace.connect(buyer).createRequest(
        "request1",
        "Need a product",
        "buyer1",
        "Looking for a specific product",
        [],
        "Market1",
        "LGA1",
        "State1"
      );

      await marketplace.connect(seller).createOffer(
        "offer1",
        ethers.utils.parseEther("1.0"),
        [],
        "request1",
        "Store1",
        "seller1"
      );

      await marketplace.connect(buyer).acceptOffer("offer1");

      const offer = await marketplace.offers("offer1");
      expect(offer.isAccepted).to.be.true;

      const request = await marketplace.requests("request1");
      expect(request.lockedSellerId).to.equal("seller1");
      expect(request.sellersPriceQuote.toString()).to.equal(ethers.utils.parseEther("1.0").toString());
      expect(request.lifecycle).to.equal(1); // 1 = ACCEPTED_BY_SELLER
    });

    it("Should revert when trying to accept an already accepted offer", async function () {
      await marketplace.connect(buyer).createRequest(
        "request1",
        "Need a product",
        "buyer1",
        "Looking for a specific product",
        [],
        "Market1",
        "LGA1",
        "State1"
      );

      await marketplace.connect(seller).createOffer(
        "offer1",
        ethers.utils.parseEther("1.0"),
        [],
        "request1",
        "Store1",
        "seller1"
      );

      await marketplace.connect(buyer).acceptOffer("offer1");

      await expect(
        marketplace.connect(buyer).acceptOffer("offer1")
      ).to.be.revertedWith("Marketplace__OfferAlreadyAccepted");
    });
  });
});
