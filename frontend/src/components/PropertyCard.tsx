'use client';

import { useWriteContract, useWaitForTransactionReceipt, useAccount, useReadContract } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { PropertySaleAbi } from '../abis/PropertySaleAbi';
import { useState, useEffect } from 'react';
import { translateError } from '../utils/errorTranslator';
import { useQueryClient } from '@tanstack/react-query';

const CONTRACT_ADDRESS = (process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || '0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0') as `0x${string}`;

interface PropertyProps {
    property: {
        id: number;
        owner: string;
        price: string;
        forSale: boolean;
        locationHash: string;
    };
}

export function PropertyCard({ property }: PropertyProps) {
    const { address } = useAccount();
    const [offerAmount, setOfferAmount] = useState('');
    const [showOfferInput, setShowOfferInput] = useState(false);
    const [pendingAction, setPendingAction] = useState<'buy' | 'relist' | 'offer' | 'accept' | 'withdraw' | null>(null);
    const [relistPrice, setRelistPrice] = useState<string | null>(null);

    const queryClient = useQueryClient();
    const { data: hash, writeContract, isPending: isWritePending, error: writeError } = useWriteContract();
    const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
        hash,
    });

    // Atualizar dados após confirmação
    useEffect(() => {
        if (isConfirmed) {
            // Atualização Otimista
            if (pendingAction === 'buy' && address) {
                setLocalOwner(address);
                setLocalForSale(false);
            } else if (pendingAction === 'relist' && relistPrice) {
                setLocalForSale(true);
                setLocalPrice(relistPrice);
            } else if (pendingAction === 'accept') {
                setLocalForSale(false);
            }

            queryClient.invalidateQueries({ queryKey: ['properties'] });

            setTimeout(() => {
                queryClient.invalidateQueries({ queryKey: ['properties'] });
                setPendingAction(null);
                setRelistPrice(null);
            }, 2000);
        }
    }, [isConfirmed, queryClient, pendingAction, address, relistPrice]);

    // Buscar ofertas da propriedade
    const { data: offers, refetch: refetchOffers } = useReadContract({
        address: CONTRACT_ADDRESS,
        abi: PropertySaleAbi,
        functionName: 'getPropertyOffers',
        args: [BigInt(property.id)],
    });

    const [localForSale, setLocalForSale] = useState(property.forSale);
    const [localOwner, setLocalOwner] = useState(property.owner);
    const [localPrice, setLocalPrice] = useState(property.price);

    // Sincronizar estado local apenas quando NÃO houver ação pendente
    // Isso evita que o status "Vendido" volte para "À Venda" por delay do indexador
    useEffect(() => {
        if (!pendingAction && !isWritePending && !isConfirming) {
            setLocalForSale(property.forSale);
            setLocalOwner(property.owner);
            setLocalPrice(property.price);
        }
    }, [property.forSale, property.owner, property.price, pendingAction, isWritePending, isConfirming]);

    const isOwner = address && localOwner.toLowerCase() === address.toLowerCase();

    const handleBuy = () => {
        if (!address) {
            alert("Por favor, conecte sua carteira primeiro");
            return;
        }

        if (isOwner) {
            alert("Você já é o dono deste imóvel!");
            return;
        }

        // Validação extra do preço
        const priceToPay = BigInt(localPrice.toString());

        console.log(`🏠 Comprando Imóvel #${property.id}`);
        console.log(`📍 Contrato: ${CONTRACT_ADDRESS}`);
        console.log(`💰 Valor: ${formatEther(priceToPay)} ETH`);

        setPendingAction('buy');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'buyProperty',
            args: [BigInt(property.id)],
            value: priceToPay,
        });
    };

    const handleMakeOffer = () => {
        if (!address) {
            alert("Por favor, conecte sua carteira primeiro");
            return;
        }
        if (!offerAmount || parseFloat(offerAmount) <= 0) {
            alert("Digite um valor válido para a oferta");
            return;
        }

        setPendingAction('offer');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'makeOffer',
            args: [BigInt(property.id)],
            value: parseEther(offerAmount),
        });
    };

    const handleAcceptOffer = (offerIndex: number) => {
        setPendingAction('accept');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'acceptOffer',
            args: [BigInt(property.id), BigInt(offerIndex)],
        });
    };

    const handleWithdrawOffer = (offerIndex: number) => {
        setPendingAction('withdraw');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'withdrawOffer',
            args: [BigInt(property.id), BigInt(offerIndex)],
        });
    };

    const handleRelist = () => {
        const newPrice = prompt("Digite o novo preço em ETH:", formatEther(BigInt(localPrice)));
        if (!newPrice || isNaN(parseFloat(newPrice))) return;

        const priceInWei = parseEther(newPrice).toString();
        setRelistPrice(priceInWei);
        setPendingAction('relist');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'relistProperty',
            args: [BigInt(property.id), BigInt(priceInWei)],
        });
    };

    const activeOffers = offers ? (offers as any[]).filter((offer: any) => offer.active) : [];
    const userOfferIndex = offers ? (offers as any[]).findIndex((offer: any) => offer.active && address && offer.buyer.toLowerCase() === address.toLowerCase()) : -1;

    return (
        <div className="group overflow-hidden rounded-[2.5rem] bg-slate-900/40 border border-white/5 backdrop-blur-sm hover:border-emerald-500/40 transition-all hover:translate-y-[-8px]">
            {/* Imagem do Imóvel */}
            <div className="aspect-[16/10] bg-gradient-to-br from-emerald-900/20 to-cyan-900/20 relative overflow-hidden">
                <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1600585154340-be6161a56a0c')] bg-cover bg-center mix-blend-overlay opacity-50 group-hover:scale-110 transition-transform duration-700"></div>
                <div className="absolute top-4 left-4 px-3 py-1 bg-emerald-500/20 backdrop-blur-md border border-emerald-500/20 rounded-full text-emerald-400 text-[10px] font-bold tracking-widest uppercase">
                    {localForSale ? 'À Venda' : 'Vendido / Fora do Mercado'}
                </div>
                {activeOffers.length > 0 && (
                    <div className="absolute top-4 right-4 px-3 py-1 bg-amber-500/20 backdrop-blur-md border border-amber-500/20 rounded-full text-amber-400 text-[10px] font-bold tracking-widest uppercase">
                        {activeOffers.length} {activeOffers.length === 1 ? 'Oferta' : 'Ofertas'}
                    </div>
                )}
            </div>

            <div className="p-8 space-y-6">
                <div>
                    <h3 className="text-2xl font-bold text-white group-hover:text-emerald-400 transition-colors">Vila Real Estate #{property.id}</h3>
                    <p className="text-slate-400 mt-2 line-clamp-1 text-xs">{property.locationHash}</p>
                </div>

                <div className="flex items-center justify-between pt-4 border-t border-white/5">
                    <div>
                        <p className="text-slate-500 text-xs font-semibold uppercase tracking-wider">Valor Atual</p>
                        <p className="text-2xl font-black text-white">{formatEther(BigInt(localPrice))} ETH</p>
                    </div>

                    {localForSale ? (
                        isOwner ? (
                            <button disabled className="h-12 px-6 bg-slate-700 text-slate-400 font-bold rounded-2xl cursor-not-allowed">
                                Seu Imóvel
                            </button>
                        ) : (
                            <button
                                onClick={handleBuy}
                                disabled={isWritePending || isConfirming}
                                className="h-12 px-6 bg-emerald-500 text-slate-950 font-bold rounded-2xl hover:bg-emerald-400 active:scale-95 transition-all shadow-lg shadow-emerald-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                {isWritePending || isConfirming ? 'Processando...' : 'Comprar Agora'}
                            </button>
                        )
                    ) : (
                        isOwner ? (
                            <button
                                onClick={handleRelist}
                                disabled={isWritePending || isConfirming}
                                className="h-12 px-6 bg-amber-500 text-slate-950 font-bold rounded-2xl hover:bg-amber-400 active:scale-95 transition-all shadow-lg shadow-amber-500/20"
                            >
                                {isWritePending || isConfirming ? 'Processando...' : 'Relistar'}
                            </button>
                        ) : (
                            <button disabled className="h-12 px-6 bg-slate-700 text-slate-400 font-bold rounded-2xl cursor-not-allowed">
                                Vendido
                            </button>
                        )
                    )}
                </div>

                {/* Seção de Ofertas - Apenas se estiver à venda e não for o dono */}
                {localForSale && !isOwner && (
                    <div className="pt-4 border-t border-white/5">
                        {userOfferIndex !== -1 ? (
                            <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-2xl text-center">
                                <p className="text-amber-400 text-xs font-bold uppercase mb-2">Sua Oferta está Ativa</p>
                                <button
                                    onClick={() => handleWithdrawOffer(userOfferIndex)}
                                    disabled={isWritePending || isConfirming}
                                    className="w-full h-10 px-4 bg-red-500/20 text-red-400 font-bold rounded-xl hover:bg-red-500/30 transition-all border border-red-500/20 disabled:opacity-50"
                                >
                                    {isWritePending || isConfirming ? 'Retirando...' : 'Desistir da Oferta'}
                                </button>
                            </div>
                        ) : (
                            <>
                                <button
                                    onClick={() => setShowOfferInput(!showOfferInput)}
                                    className="w-full h-10 px-4 bg-amber-500/10 text-amber-400 font-bold rounded-xl hover:bg-amber-500/20 transition-all border border-amber-500/20"
                                >
                                    {showOfferInput ? 'Cancelar' : '🤝 Negociar / Fazer Oferta'}
                                </button>

                                {showOfferInput && (
                                    <div className="mt-3 flex gap-2">
                                        <input
                                            type="number"
                                            step="0.01"
                                            placeholder="Valor ETH"
                                            value={offerAmount}
                                            onChange={(e) => setOfferAmount(e.target.value)}
                                            className="flex-1 px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:border-amber-500 text-sm"
                                        />
                                        <button
                                            onClick={handleMakeOffer}
                                            disabled={isWritePending || isConfirming || !offerAmount}
                                            className="px-4 py-2 bg-amber-500 text-slate-950 font-bold rounded-xl hover:bg-amber-400 disabled:opacity-50 text-sm"
                                        >
                                            Ofertar
                                        </button>
                                    </div>
                                )}
                            </>
                        )}
                    </div>
                )}

                {/* Lista de Ofertas (para quem possui o imóvel) */}
                {isOwner && activeOffers.length > 0 && (
                    <div className="pt-4 border-t border-white/5 space-y-3">
                        <p className="text-slate-400 text-sm font-semibold flex items-center gap-2">
                            <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></span>
                            Ofertas Recebidas:
                        </p>
                        <div className="space-y-2 max-h-48 overflow-y-auto pr-2 custom-scrollbar">
                            {activeOffers.map((offer: any, index: number) => (
                                <div key={index} className="flex items-center justify-between p-3 bg-slate-800/50 rounded-xl border border-white/5 hover:border-emerald-500/20 transition-all">
                                    <div>
                                        <p className="text-white font-bold">{formatEther(offer.amount)} ETH</p>
                                        <p className="text-slate-500 text-[10px] font-mono">{offer.buyer.slice(0, 6)}...{offer.buyer.slice(-4)}</p>
                                    </div>
                                    <button
                                        onClick={() => handleAcceptOffer(index)}
                                        disabled={isWritePending || isConfirming}
                                        className="px-3 py-1.5 bg-emerald-500 text-slate-950 font-bold rounded-lg hover:bg-emerald-400 text-xs transition-all disabled:opacity-50"
                                    >
                                        Aceitar
                                    </button>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {writeError && (
                    <p className="text-red-400 text-xs mt-2 p-3 bg-red-500/10 rounded-lg border border-red-500/20">
                        ❌ {translateError(writeError)}
                    </p>
                )}
                {isConfirmed && (
                    <p className="text-emerald-400 text-xs mt-2 p-3 bg-emerald-500/10 rounded-lg border border-emerald-500/20">
                        ✅ Operação confirmada!
                    </p>
                )}
            </div>
        </div>
    );
}
