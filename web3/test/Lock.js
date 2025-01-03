const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Contract", function () {
	let nftContract;
	let owner;
	let addr1;
	let addr2;

	beforeEach(async function () {
		[owner, addr1, addr2] = await ethers.getSigners();

		const NFT = await ethers.getContractFactory("NFT");
		nftContract = await NFT.deploy(owner.address);
		await nftContract.waitForDeployment();
	});

	describe("Deployment", function () {
		it("Should set the correct owner", async function () {
			expect(await nftContract.owner()).to.equal(owner.address);
		});

		it("Should have correct name and symbol", async function () {
			expect(await nftContract.name()).to.equal("NFTForge");
			expect(await nftContract.symbol()).to.equal("FORG");
		});
	});

	describe("Minting", function () {
		it("Should mint a new token with correct URI", async function () {
			const tokenURI = "ipfs://test-uri";
			await nftContract.safeMint(addr1.address, tokenURI);

			expect(await nftContract.ownerOf(0)).to.equal(addr1.address);
			expect(await nftContract.tokenURI(0)).to.equal(tokenURI);
		});

		it("Should increment token ID correctly", async function () {
			await nftContract.safeMint(addr1.address, "uri1");
			await nftContract.safeMint(addr1.address, "uri2");

			expect(await nftContract.ownerOf(1)).to.equal(addr1.address);
		});

		it("Should update balance correctly after minting", async function () {
			await nftContract.safeMint(addr1.address, "uri1");
			expect(await nftContract.balanceOf(addr1.address)).to.equal(1);
		});
	});

	describe("getMintedNftsofAddress", function () {
		it("Should revert if address has no NFTs", async function () {
			await expect(
				nftContract.getMintedNftsofAddress(addr1.address)
			).to.be.revertedWith("no nfts minted");
		});

		it("Should return correct token IDs and URIs for an address", async function () {
			await nftContract.safeMint(addr1.address, "uri1");
			await nftContract.safeMint(addr1.address, "uri2");

			const [tokenIds, uris] = await nftContract.getMintedNftsofAddress(
				addr1.address
			);

			expect(tokenIds.length).to.equal(2);
			expect(uris.length).to.equal(2);
			expect(tokenIds[0]).to.equal(0);
			expect(tokenIds[1]).to.equal(1);
			expect(uris[0]).to.equal("uri1");
			expect(uris[1]).to.equal("uri2");
		});
	});

	describe("ERC721 Standard Compliance", function () {
		it("Should support ERC721 interface", async function () {
			const ERC721InterfaceId = "0x80ac58cd";
			expect(await nftContract.supportsInterface(ERC721InterfaceId)).to.be
				.true;
		});

		it("Should support ERC721Enumerable interface", async function () {
			const ERC721EnumerableInterfaceId = "0x780e9d63";
			expect(
				await nftContract.supportsInterface(ERC721EnumerableInterfaceId)
			).to.be.true;
		});

		it("Should support ERC721Metadata interface", async function () {
			const ERC721MetadataInterfaceId = "0x5b5e139f";
			expect(
				await nftContract.supportsInterface(ERC721MetadataInterfaceId)
			).to.be.true;
		});
	});

	describe("Transfer Functionality", function () {
		beforeEach(async function () {
			await nftContract.safeMint(addr1.address, "uri1");
		});

		it("Should allow token transfer", async function () {
			await nftContract
				.connect(addr1)
				.transferFrom(addr1.address, addr2.address, 0);
			expect(await nftContract.ownerOf(0)).to.equal(addr2.address);
		});

		it("Should update balances after transfer", async function () {
			await nftContract
				.connect(addr1)
				.transferFrom(addr1.address, addr2.address, 0);
			expect(await nftContract.balanceOf(addr1.address)).to.equal(0);
			expect(await nftContract.balanceOf(addr2.address)).to.equal(1);
		});
	});
});
