import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http, createConfig } from 'wagmi';
import { mainnet, base, anvil } from 'wagmi/chains';

export const config = getDefaultConfig({
    appName: 'RWAImob',
    projectId: process.env.NEXT_PUBLIC_WAGMI_PROJECT_ID || '148c75873bfa4432d8e90428e91d3266',
    chains: [anvil, base, mainnet],
    transports: {
        [anvil.id]: http('http://localhost:8545'),
        [base.id]: http(),
        [mainnet.id]: http(),
    },
    ssr: true,
});
