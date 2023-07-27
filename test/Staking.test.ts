/*****************************
 * Test on hardhat
 ****************************/

import { ethers, upgrades } from "hardhat";
import { time } from "@openzeppelin/test-helpers";
import {
  Add3Token,
  Add3Token__factory,
  Staking,
  Staking__factory,
} from "../typechain-types";
import { expect } from "chai";

const provider = new ethers.providers.JsonRpcProvider(
  `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_GOERLI_API_KEY}`,
  { name: "goerli", chainId: 5 }
);

const tokenAddress = process.env.TEST_ADD3TOKEN_ADDRESS!;
const stakingAddress = process.env.TEST_STAKING_ADDRESS!;
const owner = process.env.PRIVATE_KEY
  ? new ethers.Wallet(process.env.PRIVATE_KEY!, provider)
  : ethers.Wallet.createRandom();
const other = process.env.PRIVATE_KEY1
  ? new ethers.Wallet(process.env.PRIVATE_KEY1!, provider)
  : ethers.Wallet.createRandom();

const firstStakePeriod = 5;
const secondStakePeriod = 10;
const firstStakeAmount = ethers.utils.parseEther("10");
const secondStakeAmount = ethers.utils.parseEther("20");
describe("Staking", async () => {
  let add3Token: Add3Token;
  let staking: Staking;

  before(async () => {
    add3Token = Add3Token__factory.connect(tokenAddress, owner) as Add3Token;
    staking = Staking__factory.connect(stakingAddress, owner) as Staking;
  });

  describe("stake", async () => {
    it("cannot stake 0 amount", async () => {
      await expect(staking.connect(owner).stake(0, 10)).to.be.rejectedWith(
        "Amount must be greater than 0"
      );
    });
    it("cannot stake without approve", async () => {
      await expect(
        staking.connect(other).stake(secondStakeAmount, firstStakePeriod)
      ).to.be.rejected;
    });
    it("Approve ADD3 token for the first user", async () => {
      await add3Token.connect(owner).approve(stakingAddress, firstStakeAmount);
    });
    it("first user stake 10 ADD3 tokens", async () => {
      const beforeBalance = await add3Token
        .connect(owner)
        .balanceOf(owner.address);
      console.log(ethers.utils.formatEther(beforeBalance));
      await staking.connect(owner).stake(firstStakeAmount, firstStakePeriod);
      const afterBalance = await add3Token
        .connect(owner)
        .balanceOf(owner.address);
      console.log(ethers.utils.formatEther(afterBalance));
      expect(Number(beforeBalance) - Number(firstStakeAmount)).to.be.eql(
        Number(afterBalance),
        "First user balance should be decreased as staking amount"
      );
    });
    it("Approve ADD3 token for the second user", async () => {
      await add3Token.connect(other).approve(stakingAddress, secondStakeAmount);
    });
    it("second user stake 20 ADD3 tokens", async () => {
      const beforeBalance = await add3Token
        .connect(other)
        .balanceOf(other.address);
      await staking.connect(other).stake(secondStakeAmount, secondStakePeriod);
      const afterBalance = await add3Token
        .connect(other)
        .balanceOf(other.address);
      expect(Number(beforeBalance) - Number(secondStakeAmount)).to.be.eql(
        Number(afterBalance),
        "First user balance should be decreased as staking amount"
      );
    });
  });
  describe("claim", async () => {
    it("check claimable amount for first user as 10 tokens", async () => {
      await time.advanceBlock();
      const claimableAmount = await staking
        .connect(owner)
        ._claimableAmount(0, owner.address);
      expect(ethers.utils.formatEther(claimableAmount)).to.be.eql(
        10,
        "Incorrect claimable amount"
      );
    });
    it("check claimable amount for second user as 20 tokens", async () => {
      await time.advanceBlock();
      const claimableAmount = await staking
        .connect(other)
        ._claimableAmount(0, other.address);
      expect(ethers.utils.formatEther(claimableAmount)).to.be.eql(
        20,
        "Incorrect claimable amount"
      );
    });
  });

  describe("unstake", async () => {
    it("Cannot unstake with incorrect id", async () => {
      await expect(staking.connect(owner).unstake(1)).to.be.rejected;
    });
    it("Unstake first user", async () => {
      await time.advanceBlock();
      const beforeBalance = await add3Token
        .connect(owner)
        .balanceOf(owner.address);
      await staking.connect(owner).unstake(0);
      const afterBalance = await add3Token
        .connect(owner)
        .balanceOf(owner.address);

      expect(Number(beforeBalance) + 30).to.be.eql(
        Number(afterBalance),
        "First user balance should be increased as staking amount"
      );
    });
    it("Unstake second user", async () => {
      await time.advanceBlock();
      const beforeBalance = await add3Token
        .connect(other)
        .balanceOf(other.address);
      await staking.connect(other).unstake(0);
      const afterBalance = await add3Token
        .connect(other)
        .balanceOf(other.address);

      expect(Number(beforeBalance) + 40).to.be.eql(
        Number(afterBalance),
        "Second user balance should be increased as staking amount"
      );
    });
  });

  describe("Set Reward rate", async () => {
    it("Cannot set reward rate with other user", async () => {
      await expect(staking.connect(other).setRewardRate(20)).to.be.rejected;
    });
    it("Set reward rate", async () => {
      await staking.connect(owner).setRewardRate(20);
      const reward = staking.connect(owner)._rewardRate;
      expect(reward.toString()).to.be.eql("20", "Reward rate is not updated");
    });
  });
});
