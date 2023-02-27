// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {ISpamFee} from "./ISpamFee.sol";

interface ISpamFactory {
    event FeeUpdated(ISpamFee fee);

    event SpamIssued(uint256 tokenId, address tokenAddress);
}
