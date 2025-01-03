// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleMarketplace is ReentrancyGuard, Ownable {
    // Listing struct just holds essential info
    struct Listing {
        address seller;
        uint256 price;
        uint256 tokenId;
        address nftContract;
        bool isActive;
    }

    // State variables
    uint256 public marketplaceFee = 250; // 2.5% fee
    mapping(uint256 => Listing) public listings;
    uint256 private listingCounter;
    uint256[] private activeListingIds;

    // Events
    event ItemListed(uint256 indexed listingId, address seller, uint256 price);
    event ItemSold(uint256 indexed listingId, address seller, address buyer);
    event ListingCanceled(uint256 indexed listingId);

    constructor(address initialOwner) Ownable(initialOwner) {}

    // List NFT for sale
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than zero");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not the owner"
        );
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "Marketplace not approved"
        );

        listingCounter++;
        listings[listingCounter] = Listing({
            seller: msg.sender,
            price: price,
            tokenId: tokenId,
            nftContract: nftContract,
            isActive: true
        });

        activeListingIds.push(listingCounter);

        emit ItemListed(listingCounter, msg.sender, price);
    }

    // Buy listed NFT
    function buyItem(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");

        listing.isActive = false;

        // Calculate and transfer marketplace fee
        uint256 fee = (msg.value * marketplaceFee) / 10000;
        uint256 sellerAmount = msg.value - fee;

        // Transfer NFT to buyer
        IERC721(listing.nftContract).transferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        // Transfer payments
        (bool feeSuccess, ) = payable(owner()).call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");

        (bool sellerSuccess, ) = payable(listing.seller).call{
            value: sellerAmount
        }("");
        require(sellerSuccess, "Seller transfer failed");

        removeFromActiveListings(listingId);

        emit ItemSold(listingId, listing.seller, msg.sender);
    }

    // Cancel listing
    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Not the seller");
        require(listing.isActive, "Listing not active");

        listing.isActive = false;
        emit ListingCanceled(listingId);
    }

    // View function to get listing details
    function getListing(
        uint256 listingId
    )
        external
        view
        returns (
            address seller,
            uint256 price,
            uint256 tokenId,
            address nftContract,
            bool isActive
        )
    {
        Listing memory listing = listings[listingId];
        return (
            listing.seller,
            listing.price,
            listing.tokenId,
            listing.nftContract,
            listing.isActive
        );
    }

    function getAllListings(
        uint256 start,
        uint256 limit
    ) external view returns (Listing[] memory listedItems, uint256 totalCount) {
        uint256 activeCount = activeListingIds.length;
        uint256 count = (limit > activeCount - start)
            ? activeCount - start
            : limit;

        listedItems = new Listing[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 listingId = activeListingIds[start + i];
            listedItems[i] = listings[listingId];
        }

        return (listedItems, activeCount);
    }

    function removeFromActiveListings(uint256 listingId) internal {
        for (uint256 i = 0; i < activeListingIds.length; i++) {
            if (activeListingIds[i] == listingId) {
                activeListingIds[i] = activeListingIds[
                    activeListingIds.length - 1
                ];
                activeListingIds.pop();
                break;
            }
        }
    }
}
