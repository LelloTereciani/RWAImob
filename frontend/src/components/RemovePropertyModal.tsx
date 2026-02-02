'use client';

import { useEffect, useRef, useState } from 'react';
import { useWriteContract, useAccount, useWaitForTransactionReceipt, useChainId, useReadContract } from 'wagmi';
import { PropertySaleAbi } from '../abis/PropertySaleAbi';
import { useAddRecentTransaction } from '@rainbow-me/rainbowkit';

const CONTRACT_ADDRESS = (process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || '0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0') as `0x${string}`;

export function RemovePropertyModal() {
    const { address } = useAccount();
    const chainId = useChainId();
    const [isOpen, setIsOpen] = useState(false);
    const [removeId, setRemoveId] = useState('');
    const [removeError, setRemoveError] = useState('');
    const successTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const addRecentTransaction = useAddRecentTransaction();

    const { data: removeHash, writeContract: writeDelist, isPending: isRemoving } = useWriteContract();
    const { isLoading: isRemovingConfirming, isSuccess: isRemoved } = useWaitForTransactionReceipt({ hash: removeHash });

    const parsedId = Number(removeId);
    const validId = Number.isFinite(parsedId) && parsedId > 0;
    const { data: propertyDetails } = useReadContract({
        address: CONTRACT_ADDRESS,
        abi: PropertySaleAbi,
        functionName: 'getPropertyDetails',
        args: validId ? [BigInt(parsedId)] : undefined,
        query: {
            enabled: validId,
        },
    });
    const propertyOwner = (propertyDetails as any)?.[0] as string | undefined;
    const isPropertyOwner = address && propertyOwner && address.toLowerCase() === propertyOwner.toLowerCase();

    const { data: ownerProperties, isLoading: isOwnerPropsLoading } = useReadContract({
        address: CONTRACT_ADDRESS,
        abi: PropertySaleAbi,
        functionName: 'getOwnerProperties',
        args: address ? [address] : undefined,
        query: {
            enabled: Boolean(address),
        },
    });
    const hasAnyProperty = Array.isArray(ownerProperties) && ownerProperties.length > 0;

    useEffect(() => {
        if (!removeHash || !address || !chainId) return;
        addRecentTransaction({
            hash: removeHash,
            description: 'Remoção de imóvel da venda',
        });
    }, [removeHash, address, chainId, addRecentTransaction]);

    useEffect(() => {
        if (!isRemoved) return;
        if (successTimeoutRef.current) clearTimeout(successTimeoutRef.current);
        successTimeoutRef.current = setTimeout(() => {
            setIsOpen(false);
            setRemoveId('');
            setRemoveError('');
        }, 2000);
        return () => {
            if (successTimeoutRef.current) {
                clearTimeout(successTimeoutRef.current);
                successTimeoutRef.current = null;
            }
        };
    }, [isRemoved]);

    const handleRemove = (e: React.FormEvent) => {
        e.preventDefault();
        if (!validId) {
            setRemoveError('Informe um ID válido (maior que 0).');
            return;
        }
        if (!address) {
            setRemoveError('Conecte sua carteira para remover.');
            return;
        }
        if (!isPropertyOwner) {
            setRemoveError('Apenas o owner do imóvel pode remover.');
            return;
        }
        setRemoveError('');
        writeDelist({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'delistProperty',
            args: [BigInt(parsedId)],
        });
    };

    if (!address) return null;
    if (isOwnerPropsLoading) {
        return (
            <div className="mb-12">
                <div className="h-[52px] w-[260px] rounded-2xl bg-slate-900/60 border border-white/10 animate-pulse" />
            </div>
        );
    }
    if (!hasAnyProperty) return null;

    return (
        <div className="mb-12">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="flex items-center gap-2 px-6 py-3 bg-slate-900 border border-white/10 text-white font-bold rounded-2xl hover:bg-slate-800 transition-all shadow-lg shadow-black/20 active:scale-95"
            >
                <span className="text-xl">−</span>
                Remover Imóvel da Venda
            </button>

            {isOpen && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-sm">
                    <div className="w-full max-w-md bg-slate-900 border border-white/10 rounded-[2.5rem] p-10 shadow-2xl">
                        <div className="flex justify-between items-center mb-8">
                            <h2 className="text-2xl font-bold text-white">Remover Imóvel</h2>
                            <button onClick={() => setIsOpen(false)} className="text-slate-400 hover:text-white">✕</button>
                        </div>

                        <form onSubmit={handleRemove} className="space-y-4">
                            <div className="space-y-2">
                                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">ID do Imóvel</label>
                                <input
                                    type="number"
                                    min="1"
                                    placeholder="Ex: 1"
                                    className="w-full px-5 py-4 bg-slate-950/50 border border-white/5 rounded-2xl text-white focus:border-emerald-500/50 focus:outline-none transition-colors"
                                    value={removeId}
                                    onChange={e => setRemoveId(e.target.value)}
                                />
                            </div>
                            <button
                                type="submit"
                                disabled={isRemoving || isRemovingConfirming || !validId || !isPropertyOwner}
                                className="w-full py-4 bg-red-500/20 text-red-300 font-bold rounded-2xl hover:bg-red-500/30 disabled:opacity-50 transition-all border border-red-500/20"
                            >
                                {isRemoving || isRemovingConfirming ? 'Removendo...' : 'Remover da Venda'}
                            </button>
                            {!isPropertyOwner && validId && address && (
                                <p className="text-amber-400 text-center text-xs font-semibold">Somente o owner pode remover.</p>
                            )}
                            {removeError && <p className="text-red-400 text-center text-sm font-bold">{removeError}</p>}
                            {isRemoved && <p className="text-emerald-400 text-center text-sm font-bold">✅ Imóvel removido da venda</p>}
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
