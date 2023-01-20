// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;



const receivingAddresses = [
  "0x44454670fb288b836ebbce9b691e2fc4f268c09b",
  "0x9254de3C7F64DAD0BeDedFC7c302D4fc73eC0CE5"
];

async function main() {
  const xyzTokenFactory = await ethers.getContractFactory("XYZ");
  console.log("Deploying contract");
  const npx = await xyzTokenFactory.deploy(receivingAddresses); // This sends it to the mempool
  const contractAddress = npx.address;
  console.log(`Deploying contract to : ${contractAddress}`);
  await npx.deployed(); // This waits for the transcation to be mined
  if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
    console.log("Waiting for 6 block confirmations before verifying contract");
    await npx.deployTransaction.wait(6);
    await verify(contractAddress, [receivingAddresses]);
  }
}

async function verify(contractAddress, args) {
  console.log("Verifying contract");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified");
    } else {
      console.error(e);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
