import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { network } from "hardhat";

describe("MyToken", async function () {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  describe("Deployment", function () {
    it("Should set the correct name", async function () {
      const myToken = await viem.deployContract("MyToken");
      const name = await myToken.read.name();
      assert.equal(name, "MyToken");
    });

    it("Should set the correct symbol", async function () {
      const myToken = await viem.deployContract("MyToken");
      const symbol = await myToken.read.symbol();
      assert.equal(symbol, "MTK");
    });

    it("Should set the correct decimals", async function () {
      const myToken = await viem.deployContract("MyToken");
      const decimals = await myToken.read.decimals();
      assert.equal(decimals, 18);
    });

    it("Should have the correct total supply", async function () {
      const myToken = await viem.deployContract("MyToken");
      const expectedSupply = 1_000_000n * 10n ** 18n;
      const totalSupply = await myToken.read.totalSupply();
      assert.equal(totalSupply, expectedSupply);
    });
  });

  describe("Transfer", function () {
    it("Should transfer tokens", async function () {
      const myToken = await viem.deployContract("MyToken");
      const recipientAddress = "0x1111111111111111111111111111111111111111";
      const transferAmount = 100n * 10n ** 18n;

      const balanceBefore = (await myToken.read.balanceOf([recipientAddress])) as bigint;
      await myToken.write.transfer([recipientAddress, transferAmount]);
      const balanceAfter = (await myToken.read.balanceOf([recipientAddress])) as bigint;

      assert.equal(balanceAfter - balanceBefore, transferAmount);
    });

    it("Should fail if recipient is zero address", async function () {
      const myToken = await viem.deployContract("MyToken");
      const transferAmount = 100n * 10n ** 18n;
      const zeroAddress = "0x0000000000000000000000000000000000000000";

      try {
        await myToken.write.transfer([zeroAddress, transferAmount]);
        assert.fail("Should have reverted");
      } catch (error: any) {
        assert.match(error.message, /recipient cannot be zero address/);
      }
    });

    it("Should emit Transfer event", async function () {
      const myToken = await viem.deployContract("MyToken");
      const events = await publicClient.getContractEvents({
        address: myToken.address,
        abi: myToken.abi,
        eventName: "Transfer",
        strict: true,
      });

      // Filter to the initial mint event
      const mintEvent = events.find((e) => (e.args as any).from === "0x0000000000000000000000000000000000000000");
      assert.ok(mintEvent, "Transfer event should be emitted on deployment");
    });
  });

  describe("Approve", function () {
    it("Should approve tokens for spending", async function () {
      const myToken = await viem.deployContract("MyToken");
      const spenderAddress = "0x2222222222222222222222222222222222222222";
      const approveAmount = 1000n * 10n ** 18n;

      await myToken.write.approve([spenderAddress, approveAmount]);

      const events = await publicClient.getContractEvents({
        address: myToken.address,
        abi: myToken.abi,
        eventName: "Approval",
        strict: true,
      });

      assert.ok(events.length > 0, "Approval event should be emitted");
      assert.equal((events[events.length - 1].args as any).value, approveAmount);
    });

    it("Should fail if spender is zero address", async function () {
      const myToken = await viem.deployContract("MyToken");
      const approveAmount = 1000n * 10n ** 18n;
      const zeroAddress = "0x0000000000000000000000000000000000000000";

      try {
        await myToken.write.approve([zeroAddress, approveAmount]);
        assert.fail("Should have reverted");
      } catch (error: any) {
        assert.match(error.message, /spender cannot be zero address/);
      }
    });

    it("Should update allowance", async function () {
      const myToken = await viem.deployContract("MyToken");
      const spenderAddress = "0x2222222222222222222222222222222222222222";
      const deployerAddress = "0xf24ff3a9cf04c71dbc94d0b566f7a27b94566cac";
      const approveAmount = 500n * 10n ** 18n;

      await myToken.write.approve([spenderAddress, approveAmount]);
      const allowance = (await myToken.read.allowance([
        deployerAddress,
        spenderAddress,
      ])) as bigint;
      assert.equal(allowance, approveAmount);
    });
  });

  describe("BalanceOf", function () {
    it("Should return correct balance for deployer", async function () {
      const myToken = await viem.deployContract("MyToken");
      const deployerAddress = "0xf24ff3a9cf04c71dbc94d0b566f7a27b94566cac";
      const expectedBalance = 1_000_000n * 10n ** 18n;

      const balance = (await myToken.read.balanceOf([deployerAddress])) as bigint;
      assert.equal(balance, expectedBalance);
    });

    it("Should return zero balance for new address", async function () {
      const myToken = await viem.deployContract("MyToken");
      const newAddress = "0x1111111111111111111111111111111111111111";

      const balance = (await myToken.read.balanceOf([newAddress])) as bigint;
      assert.equal(balance, 0n);
    });

    it("Should update balance after transfer", async function () {
      const myToken = await viem.deployContract("MyToken");
      const recipientAddress = "0x1111111111111111111111111111111111111111";
      const transferAmount = 500n * 10n ** 18n;

      await myToken.write.transfer([recipientAddress, transferAmount]);
      const balance = (await myToken.read.balanceOf([recipientAddress])) as bigint;
      assert.equal(balance, transferAmount);
    });
  });

  describe("Allowance", function () {
    it("Should return zero allowance by default", async function () {
      const myToken = await viem.deployContract("MyToken");
      const deployerAddress = "0xf24ff3a9cf04c71dbc94d0b566f7a27b94566cac";
      const spenderAddress = "0x2222222222222222222222222222222222222222";

      const allowance = (await myToken.read.allowance([
        deployerAddress,
        spenderAddress,
      ])) as bigint;
      assert.equal(allowance, 0n);
    });
  });
});
