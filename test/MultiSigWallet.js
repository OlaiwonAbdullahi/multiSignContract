const { expect } = require("chai");
const hre = require("hardhat");
const ethers = hre.ethers;

describe("MultiSigWallet", function () {
  let MultiSig, wallet;
  let owner1, owner2, owner3, other;
  const requiredConfirmations = 2;

  beforeEach(async function () {
    [owner1, owner2, owner3, other] = await ethers.getSigners();
    MultiSig = await ethers.getContractFactory("MultiSigWallet");
    wallet = await MultiSig.deploy(
      [owner1.address, owner2.address, owner3.address],
      requiredConfirmations
    );

    await owner1.sendTransaction({
      to: wallet.address,
      value: hre.ethers.utils.parseEther("10"),
    });
  });

  it("should deploy with correct owners and confirmations", async () => {
    expect(await wallet.owners(0)).to.equal(owner1.address);
    expect(await wallet.required()).to.equal(requiredConfirmations);
  });

  it("should allow owner to submit a transaction", async () => {
    await expect(
      wallet
        .connect(owner1)
        .submitTransaction(other.address, ethers.utils.parseEther("1"), "0x")
    ).to.emit(wallet, "TransactionSubmitted");
    expect(await wallet.getTransactionCount()).to.equal(1);
  });

  it("should allow confirmation, revocation and execution", async () => {
    await wallet
      .connect(owner1)
      .submitTransaction(other.address, ethers.utils.parseEther("1"), "0x");

    await expect(wallet.connect(owner1).confirmTransaction(0)).to.emit(
      wallet,
      "TransactionConfirmed"
    );
    await expect(wallet.connect(owner2).confirmTransaction(0)).to.emit(
      wallet,
      "TransactionConfirmed"
    );
    await expect(wallet.connect(owner1).revokeConfirmation(0)).to.emit(
      wallet,
      "TransactionRevoked"
    );
    await wallet.connect(owner1).confirmTransaction(0);

    await expect(wallet.connect(owner3).executeTransaction(0)).to.emit(
      wallet,
      "TransactionExecuted"
    );
  });

  it("should not allow execution without enough confirmations", async () => {
    await wallet
      .connect(owner1)
      .submitTransaction(other.address, ethers.utils.parseEther("1"), "0x");
    await wallet.connect(owner1).confirmTransaction(0);
    await expect(
      wallet.connect(owner1).executeTransaction(0)
    ).to.be.revertedWith("Not enough confirmations");
  });
});
