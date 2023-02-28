import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";

async function deploySpamDefender() {
    const Defender = await ethers.getContractFactory("SpamDefender")
    const defender = await Defender.deploy("Spam Defender", "SPAMD");
    await defender.deployed()

    return { defender }
}

async function deploySpamFee() {
    const Fee = await ethers.getContractFactory("SpamFee");
    const fee = await Fee.deploy();
    await fee.deployed();

    return { fee }
}

async function deployFactoryFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const { defender } = await loadFixture(deploySpamDefender);
    const { fee } = await loadFixture(deploySpamFee)

    const Factory = await ethers.getContractFactory("SpamFactory");
    const factory = await Factory.deploy(defender.address, fee.address, "Spam", "SPAM");
    await factory.deployed();

    return { defender, fee, factory, owner, otherAccount }
}

export {
    deploySpamDefender,
    deploySpamFee,
    deployFactoryFixture
}