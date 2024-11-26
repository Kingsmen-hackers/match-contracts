const {
  FileCreateTransaction,
  AccountId,
  Client,
  ContractCreateTransaction,
  PrivateKey,
  FileAppendTransaction,
  Hbar,
} = require("@hashgraph/sdk");
const fs = require("fs");
require("dotenv").config();

const operatorId = AccountId.fromString(process.env.OPERATOR_ID);
const adminKey = PrivateKey.fromStringDer(process.env.OPERATOR_KEY);

const client = Client.forTestnet().setOperator(operatorId, adminKey);

const main = async () => {
  const info = fs.readFileSync(
    "./artifacts/contracts/Marketplace.sol/Marketplace.json",
    "utf-8"
  );

  const bytecode = JSON.parse(info).bytecode;
  const fileCreateTx = await new FileCreateTransaction()
    .setKeys([adminKey])
    .execute(client);
  const fileCreateRx = await fileCreateTx.getReceipt(client);
  const bytecodeFileId = fileCreateRx.fileId;
  console.log(`- The smart contract bytecode file ID is: ${bytecodeFileId}`);

  // Append contents to the file
  const fileAppendTx = await new FileAppendTransaction()
    .setFileId(bytecodeFileId)
    .setContents(bytecode)
    .setMaxChunks(50)
    .execute(client);
  await fileAppendTx.getReceipt(client);
  console.log(`- Content added`);

  console.log(`\nSTEP 2 - Create contract`);
  const contractCreateTx = await new ContractCreateTransaction()
    .setAdminKey(adminKey)
    .setBytecodeFileId(bytecodeFileId)
    .setGas(1000000)
    .execute(client);

  const contractCreateRx = await contractCreateTx.getReceipt(client);
  const contractId = contractCreateRx.contractId.toString();
  console.log(`- Contract created ${contractId}`);
};

main()
  .catch(console.error)
  .then(() => process.exit(0));
