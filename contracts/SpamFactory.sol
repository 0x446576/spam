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

import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

/// @dev MinimalProxy Factory making spam deliveries to recipients at a fee.
/// @author 0x446576
contract SpamFactory is ISpamFactory, ERC721, Ownable {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;
    using Strings for uint256;

    /// @dev Spam Defender ERC-721.
    IERC721 public immutable defender;

    /// @dev Fee consumer of protocol-cost of making a delivery.
    ISpamFee public fee;

    /// @dev Id of token being minted next.
    uint256 public tokenId;

    /// @dev Id of token being deployed.
    uint256 public deliveringTokenId;

    /// @dev Recipient of delivery.
    address public deliveringTo;

    /// @dev URI per tokenId.
    mapping(uint256 => string) tokenIdToURI;

    /// @dev Amount of pounds per tokenId.
    mapping(uint256 => uint256) tokenIdToPounds;

    constructor(
        IERC721 _defender,
        ISpamFee _fee,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
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
            _msgSender() == address(getSpam(_tokenId)),
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
        if (bytes(uri).length == 0) uri = super.tokenURI(_tokenId);
    }

    function getSpam(uint256 _tokenId) public view returns (Spam spam) {
        return
            Spam(
                payable(
                    keccak256(
                        abi.encodePacked(
                            // Prefix:
                            bytes1(0xFF),
                            // Creator:
                            address(this),
                            // Salt:
                            bytes32(_tokenId),
                            // Bytecode hash:
                            keccak256(
                                abi.encodePacked(
                                    // Deployment bytecode:
                                    type(Spam).creationCode
                                )
                            )
                        )
                    ).fromLast20Bytes() // Convert the CREATE2 hash into an address.
                )
            );
    }

    function _setFee(ISpamFee _fee) internal {
        /// @dev Set the new fee.
        fee = _fee;

        /// @dev Emit the event for updated fees.
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

        /// @dev Load the hotslots.
        deliveringTokenId = _tokenId;
        deliveringTo = _to;

        /// @dev Deploy contract to the same address.
        Spam spam = new Spam{salt: bytes32(_tokenId)}();

        /// @dev Announce delivery of spam bucket.
        emit SpamIssued(_tokenId, address(spam));

        /// @dev Clear the hotslots.
        delete deliveringTokenId;
        delete deliveringTo;
    }

    function _tokenHash(uint256 _tokenId) internal pure returns (bytes32) {
        /// @dev The salt-hash used for delivery deployment.
        return keccak256(abi.encode(_tokenId.toString()));
    }
}
