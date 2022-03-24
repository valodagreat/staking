const main = async () => {
    const stakingContractFactory = await hre.ethers.getContractFactory('Staking');
    const stakingContract = await stakingContractFactory.deploy();
    await stakingContract.deployed();
    console.log("Token Contract deployed to:", stakingContract.address);
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();