const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contract with account:", deployer.address);

  const MultiSig = await hre.ethers.getContractFactory("MultiSigWallet");

  const owners = ["0x9d07c6d66C0dcdb7103541d75f626843d39D101b"];
  const requiredConfirmations = 1;

  const wallet = await MultiSig.deploy(owners, requiredConfirmations);
  await wallet.deployed();

  console.log("MultiSigWallet deployed to:", wallet.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
