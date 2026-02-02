import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http, createConfig } from 'wagmi';
import { sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
    appName: 'RWAImob',
    projectId: process.env.NEXT_PUBLIC_WAGMI_PROJECT_ID || '148c75873bfa4432d8e90428e91d3266',
    chains: [sepolia],
    transports: {
        [sepolia.id]: http(process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL || 'https://ethereum-sepolia-rpc.publicnode.com'),
    },
    ssr: true,
});
