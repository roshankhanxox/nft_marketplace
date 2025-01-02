// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    constructor(
        address initialOwner
    ) ERC721("NFTForge", "FORG") Ownable(initialOwner) {}

    uint256 private _nextTokenId;

    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //fucntion to get all minted nfts of an address
    function getMintedNftsofAddress(
        address user
    ) public view returns (uint256[] memory, string[] memory) {
        uint256 tokencount = balanceOf(user);
        require(tokencount > 0, "no nfts minted");

        uint256[] memory tokenIds = new uint256[](tokencount);
        string[] memory uris = new string[](tokencount);

        for (uint256 i = 0; i < tokencount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            tokenIds[i] = tokenId;
            uris[i] = tokenURI(tokenId);
        }
        return (tokenIds, uris);
    }
}
