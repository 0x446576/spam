# Spam : A Parasitic ERC721 Factory

This repository demonstrates a now lost smart contract pattern that uses a `MinimalProxyFactory` to mint a bulk amount of `ERC721` tokens using [EIP-2309](https://eips.ethereum.org/EIPS/eip-2309). As `selfdestruct` is being deprecated due to [EIP-4758](https://eips.ethereum.org/EIPS/eip-4758), this repository will no longer work after the upcoming hard-fork.

Living as a `Spam Engine`, individuals are enabled to make deliveries of varying weights to recipients that will mint a varying number of tokens that the recipient must pay a cost for to return to the Post.

The social game theory is as follows:

* Senders may mint a new `Delivery` by paying a small fee to the `Factory`.
* Senders may send a `Delivery` to a recipient that will explode into up to 5,000 `ERC721` tokens.
* Recipients will automatically receive `N` spam tokens when a `Delivery` is sent, there is no way to avoid it nor additional action required.
    * Even smart contract wallets can be spammed.
* Recipients may `resolve` a `Delivery` by paying a fee dependent on the size of `Delivery` to repackage all the pieces and get rid of the `Spam` in their Ethereum wallet and gain the ability to send a `Delivery` to a recipient of their choosing.
    * 1% of the fee will go to the `Factory` as opportunity compensation when a `Delivery` is `resolved`.
* When sending a `Delivery`, the image uploaded is the same image used for the pieces of `Spam`.
* Up to 5,000 `Defenders` may be minted at a cost of `0.008 Ether` each that will prevent an individual from being spammed when held-balance is greater than `1`.
    * This token does not expire, can be traded, and operates as a typical `ERC-721`.