import { createConfig } from "ponder";
import { http } from "viem";

import { PropertySaleAbi } from "./abis/PropertySaleAbi";

export default createConfig({
  chains: {
    localhost: {
      id: 31337,
      rpc:
        process.env.PONDER_RPC_URL_1 ??
        process.env.PONDER_RPC_URL_31337 ??
        "http://127.0.0.1:8545",
    },
  },
  contracts: {
    PropertySale: {
      abi: PropertySaleAbi,
      chain: "localhost",
      address: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
      startBlock: 0,
    },
  },
});
