# 🏗 scaffold-eth - 📈 Bonding Curve Emoji Feast 😃😡😎🤣❤️😔

> Bonding Curve Gamification of sorts by setting up 6 different emojis's on same type of bonding curves

<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a>About The Branch</a>
    </li>
    <li>
      <a>Getting Started</a>
      <ul>
        <li><a>Installation</a></li>
        <li><a>Introduction</a></li>
        <li><a>To-Do</a></li>
      </ul>
    </li>
    <li><a>Branch UI Walkthrough</a></li>
    <li><a>Contact</a></li>
  </ol>
</details>

## About The Branch

This branch is entitled to showcase a particular usecase of [Bonding Curve](https://yos.io/2018/11/10/bonding-curves/) which makes use of the [Bancor's Bonding Curve Formula](https://yos.io/2018/11/10/bonding-curves/#mathematical-formula) & it is a upgraded version of this [branch](https://github.com/scaffold-eth/scaffold-eth/tree/bonding-curve)


## Getting Started


### Installation

Let's start our environment for tinkering and exploring how NFT auction would work.

1. Clone the repo first
```sh
git clone -b bonding-curve-emoji-feast https://github.com/austintgriffith/scaffold-eth.git bonding-curve-emoji-feast
cd bonding-curve-emoji-feast
```

2. Install dependencies
```bash
yarn install
```

3. Spin up local chain
```sh
yarn chain
```

4. Deploy Contracts
```sh
yarn deploy
```

5. Start React frontend
```bash
yarn start
```

## Introduction

**To Dive deep on an introduction to bonding curves, please check out this [branch](https://github.com/scaffold-eth/scaffold-eth/tree/bonding-curve) as the emoji feast (current branch) assumes the users having a basic understanding of bonding curves and bancor bonding curves spefically**

Basically the idea behind this branch is to gamify bonding curves by creating a price leaderboard for different emoji's, so more costly the emoji the higher it is ranked on the leaderboard.

The price is fetched from a smart contract method
```
function getPrice() external view returns (uint256)
```

which just returns the price of 1 ETH worth of the emoji token.

### Mechanism

During the deployment when the 6 emoji contract's get deployed there is small 0.0001 eth to set the reserve amount which is required as per the Bancor Formula and the reserve ratio which determines the price sensitivity is set to 30 % for all emoji's

Further on as user lock in eth in a particular emoji token contract they wish to mint and the price increases with the supply and vice-versa if the user burns the token.

## To-Do
- Beautufy the design, right now the ui code in terms of styling is pretty simple and un-appealing the aim is get the design right in terms of the factors mentioned above

- React code for leaderboard, need to sort the [emojiQuoteArray](https://github.com/scaffold-eth/scaffold-eth/blob/bonding-curve-emoji-feast/packages/react-app/src/views/ExampleUI.jsx#L78) with each object having different keys.




## Branch UI Walkthrough

Firstly, get us some funds using local faucet.

<img width="458" alt="feast 1" src="https://user-images.githubusercontent.com/26670962/132893454-5775c6b4-ad87-46c9-af92-d4b7f9541355.png">


Mint & Burn Different Emoji's


## Contact

Join the [telegram support chat 💬](https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA) to ask questions and find others building with 🏗 scaffold-eth!
