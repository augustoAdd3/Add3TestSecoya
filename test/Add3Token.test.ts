/*****************************
 * Test on hardhat
 ****************************/

import { ethers } from "hardhat";
import { Add3Token } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";

describe("Add3Token", async () => {
  let add3Token: Add3Token;
  let owner: SignerWithAddress,
    account_0: SignerWithAddress,
    account_1: SignerWithAddress;
  const account_1_mint_amount = 5 * 365 * 20;
  before(async () => {
    [owner, account_0, account_1] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("Add3Token", owner);
    add3Token = (await Token.deploy(
      "Add3Token",
      "ADD3",
      10000000000
    )) as Add3Token;
  });

  describe("deployment", async () => {
    it("deploys successfully", async () => {
      const address = add3Token.address;
      expect(address).to.be.not.eql(0.0);
      expect(address).to.be.not.eql("");
      expect(address).to.be.not.eql(null);
      expect(address).to.be.not.eql(undefined);
    });
    it("has a name", async () => {
      const name = await add3Token.name();
      expect(name).to.be.eql("Add3Token");
    });
    it("has a symbol", async () => {
      const symbol = await add3Token.symbol();
      expect(symbol).to.be.eql("ADD3");
    });
    it("cap equal 10000000000", async () => {
      let cap = await add3Token.totalSupply();
      expect(ethers.utils.formatEther(cap)).to.be.eql("10000000000.0");
    });
  });

  describe("mint, transfer, burn, pause", async () => {
    it("non-owner cannot mint", async () => {
      await expect(
        add3Token
          .connect(account_1)
          .mint(account_1.address, account_1_mint_amount)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    it("cannot mint mor cap", async () => {
      await expect(
        add3Token.connect(account_1).mint(account_1.address, "200000000000000")
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    it("owner can mint more cap", async () => {
      const result = await add3Token
        .connect(owner)
        .mint(account_1.address, account_1_mint_amount);
      let balance = await add3Token.balanceOf(account_1.address);
      expect(account_1_mint_amount).to.be.eql(Number(balance));
    });
    it("cannot transfer more than the balance", async () => {
      await expect(
        add3Token.connect(account_1).transfer(account_0.address, 1000000000000)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });
    it("transfer", async () => {
      let balance_account1 = await add3Token.balanceOf(account_1.address);
      await add3Token.connect(account_1).transfer(account_0.address, 10);
      let balance = await add3Token.balanceOf(account_1.address);
      expect((Number(balance_account1) - 10).toString()).to.be.eql(
        balance.toString()
      );
      balance = await add3Token.balanceOf(account_0.address);
      expect((10).toString()).to.be.eql(balance.toString());
    });
    it("cannot burn more than the balance", async () => {
      await add3Token
        .connect(owner)
        .mint(account_1.address, account_1_mint_amount);
      await expect(add3Token.connect(account_1).burn(100000000000000)).to.be
        .reverted;
    });
    it("burn", async () => {
      let balance_account1 = await add3Token.balanceOf(account_1.address);
      const result = await add3Token.connect(account_1).burn(10);
      let balance = await add3Token.balanceOf(account_1.address);
      expect((Number(balance_account1) - 10).toString()).to.be.eql(
        balance.toString()
      );
    });
    it("approve", async () => {
      await add3Token.connect(account_0).approve(account_1.address, 10);
      let balance = await add3Token.allowance(
        account_0.address,
        account_1.address
      );
      expect((10).toString()).to.be.eql(balance.toString());
    });
    it("transferFrom exception", async () => {
      await expect(
        add3Token
          .connect(account_1)
          .transferFrom(account_1.address, account_0.address, 10)
      ).to.be.revertedWith("ERC20: insufficient allowance");
    });
    it("transferFrom", async () => {
      let balance_account1 = await add3Token.balanceOf(account_1.address);
      await add3Token
        .connect(account_1)
        .transferFrom(account_0.address, account_1.address, 10);
      let balance = await add3Token.balanceOf(account_1.address);
      expect((Number(balance_account1) + 10).toString()).to.be.eql(
        balance.toString()
      );
    });
    it("cannot do anything(Transfer, Burn...) if the token was paused", async () => {
      await add3Token.connect(owner).pause();

      await expect(
        add3Token.connect(account_1).transfer(account_0.address, 10)
      ).to.be.revertedWith("Pausable: paused");

      await expect(add3Token.connect(account_1).burn(10)).to.be.revertedWith(
        "Pausable: paused"
      );

      await add3Token.connect(owner).unpause();
    });
  });
});
