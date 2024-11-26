import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Reduce this if size is still an issue (e.g., 50 or 100).
      },
    },
  },
};

export default config;
