# Simple TCR

A simpler Token Curated Registry implementation using Ethereum smart contracts.

This implementation strips out most of the details and only keeps the basic TCR functionality. Consider this to be the "hello world" for TCR implementations.

Note: Most of the code for this Token Curated Registry implementation is derived from the [generic TCR implementation](https://github.com/skmgoldin/tcr) from Mike Goldin (and the adChain team).

## Why this implementation?

This TCR implementation is for getting a basic understanding of community driven curation using TCRs. While the [generic implementation](https://github.com/skmgoldin/tcr) is comprehensive and elegant, it is also too advanced to be used for understanding basic token based curation concepts. This simpler implementation strips out all advanced and complex functions and configuration parameters and only includes the basic curation functions - propose, challenge, vote, resolve, claim rewards.

## What makes it simple?

To keep this TCR implementation simple, following functions and components are not implemented or included.

1. PLCR voting - Instead of using PLCR voting, we are using just a list of polls and votes. There is no revealing of votes at a later stage. All votes are revealed by default.
1. Configurable parameters - All TCR parameters are hard-coded. Also, only a subset of parameters are used (min deposit, apply stage length, commit stage length).
1. Hard-coded rewards formula - The rewards calculation formula for all challenges is the same and is hard-coded as we are not using dispensation percentage and vote quorum parameters.
1. Only basic curation functions are implemented. Exits, deposit reduction, etc. are not implemented.

## When all this is left out, what's still in there?

Good question!

The following simple flow is implemented here,

1. Initialize a TCR with a token
1. Propose a listing
1. Challenge an applied/whitelisted listing
1. Vote on a challenge (without commit-reveal)
1. Update status of a listing (resolve challenge)
1. Claim rewards after a challenge is resolved (based on a hard-coded formula)

This basic flow helps understand the concepts of community driven curation using TCRs.

## Structure

The repository follow the structure of a regular truffle app created using `truffle init`. The **contracts** directory has two contracts - `token` and `tcr`. The token contract is derived from the [OpenZeppelin ERC20 contract](https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/token/ERC20) and the tcr contract has what's described in the sections above. The **test** directory contains positive unit tests for both contracts.

## Important Note

This TCR implementation is only for demo purposes. The solidity smart-contracts in this repository are **not audited** and they should not be used in production scenarios.

For real world (production) usage, please refer to the [generic TCR implementation](https://github.com/skmgoldin/tcr) from [Mike Goldin](https://github.com/skmgoldin) which is also being used in the [adChain registry](https://adchain.com/).