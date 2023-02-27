// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {ISpamFee} from "./interfaces/ISpamFee.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Contained logic of fee to send a delivery.
/// @author 0x446576
contract SpamFee is ISpamFee, Ownable {
    uint256 public constant deliveryFee = 0.002 ether;

    function feePerDelivery() external pure returns (uint256) {
        return deliveryFee;
    }
}
