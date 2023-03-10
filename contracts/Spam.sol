// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {SpamFactory} from "./SpamFactory.sol";

import {ISpam} from "./interfaces/ISpam.sol";
import {ERC721Consecutive} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @dev An EIP-2309 driven ERC-721 implementation minting tokens to a recipient
///      in order to spam the wallet of an Ethereum user.
/// @author 0x446576
contract Spam is ISpam, ERC721Consecutive {
    using Strings for uint256;

    /// @dev Factory of delivery.
    ERC721 resolver;

    /// @dev Sender of delivery.
    address payable sender;

    /// @dev Cost of resolving.
    uint256 public constant ethPerPound = 0.0002 ether;

    constructor()
        ERC721(
            string(
                abi.encodePacked(
                    "Spam: #",
                    SpamFactory(_msgSender()).deliveringTokenId().toString()
                )
            ),
            string(
                abi.encodePacked(
                    "Spam-",
                    SpamFactory(_msgSender()).deliveringTokenId().toString()
                )
            )
        )
    {
        /// @dev Factory deploying deliveries.
        resolver = ERC721(_msgSender());

        /// @dev Make the delivery.
        _mintConsecutive(
            SpamFactory(_msgSender()).deliveringTo(),
            1 +
                (uint96(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _msgSender(),
                                address(this),
                                block.coinbase
                            )
                        )
                    )
                ) % 4999)
        );
    }

    function resolve() public payable virtual {
        /// @dev Pay the clean-up fee.
        require(
            msg.value == ethPerPound * _mintConsecutive(_msgSender(), 0),
            "Spam::resolve: Invalid payment."
        );

        /// @dev Resolver compensation.
        uint256 resolverValue = (msg.value * 100) / 10000;

        /// @dev Pay the resolver.
        (bool sent, ) = address(resolver).call{value: resolverValue}("");
        require(sent, "Failed to send Ether");

        /// @dev Send remaining funds to delivery sender.
        selfdestruct(payable(sender));
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        /// @dev Use the image placed on the Delivery.
        return resolver.tokenURI(_tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256,
        uint256
    ) internal pure override {
        /// @dev If no zeroed party, guard.
        if (_from == address(0) || _to == address(0)) return;

        /// @dev Prevent the token from being transferred.
        revert("Spam::_beforeTokenTransfer: Invalid transfer.");
    }
}
