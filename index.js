const {
  FileCreateTransaction,
  AccountId,
  Client,
  ContractCreateTransaction,
  PrivateKey,
} = require("@hashgraph/sdk");
const fs = require("fs");
require("dotenv").config();

const operatorId = AccountId.fromString(process.env.OPERATOR_ID);
const operatorKey = PrivateKey.fromStringDer(process.env.OPERATOR_KEY);

const client = Client.forTestnet().setOperator(operatorId, operatorKey);

const main = async () => {
  const info = fs.readFileSync(
    "./artifacts/contracts/Marketplace.sol/Marketplace.json",
    "utf-8"
  );

  const bytes = JSON.parse(info).bytecode;
  const fileCreateTx = new FileCreateTransaction()
    .setContents(bytes)
    .setKeys([operatorKey])
    .freezeWith(client);

  const fileCreateSign = await fileCreateTx.sign(operatorKey);
  const fileCreateSub = await fileCreateSign.execute(client);
  const fileCreateRx = await fileCreateSub.getReceipt(client);
  const byteCodeFileId = fileCreateRx.fileId;

  console.log(`The byte code file id is: ${byteCodeFileId}`);

  const contractInstantiateTx = new ContractCreateTransaction()
    .setBytecodeFileId(byteCodeFileId)
    .setGas(100000);
  const contractInstantiateSubmit = await contractInstantiateTx.execute(client);
  const contractInstantiateReceipt = await contractInstantiateSubmit.getReceipt(
    client
  );
  const contractId = contractInstantiateReceipt.contractId;
  const contractAddress = contractId.toSolidityAddress();

  console.log(`The contract address is:${contractId} ${contractAddress}`);
};

main();
