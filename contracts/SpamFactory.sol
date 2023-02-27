// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {Spam} from "./Spam.sol";

import {ISpamFactory} from "./interfaces/ISpamFactory.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ISpamFee} from "./interfaces/ISpamFee.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev MinimalProxy Factory making spam deliveries to recipients at a fee.
/// @author 0x446576
contract SpamFactory is ISpamFactory, ERC721, Ownable {
    using Clones for address;
    using Strings for uint256;

    /// @dev Spam Defender ERC-721.
    IERC721 immutable defender;

    /// @dev Implementation of a deployed Pound.
    address immutable pound;

    /// @dev Fee consumer of protocol-cost of making a delivery.
    ISpamFee fee;

    /// @dev Id of token being minted next.
    uint256 tokenId;

    /// @dev URI per tokenId.
    mapping(uint256 => string) tokenIdToURI;

    /// @dev Amount of pounds per tokenId.
    mapping(uint256 => uint256) tokenIdToPounds;

    constructor(
        address _pound,
        IERC721 _defender,
        ISpamFee _fee,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        /// @dev Factory implementation to deploy.
        pound = _pound;

        /// @dev Defender preventing spam deliveries.
        defender = _defender;

        /// @dev Reference the fee consumer.
        _setFee(_fee);
    }

    function mint(string memory _uri) public payable virtual {
        /// @dev Confirm proper funding.
        require(
            msg.value == fee.feePerDelivery(),
            "SpamFactory::mint: Invalid payment."
        );

        /// @dev Image being used for token.
        tokenIdToURI[tokenId] = _uri;

        /// @dev Mint token.
        _safeMint(_msgSender(), tokenId++);
    }

    function resolve(uint256 _tokenId) public virtual {
        /// @dev Confirm the sender is the expected resolver.
        require(
            _msgSender() ==
                pound.predictDeterministicAddress(
                    _tokenHash(_tokenId),
                    address(this)
                ),
            "Spam::resolve: Invalid sender."
        );

        /// @dev Delete the spam delivery.
        delete tokenIdToPounds[_tokenId];
    }

    function withdraw() public virtual {
        /// @dev Pay the owner of the Factory.
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");

        /// @dev Confirm successful payment.
        require(sent, "Failed to send Ether");
    }

    function setFee(ISpamFee _fee) external onlyOwner {
        /// @dev Establish new fee reference.
        _setFee(_fee);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        /// @dev Pull the string out of storage.
        uri = tokenIdToURI[_tokenId];

        /// @dev Confirm valid configuation.
        require(bytes(uri).length > 0, "SpamFactory::tokenURI: Invalid token.");
    }

    function _setFee(ISpamFee _fee) internal {
        fee = _fee;

        emit FeeUpdated(_fee);
    }

    function _beforeTokenTransfer(
        address,
        address _to,
        uint256 _tokenId,
        uint256
    ) internal virtual override {
        /// @dev If no fee, guard.
        if (msg.value > 0) return;

        /// @dev If holds Defender, guard.
        if (defender.balanceOf(_to) > 0) return;

        /// @dev Weight of parcel already established.
        require(tokenIdToPounds[_tokenId] == 0, "Spam: Token already heavy.");

        /// @dev Deploy contract to the same address.
        address poundAddress = pound.cloneDeterministic(_tokenHash(_tokenId));

        /// @dev Reference the spam to initialize it.
        Spam spam = Spam(poundAddress);

        /// @dev  Pseudo-random number for pounds of delivery.
        uint96 pounds = 1 +
            (uint96(
                uint256(
                    keccak256(
                        abi.encodePacked(msg.sender, tokenId, block.coinbase)
                    )
                )
            ) % 4999);

        /// @dev Initialize the delivery.
        spam.initialize(_to, _tokenId, pounds);

        /// @dev Announce delivery of spam bucket.
        emit SpamIssued(_tokenId, poundAddress);
    }

    function _tokenHash(uint256 _tokenId) internal pure returns (bytes32) {
        /// @dev The salt-hash used for delivery deployment.
        return keccak256(abi.encode(_tokenId.toString()));
    }
}
