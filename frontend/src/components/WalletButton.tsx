'use client';

import { useConnectModal, useChainModal } from '@rainbow-me/rainbowkit';
import { useEffect, useMemo, useState } from 'react';
import { useAccount, useBalance, useDisconnect } from 'wagmi';
import { sepolia } from 'wagmi/chains';

function shortenAddress(address?: string) {
  if (!address) return '';
  return `${address.slice(0, 4)}...${address.slice(-4)}`;
}

function formatBalance(value?: string, symbol?: string) {
  if (!value || !symbol) return null;

  const parsed = Number.parseFloat(value);
  if (Number.isNaN(parsed)) return `${value} ${symbol}`;

  return `${parsed.toFixed(3)} ${symbol}`;
}

export function WalletButton() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const { address, chain, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const { data: balance } = useBalance({
    address,
    query: {
      enabled: Boolean(address),
    },
  });
  const { openConnectModal } = useConnectModal();
  const { openChainModal } = useChainModal();

  useEffect(() => {
    if (!copied) return;

    const timeout = window.setTimeout(() => {
      setCopied(false);
    }, 1500);

    return () => window.clearTimeout(timeout);
  }, [copied]);

  const shortAddress = useMemo(() => shortenAddress(address), [address]);
  const balanceLabel = useMemo(
    () => formatBalance(balance?.formatted, balance?.symbol),
    [balance?.formatted, balance?.symbol],
  );

  const handlePrimaryClick = () => {
    if (!isConnected) {
      openConnectModal?.();
      return;
    }

    if (chain?.id !== sepolia.id) {
      openChainModal?.();
      return;
    }

    setIsModalOpen(true);
  };

  const handleCopyAddress = async () => {
    if (!address) return;

    try {
      await navigator.clipboard.writeText(address);
      setCopied(true);
    } catch (error) {
      console.error('Failed to copy wallet address', error);
    }
  };

  return (
    <>
      <button
        type="button"
        onClick={handlePrimaryClick}
        className="h-11 rounded-2xl border border-white/10 bg-slate-900/70 px-5 text-sm font-semibold text-white transition hover:border-emerald-400/40 hover:bg-slate-800/80"
      >
        {!isConnected
          ? 'Conectar Carteira'
          : chain?.id !== sepolia.id
            ? 'Trocar Rede'
            : shortAddress}
      </button>

      {isModalOpen && isConnected && address && (
        <div
          className="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/75 px-4"
          onClick={() => setIsModalOpen(false)}
        >
          <div
            className="w-full max-w-xs rounded-3xl border border-white/10 bg-slate-900 p-5 shadow-2xl shadow-black/40"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="flex items-start justify-between">
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-br from-emerald-400 to-cyan-500 text-2xl">
                <span aria-hidden="true">W</span>
              </div>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-white/5 text-slate-400 transition hover:bg-white/10 hover:text-white"
                aria-label="Fechar modal da carteira"
              >
                <svg viewBox="0 0 20 20" className="h-4 w-4 fill-current">
                  <path d="M5.22 5.22a.75.75 0 0 1 1.06 0L10 8.94l3.72-3.72a.75.75 0 1 1 1.06 1.06L11.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06L10 11.06l-3.72 3.72a.75.75 0 1 1-1.06-1.06L8.94 10 5.22 6.28a.75.75 0 0 1 0-1.06Z" />
                </svg>
              </button>
            </div>

            <div className="mt-4 text-center">
              <p className="text-2xl font-bold text-white">{shortAddress}</p>
              {balanceLabel && (
                <p className="mt-1 text-sm font-medium text-slate-400">{balanceLabel}</p>
              )}
            </div>

            <div className="mt-5 grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={handleCopyAddress}
                className="rounded-2xl bg-white/5 px-4 py-3 text-sm font-semibold text-white transition hover:bg-white/10"
              >
                <span className="mb-2 flex justify-center text-slate-400">
                  <svg viewBox="0 0 20 20" className="h-5 w-5 fill-current">
                    <path d="M6.75 2.5A2.25 2.25 0 0 0 4.5 4.75v7A2.25 2.25 0 0 0 6.75 14h7A2.25 2.25 0 0 0 16 11.75v-7A2.25 2.25 0 0 0 13.75 2.5h-7Zm-1 2.25c0-.55.45-1 1-1h7c.55 0 1 .45 1 1v7c0 .55-.45 1-1 1h-7c-.55 0-1-.45-1-1v-7Z" />
                    <path d="M2.5 8.25A2.25 2.25 0 0 1 4 6.13v1.38a1 1 0 0 0-.25-.01h-.5a1 1 0 0 0-1 1v7c0 .55.45 1 1 1h7a1 1 0 0 0 1-1v-.5c0-.08 0-.17-.01-.25H12.62a2.25 2.25 0 0 1-2.12 1.5h-7A2.25 2.25 0 0 1 2.5 15.5v-7.25Z" />
                  </svg>
                </span>
                {copied ? 'Copiado' : 'Copiar Endereco'}
              </button>

              <button
                type="button"
                onClick={() => {
                  disconnect();
                  setIsModalOpen(false);
                }}
                className="rounded-2xl bg-white/5 px-4 py-3 text-sm font-semibold text-white transition hover:bg-white/10"
              >
                <span className="mb-2 flex justify-center text-slate-400">
                  <svg viewBox="0 0 20 20" className="h-5 w-5 fill-current">
                    <path d="M10.75 3a.75.75 0 0 1 .75-.75h3A2.25 2.25 0 0 1 17.75 4.5v11A2.25 2.25 0 0 1 15.5 17.75h-3a.75.75 0 0 1 0-1.5h3a.75.75 0 0 0 .75-.75v-11a.75.75 0 0 0-.75-.75h-3a.75.75 0 0 1-.75-.75Z" />
                    <path d="M11.53 10.53a.75.75 0 0 0 0-1.06L8.81 6.75a.75.75 0 1 0-1.06 1.06l1.44 1.44H3a.75.75 0 0 0 0 1.5h6.19l-1.44 1.44a.75.75 0 1 0 1.06 1.06l2.72-2.72Z" />
                  </svg>
                </span>
                Desconectar
              </button>
            </div>

            <p className="mt-4 break-all text-center text-xs text-slate-500">{address}</p>
          </div>
        </div>
      )}
    </>
  );
}
