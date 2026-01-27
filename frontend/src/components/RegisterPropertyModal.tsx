'use client';

import { useState } from 'react';
import { useWriteContract, useAccount, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { PropertySaleAbi } from '../abis/PropertySaleAbi';

const CONTRACT_ADDRESS = (process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || '0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0') as `0x${string}`;

export function RegisterPropertyModal() {
    const { address } = useAccount();
    const [isOpen, setIsOpen] = useState(false);
    const [form, setForm] = useState({
        location: '',
        price: '',
        uri: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c'
    });

    const { data: contractOwner } = useReadContract({
        address: CONTRACT_ADDRESS,
        abi: PropertySaleAbi,
        functionName: 'owner',
    });

    const { data: hash, writeContract, isPending } = useWriteContract();
    const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

    const isPlatformOwner = address && contractOwner && address.toLowerCase() === (contractOwner as string).toLowerCase();

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (!form.location || !form.price) return;

        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'listProperty',
            args: [form.location, parseEther(form.price), form.uri],
        });
    };

    if (!isPlatformOwner) return null;

    return (
        <div className="mb-12">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-emerald-500 to-cyan-600 text-slate-950 font-bold rounded-2xl hover:scale-105 transition-all shadow-lg shadow-emerald-500/20 active:scale-95"
            >
                <span className="text-xl">+</span>
                Cadastrar Novo Ativo RWA
            </button>

            {isOpen && (
                <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-sm">
                    <div className="w-full max-w-md bg-slate-900 border border-white/10 rounded-[2.5rem] p-10 shadow-2xl">
                        <div className="flex justify-between items-center mb-8">
                            <h2 className="text-2xl font-bold text-white">Novo Cadastro</h2>
                            <button onClick={() => setIsOpen(false)} className="text-slate-400 hover:text-white">✕</button>
                        </div>

                        <form onSubmit={handleSubmit} className="space-y-6">
                            <div className="space-y-2">
                                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Localização / Nome</label>
                                <input
                                    type="text"
                                    required
                                    placeholder="Ex: Cobertura em Ipanema, RJ"
                                    className="w-full px-5 py-4 bg-slate-950/50 border border-white/5 rounded-2xl text-white focus:border-emerald-500/50 focus:outline-none transition-colors"
                                    value={form.location}
                                    onChange={e => setForm({ ...form, location: e.target.value })}
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Preço Base (ETH)</label>
                                <input
                                    type="number"
                                    step="0.01"
                                    required
                                    placeholder="Ex: 1.5"
                                    className="w-full px-5 py-4 bg-slate-950/50 border border-white/5 rounded-2xl text-white focus:border-emerald-500/50 focus:outline-none transition-colors"
                                    value={form.price}
                                    onChange={e => setForm({ ...form, price: e.target.value })}
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="text-xs font-bold text-slate-400 uppercase tracking-widest">Imagem URI (Social Proof)</label>
                                <input
                                    type="text"
                                    placeholder="URL da Imagem"
                                    className="w-full px-5 py-4 bg-slate-950/50 border border-white/5 rounded-2xl text-white focus:border-emerald-500/50 focus:outline-none transition-colors"
                                    value={form.uri}
                                    onChange={e => setForm({ ...form, uri: e.target.value })}
                                />
                            </div>

                            <button
                                type="submit"
                                disabled={isPending || isConfirming}
                                className="w-full py-5 bg-emerald-500 text-slate-950 font-black rounded-2xl hover:bg-emerald-400 disabled:opacity-50 transition-all shadow-xl shadow-emerald-500/20"
                            >
                                {isPending || isConfirming ? 'Registrando na Blockchain...' : 'Finalizar Cadastro'}
                            </button>

                            {isSuccess && <p className="text-emerald-400 text-center text-sm font-bold animate-bounce">🚀 Ativo registrado com sucesso!</p>}
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
