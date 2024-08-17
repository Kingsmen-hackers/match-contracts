import {
  AccountId,
  ContractExecuteTransaction,
  ContractFunctionParameters,
  ContractId,
  Hbar,
  LedgerId,
  PrivateKey,
  Client,
  TransactionResponse,
} from "@hashgraph/sdk";

import "dotenv/config";

export enum AccountType {
  BUYER,
  SELLER,
}

const appMetaData = {
  name: "Finder",
  description:
    "Finder is a blockchain application that allows buyers to find the best deals on products they want to buy.",
  icons: [window.location.origin + "/favicon.ico"],
  url: window.location.origin,
};

const CONTRACT_ID = "0.0.4686833";

const env = "testnet";
const PROJECT_ID = "73801621aec60dfaa2197c7640c15858";
const DEBUG = true;

const operatorId = AccountId.fromString(process.env.OPERATOR_ID!);
const adminKey = PrivateKey.fromStringDer(process.env.OPERATOR_KEY!);

const client = Client.forTestnet().setOperator(operatorId, adminKey);

export async function createUser(
  username: string,
  phone: string,
  lat: number,
  long: number,
  account_type: AccountType
): Promise<TransactionResponse | undefined> {
  try {
    const params = new ContractFunctionParameters();

    params.addString(username);
    params.addString(phone);
    params.addInt256(lat);
    params.addInt256(long);
    params.addUint8(account_type == AccountType.BUYER ? 0 : 1);
    let transaction = new ContractExecuteTransaction()
      .setContractId(ContractId.fromString(CONTRACT_ID))
      .setGas(1000000)
      .setFunction("createUser", params);

    const contractExecSubmit = await transaction.execute(client);
    return contractExecSubmit;
  } catch (error) {
    console.error(error);
  }
}

export async function createStore(
  name: string,
  description: string,
  latitude: number,
  longitude: number
): Promise<TransactionResponse | undefined> {
  try {
    const params = new ContractFunctionParameters();
    params.addString(name);
    params.addString(description);
    params.addInt256(latitude);
    params.addInt256(longitude);
    let transaction = new ContractExecuteTransaction()
      .setContractId(ContractId.fromString(CONTRACT_ID))
      .setGas(1000000)
      .setFunction("createStore", params);

    const contractExecSubmit = await transaction.execute(client);
    return contractExecSubmit;
  } catch (error) {
    console.error(error);
  }
}

export async function createRequest(
  name: string,
  buyerId: string,
  description: string,
  images: string[],
  latitude: number,
  longitude: number
): Promise<TransactionResponse | undefined> {
  try {
    const params = new ContractFunctionParameters();
    params.addString(name);
    params.addString(buyerId);
    params.addString(description);
    params.addStringArray(images);
    params.addInt256(latitude);
    params.addInt256(longitude);
    let transaction = new ContractExecuteTransaction()
      .setContractId(ContractId.fromString(CONTRACT_ID))
      .setGas(1000000)
      .setFunction("createRequest", params);
    const contractExecSubmit = await transaction.execute(client);
    return contractExecSubmit;
  } catch (error) {
    console.error(error);
  }
}

export async function createOffer(
  price: number,
  images: string[],
  requestId: string,
  storeName: string,
  sellerId: string
): Promise<TransactionResponse | undefined> {
  try {
    const params = new ContractFunctionParameters();
    params.addInt256(price);
    params.addStringArray(images);
    params.addString(requestId);
    params.addString(storeName);
    params.addString(sellerId);
    let transaction = new ContractExecuteTransaction()
      .setContractId(ContractId.fromString(CONTRACT_ID))
      .setGas(1000000)
      .setFunction("createOffer", params);

    const contractExecSubmit = await transaction.execute(client);
    return contractExecSubmit;
  } catch (error) {
    console.error(error);
  }
}

export async function acceptOffer(
  offerId: string
): Promise<TransactionResponse | undefined> {
  try {
    const params = new ContractFunctionParameters();
    params.addString(offerId);
    let transaction = new ContractExecuteTransaction()
      .setContractId(ContractId.fromString(CONTRACT_ID))
      .setGas(1000000)
      .setFunction("acceptOffer", params);

    const contractExecSubmit = await transaction.execute(client);
    return contractExecSubmit;
  } catch (error) {
    console.error(error);
  }
}

export async function removeOffer(
  offerId: string
): Promise<TransactionResponse | undefined> {
  try {
    const params = new ContractFunctionParameters();
    params.addAddress(offerId);
    let transaction = new ContractExecuteTransaction()
      .setContractId(ContractId.fromString(CONTRACT_ID))
      .setGas(1000000)
      .setFunction("removeOffer", params);

    const contractExecSubmit = await transaction.execute(client);
    return contractExecSubmit;
  } catch (error) {
    console.error(error);
  }
}
