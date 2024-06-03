const { ethers, run, network } = require("hardhat");
require("dotenv").config();

async function main() {
    const BibahoBondhonFactory = await ethers.getContractFactory("BibahoBondhon");

    console.log("Deploying contract...");
    const bibahoBondhon = await BibahoBondhonFactory.deploy();
    await bibahoBondhon.getDeployedCode();
    console.log("Contract deployed!");

    const nAddress = await bibahoBondhon.getAddress();    
    console.log(`Contract deployed to: ${nAddress}`);

    console.log(`Network: ${network.name}`);

    if (network.name === "rinkeby" || network.name === "sepolia") {
        console.log("Waiting for 6 confirmations...");
        await bibahoBondhon.deployTransaction.wait(6);
        await verify(nAddress, []);
    } else {
        console.log("Verification not required on this network");
    }

    // Example interaction: Get the certificate count (this will fail if no certificates have been created)
    // try {
    //     const certificateCount = await bibahoBondhon.certificateCount();
    //     console.log(`Certificate count: ${certificateCount}`);
    // } catch (error) {
    //     console.error("Error fetching certificate count:", error);
    // }
}

// async function verify(contractAddress, args) {
//     console.log("Verifying contract...");
//     try {
//         await run("verify:verify", {
//             address: contractAddress,
//             constructorArguments: args,
//         });
//     } catch (e) {
//         if (e.message.toLowerCase().includes("already verified")) {
//             console.log("Already verified");
//         } else {
//             console.log(e);
//         }
//     }
// }

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
