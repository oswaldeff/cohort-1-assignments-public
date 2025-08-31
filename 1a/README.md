# MiniAMM

Install [foundry](https://getfoundry.sh/forge/overview/) and initialize the forge workspace.

Go to [the faucet](https://faucet.flare.network/coston2) and input your EVM wallet address to get C2FLR testnet token. Use this wallet to deploy your contract.

## Requirements

`MiniAMM.sol` has two features available to users:

1. Add liquidity: users supply two tokens at the same time. Essentially, this function transfers a pair of tokens into the contract, thereby increasing the $k$. However, the ratio of $x$ to $y$ must stay constant, except for the first time the liquidity is supplied.
1. Swap: users can swap $x$ amount of token into $y$ amount of token, keeping $k$ constant. Essentially, this transfers $x$ amount of token into the contract, and transfers out $y$ amount of token to the user, while keeping $k$ constant.

To be able to test MiniAMM, you need to deploy two different mock ERC-20 tokens:

1. Complete MockERC20 contract in `MockERC20.sol`. `freeMintTo` must mint `amount` tokens to `to`. `freeMintToSender` mints `amount` tokens to `msg.sender`. These functions must be callable by any address so that minting is available for anyone.

You can test if your contracts are working correctly by running `forge test`. **Your goal is to make all tests pass without hardcoding the answers into your contracts.**

After that, **deploy and verify** two different `MockERC20` contracts with arbitrary names and symbols you choose, as well as `MiniAMM` contract to [Flare Coston2 Testnet](https://coston2.testnet.flarescan.com/). **To verify** means your contract code will be visible on a blockchain explorer. You will need to use [the faucet](https://faucet.flare.network/coston2) to fund your deployer account.

`MiniAMM` contract should take those two `MockERC20` contract addresses as `tokenX` and `tokenY` respectively.

### Deliverables

Once you are done with everything, you would be left with:

- A complete `MiniAMM.sol` implementation
- A complete `MockERC20.sol` implementation
- A complete `MiniAMM.s.sol` implementation
- Deployment addresses of `MiniAMM`, and two `MockERC20` contracts on https://coston2.testnet.flarescan.com/
- All tests under `test` folder passing with `forge test`

### 1a submission info

```
##### flare-coston2
✅  [Success] Hash: 0xc3ba62fbcf627c28efe79de65890a3cd317de4dd6a487c9581ba6ef3ff583fa6
Contract Address: 0x4A6A8D1563461873437a54be925aEd2b9Af5c624
Block: 21421452
Paid: 0.0615721875 C2FLR (985155 gas * 62.5 gwei)


##### flare-coston2
✅  [Success] Hash: 0xe8bc2157bf968c63f7777c13ec883c68b058304bc3682679deef98359ebde1d4
Contract Address: 0xA3099B5a2fD1D693b93F68C28d30D8903b8a0754
Block: 21421453
Paid: 0.0615721875 C2FLR (985155 gas * 62.5 gwei)


##### flare-coston2
✅  [Success] Hash: 0x1d65a4b3b3fe5bb7482b30afabd108aae6fb87702462f9edff5861e49c65fb90
Contract Address: 0x23fc70763017B34427D7460cF0500c81a2Ea6f6E
Block: 21421454
Paid: 0.06657375 C2FLR (1065180 gas * 62.5 gwei)

✅ Sequence #1 on flare-coston2 | Total Paid: 0.189718125 C2FLR (3035490 gas * avg 62.5 gwei)


==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
```
