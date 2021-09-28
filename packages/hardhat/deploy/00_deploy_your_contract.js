// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const myAddress = "0xcbBBFcd4DFcc67fF0Bdbbd59D9b91F38D4dBE494";

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    await deploy("Fruit", {
        from: deployer,
        log: true,
    });

    await deploy("Fertilizer", {
        from: deployer,
        log: true,
    });

    await deploy("Land", {
        from: deployer,
        log: true,
    });

    const fertilizer = await ethers.getContract("Fertilizer");
    const fruit = await ethers.getContract("Fruit");
    const land = await ethers.getContract("Land");

    const seed = await deploy("Seed", {
        from: deployer,
        args: [land.address, fruit.address, fertilizer.address],
        log: true,
    });

    await fertilizer.transfer(myAddress, ethers.utils.parseEther("10"));
    await fruit.transfer(myAddress, ethers.utils.parseEther("10"));
    const landId = await land.tokenOfOwnerByIndex(deployer, 0);
    await land.safeTransfer(myAddress, landId);

    /*
      // Getting a previously deployed contract
      const YourContract = await ethers.getContract("YourContract", deployer);
      await YourContract.setPurpose("Hello");
    
      To take ownership of yourContract using the ownable library uncomment next line and add the 
      address you want to be the owner. 
      // yourContract.transferOwnership(YOUR_ADDRESS_HERE);
  
      //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
    */

    /*
    //If you want to send value to an address from the deployer
    const deployerWallet = ethers.provider.getSigner()
    await deployerWallet.sendTransaction({
      to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
      value: ethers.utils.parseEther("0.001")
    })
    */

    /*
    //If you want to send some ETH to a contract on deploy (make your constructor payable!)
    const yourContract = await deploy("YourContract", [], {
    value: ethers.utils.parseEther("0.05")
    });
    */

    /*
    //If you want to link a library into your contract:
    // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
    const yourContract = await deploy("YourContract", [], {}, {
     LibraryName: **LibraryAddress**
    });
    */
};
module.exports.tags = ["Seed", "Fruit", "Land", "Fertilizer"];