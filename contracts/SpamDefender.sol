// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SpamDefender is ERC721 {
    /// @dev Cost to mint a Defender.
    uint256 public constant COST = 0.008 ether;

    /// @dev Number of Defenders that can be minted.
    uint256 public constant MAX_SUPPLY = 5_000;

    /// @dev Id of token being minted next.
    uint256 tokenId;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint() public payable virtual {
        /// @dev Collect proper payment.
        require(msg.value == COST, "SpamDefender::mint: Invalid payment.");

        /// @dev Track the number of Defenders live.
        uint256 mintId = tokenId++;

        /// @dev Apply max supply strictfully.
        require(mintId < MAX_SUPPLY, "SpamDefender::mint: Invalid supply.");

        /// @dev Mint the Defender to the sender.
        _safeMint(_msgSender(), mintId);
    }
}
