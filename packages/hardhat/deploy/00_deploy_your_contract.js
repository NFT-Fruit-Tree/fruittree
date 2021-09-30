// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    await deploy("Currency", {
        from: deployer,
        log: true,
    });
    const currency = await ethers.getContract("Currency");

    await deploy("Fruit", {
        from: deployer,
        args: [currency.address],
        log: true,
    });
    await deploy("Land", {
        from: deployer,
        args: [currency.address],
        log: true,
    });
    const land = await ethers.getContract("Land");
    const fruit = await ethers.getContract("Fruit");

    await deploy("Seed", {
        from: deployer,
        args: [land.address, fruit.address, currency.address],
        log: true,
    });

    console.log("📢 Premint started...");
    const step = 50;
    for (let i = 0; i < 1024; i += step) {
        try {
            await land.premint(i, i + step);
        } catch (e) {
            console.error(`🛑 Premint failed for i from ${i}`);
            throw e;
        }
    }
    await land.renounceOwnership();
    console.log("✅ Premint ended...");

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