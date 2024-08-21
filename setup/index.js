import {
  AccountId,
  ContractExecuteTransaction,
  ContractFunctionParameters,
  ContractId,
  Hbar,
  LedgerId,
  PrivateKey,
  Client,
} from "@hashgraph/sdk";

import { ethers } from "ethers";

import { marketAbi } from "./abi.js";

import "dotenv/config";

export const AccountType = {
  BUYER: 0,
  SELLER: 1,
};

const CONTRACT_ID = "0.0.4686833";

export const operatorId = AccountId.fromString(process.env.OPERATOR_ID);
const adminKey = PrivateKey.fromStringDer(process.env.OPERATOR_KEY);

const client = Client.forTestnet().setOperator(operatorId, adminKey);

const HEDERA_JSON_RPC = {
  mainnet: "https://mainnet.hashio.io/api",
  testnet: "https://testnet.hashio.io/api",
};

export async function createUser(username, phone, lat, long, account_type) {
  try {
    const params = new ContractFunctionParameters();
    params.addString(username);
    params.addString(phone);
    params.addInt256(lat);
    params.addInt256(long);
    params.addUint8(AccountType.BUYER);

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

export async function createStore(name, description, latitude, longitude) {
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
  name,
  description,
  images,
  latitude,
  longitude
) {
  try {
    const params = new ContractFunctionParameters();
    params.addString(name);
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
  price,
  images,
  requestId,
  storeName,

) {
  try {
    const params = new ContractFunctionParameters();
    params.addInt256(price);
    params.addStringArray(images);
    params.addString(requestId);
    params.addString(storeName);

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

export async function acceptOffer(offerId) {
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

export async function removeOffer(offerId) {
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

export async function getEvmAddress(account_id) {
  const url = `https://testnet.mirrornode.hedera.com/api/v1/accounts/${account_id}?limit=1`;
  const response = await fetch(url);
  const data = await response.json();
  return data?.evm_address;
}

export function getContract() {
  const contractAddress = AccountId.fromString(CONTRACT_ID).toSolidityAddress();
  const provider = new ethers.JsonRpcProvider(HEDERA_JSON_RPC.testnet);

  return new ethers.Contract(`0x${contractAddress}`, marketAbi, provider);
}

export async function fetchUser(account_id) {
  const contract = getContract();
  const userAddress = await getEvmAddress(account_id);

  const user = await contract.users(userAddress);

  return user;
}
