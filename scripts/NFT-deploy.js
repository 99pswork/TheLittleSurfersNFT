const { ethers } = require("hardhat");

contract("NFT deployment", () => {
	let nft;

	before(async () => {
    const NFT = await ethers.getContractFactory("TheLittleSurfers");
		nft = await NFT.deploy(
			"Tiger",
			"TIGER",
			"150000000000000000",
			"200000000000000000",
			12,
      2,
	  4,
      5
		);
		await nft.deployed();

		console.log("NFT deployed at address: ", nft.address);
	});

	it("should print contract address", async () => {
		console.log("NFT deployed at address: ", nft.address);
	});

});
