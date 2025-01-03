const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleMarketplace", function () {
	let nftContract;
	let marketplace;
	let owner;
	let seller;
	let buyer;

	beforeEach(async function () {
		[owner, seller, buyer] = await ethers.getSigners();

		// Deploy NFT
		const NFT = await ethers.getContractFactory("NFT");
		nftContract = await NFT.deploy(owner.address);

		// Deploy marketplace
		const Marketplace = await ethers.getContractFactory(
			"SimpleMarketplace"
		);
		marketplace = await Marketplace.deploy(owner.address);

		// Mint NFT to seller
		await nftContract.safeMint(seller.address, "test-uri");
		// Approve marketplace
		await nftContract
			.connect(seller)
			.approve(await marketplace.getAddress(), 0);
	});

	it("Should list an item", async function () {
		await marketplace
			.connect(seller)
			.listItem(
				await nftContract.getAddress(),
				0,
				ethers.parseEther("1")
			);

		const listing = await marketplace.getListing(1);
		expect(listing.seller).to.equal(seller.address);
		expect(listing.price).to.equal(ethers.parseEther("1"));
		expect(listing.isActive).to.be.true;
	});

	it("Should buy a listed item", async function () {
		await marketplace
			.connect(seller)
			.listItem(
				await nftContract.getAddress(),
				0,
				ethers.parseEther("1")
			);

		await marketplace.connect(buyer).buyItem(1, {
			value: ethers.parseEther("1"),
		});

		expect(await nftContract.ownerOf(0)).to.equal(buyer.address);
	});

	it("Should allow canceling a listing", async function () {
		await marketplace
			.connect(seller)
			.listItem(
				await nftContract.getAddress(),
				0,
				ethers.parseEther("1")
			);

		await marketplace.connect(seller).cancelListing(1);

		const listing = await marketplace.getListing(1);
		expect(listing.isActive).to.be.false;
	});
});
