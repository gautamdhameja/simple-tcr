# Simple Token Curated Registry Implementation

Most of the code for this Token Curated Registry implementation is derived from the [generic TCR implementation](https://github.com/skmgoldin/tcr) from Mike Goldin (and the adChain team).

This implementation strips out most of the details and only keeps the basic TCR functionality. Consider this to be the "hello world" for TCR implementation.

For real world (production) usage, please refer to the generic TCR implementation
[https://github.com/skmgoldin/tcr](https://github.com/skmgoldin/tcr).

## Why another implementation?

This TCR implementation is for basic understanding of community driven curation using TCRs. While the [generic implementation](https://github.com/skmgoldin/tcr) is comprehensive and elegant, it is also too advanced to be used for understanding basic token-curation functions. Hence, this simpler implementation strips out all advanced and complex functions and configuration and only includes the basic curation functions - apply, challenge, vote, resolve, claim rewards.

## What's making it simple?

To keep this TCR implementation simple, following functions and components are not implemented or included.

1. PLCR voting - Instead of using PLCR voting, we are using just a list of polls and votes. There is no revealing of votes at a later stage. All votes are revealed by default.
1. Configurable parameters - All TCR parameters are hard-coded. Also, only a subset of parameters are used (min deposit, apply stage length, commit stage length).
1. Hard-coded rewards formula - The rewards calculation formula for all challenges is the same and is hard-coded as we are not using dispensation percentage and vote quorum parameters.
1. Only basic curation functions are implemented. Exits, deposit reduction, etc. are not implemented.

### When all this is left out, what's still in there?

Good question!

The following simple TCR flow is implemented,

1. Initialize a TCR with a token
1. Apply a listing
1. Challenge an applied/whitelisted listing
1. Vote on a challenge
1. Claim rewards when the challenge is resolved

This basic flow helps understand the power of community driven curation.

## Structure

The repository follow the structure of a regular truffle app created using `truffle init`. The contracts directory has two contracts - `token` and `tcr`. The token contract is default ERC20 contract and the tcr contract has what's described in the sections above. The `test` directory has positive unit tests for both contracts.