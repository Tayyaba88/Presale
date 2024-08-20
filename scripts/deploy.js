const { ethers } = require("hardhat");

async function main() {
  const presale = await ethers.getContractFactory("Presale");
  console.log("Deploying Presale...");

  try {
    const contract = await presale.deploy();
    await contract.waitForDeployment();

    console.log("Deployed to ", await contract.getAddress());
  } catch (error) {
    console.error("Error deploying Presale:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
