import { createConfig } from "ponder";
import { PropertySaleAbi } from "./abis/PropertySaleAbi";

export default createConfig({
  chains: {
    sepolia: {
      id: 11155111,
      rpc:
        process.env.PONDER_RPC_URL_11155111 ??
        "https://ethereum-sepolia-rpc.publicnode.com",
    },
  },
  contracts: {
    PropertySale: {
      abi: PropertySaleAbi,
      chain: "sepolia",
      address:
        process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ??
        process.env.PONDER_CONTRACT_ADDRESS ??
        "0x0000000000000000000000000000000000000000",
      startBlock: Number(process.env.PONDER_START_BLOCK ?? 0),
    },
  },
});
