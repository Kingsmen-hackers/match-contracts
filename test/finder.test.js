const { expect } = require("chai");

const {
  acceptOffer,
  AccountType,
  createOffer,
  createRequest,
  createStore,
  createUser,
  removeOffer,
} = require("../setup");

describe("Marketplace Smart Contract Tests", function () {
  // Sample user data
  const testUser = {
    username: "TestUser",
    phone: "1234567890",
    latitude: 37.7749,
    longitude: -122.4194,
    accountType: AccountType.BUYER, // BUYER
  };

  const testStore = {
    name: "TestStore",
    description: "A test store",
    latitude: 37.7749,
    longitude: -122.4194,
  };

  const testRequest = {
    name: "TestRequest",
    description: "A test request",
    images: ["img1.jpg", "img2.jpg"],
    latitude: 37.7749,
    longitude: -122.4194,
  };

  const testOffer = {
    price: 1000,
    images: ["offer_img1.jpg", "offer_img2.jpg"],
    requestId: "1",
    storeName: "TestStore",
    sellerId: "0.0.12345",
  };

  it("should create a new user", async function () {
    const receipt = await createUser(
      testUser.username,
      testUser.phone,
      testUser.latitude,
      testUser.longitude,
      testUser.accountType
    );
    expect(receipt).to.not.be.null;
    // expect(receipt.status).to.equal("SUCCESS");
  });

  it("should create a new store", async function () {
    const receipt = await createStore(
      testStore.name,
      testStore.description,
      testStore.latitude,
      testStore.longitude
    );
    expect(receipt).to.not.be.null;
    // expect(receipt.status).to.equal("SUCCESS");
  });

  it("should create a new request", async function () {
    const receipt = await createRequest(
      testRequest.name,
      "0.0.12345", // Example buyer ID
      testRequest.description,
      testRequest.images,
      testRequest.latitude,
      testRequest.longitude
    );
    expect(receipt).to.not.be.null;
    // expect(receipt.status).to.equal("SUCCESS");
  });

  it("should create a new offer", async function () {
    const receipt = await createOffer(
      testOffer.price,
      testOffer.images,
      testOffer.requestId,
      testOffer.storeName,
      testOffer.sellerId
    );
    expect(receipt).to.not.be.null;
    // expect(receipt.status).to.equal("SUCCESS");
  });

  it("should accept an offer", async function () {
    const receipt = await acceptOffer("1"); // Example offer ID
    expect(receipt).to.not.be.null;
    // expect(receipt.status).to.equal("SUCCESS");
  });

  it("should remove an offer", async function () {
    const receipt = await removeOffer("1"); // Example offer ID
    expect(receipt).to.not.be.null;
    // expect(receipt.status).to.equal("SUCCESS");
  });
});
