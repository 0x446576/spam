import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { deploySpamDefender, deploySpamFee, deployFactoryFixture } from "./utils";

describe("SpamFactory", function () {
    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { factory, owner } = await loadFixture(deployFactoryFixture);

            expect(await factory.owner()).to.equal(owner.address);
        });
    });

    describe("Configuration", function () {
        describe("Validations", async function () {
            it("Should set the right deployment values", async function () {
                const { defender, fee, factory } = await loadFixture(deployFactoryFixture);

                expect(await factory.defender()).to.equal(defender.address)
                expect(await factory.fee()).to.equal(fee.address)
            })

            it("Should revert with the right error if called from non-owner account", async function () {
                const { fee, factory, otherAccount } = await loadFixture(deployFactoryFixture);

                await expect(factory.connect(otherAccount).setFee(fee.address)).to.be.revertedWith("Ownable: caller is not the owner")
            });
        })
    });

    describe("Transfers", function () {
        describe("ETH Payments", function () {
            it("Should pay Factory when minting a new delivery", async function () {
                const { fee, factory, owner } = await loadFixture(deployFactoryFixture);

                const value = await fee.feePerDelivery();

                await expect(factory.mint("0x", { value })).to.changeEtherBalances(
                    [owner, factory.address],
                    [-value, value]
                );
            });
        });

        describe("Token Deliveries", function () {
            it("Should delivery tokens when delivery is transfered to recipient", async function () {
                const { fee, factory, owner, otherAccount } = await loadFixture(deployFactoryFixture);

                const value = await fee.feePerDelivery();

                await expect(factory.mint("0x", { value })).to.not.be.reverted;

                await expect(factory.transferFrom(owner.address, otherAccount.address, 0)).to.not.be.reverted;
            })
        })
    });
});
