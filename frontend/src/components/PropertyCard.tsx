'use client';

import { useWriteContract, useWaitForTransactionReceipt, useAccount, useReadContract, useChainId } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { PropertySaleAbi } from '../abis/PropertySaleAbi';
import { useState, useEffect, useRef } from 'react';
import { translateError } from '../utils/errorTranslator';
import { useQueryClient } from '@tanstack/react-query';
import { useAddRecentTransaction } from '@rainbow-me/rainbowkit';

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
    const chainId = useChainId();
    const queryClient = useQueryClient();
    const addRecentTransaction = useAddRecentTransaction();

    // 1. Estados Locais
    const [offerAmount, setOfferAmount] = useState('');
    const [showOfferInput, setShowOfferInput] = useState(false);
    const [pendingAction, setPendingAction] = useState<'buy' | 'relist' | 'delist' | 'offer' | 'accept' | 'withdraw' | 'refund' | null>(null);
    const [relistPrice, setRelistPrice] = useState<string | null>(null);
    const [localUserOffer, setLocalUserOffer] = useState<string | null>(null);
    const [offerGraceUntil, setOfferGraceUntil] = useState<number | null>(null);
    const [localForSale, setLocalForSale] = useState(property.forSale);
    const [localOwner, setLocalOwner] = useState(property.owner);
    const [localPrice, setLocalPrice] = useState(property.price);
    const [showSuccessMessage, setShowSuccessMessage] = useState(false);
    const successTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const pendingActionRef = useRef(pendingAction);
    const offerAmountRef = useRef(offerAmount);
    const relistPriceRef = useRef(relistPrice);
    const handledHashRef = useRef<`0x${string}` | null>(null);

    const sanitizeDecimalInput = (value: string) => {
        const normalized = value.replace(',', '.');
        let result = '';
        let seenDot = false;
        for (const ch of normalized) {
            if (ch >= '0' && ch <= '9') {
                result += ch;
            } else if (ch === '.' && !seenDot) {
                result += ch;
                seenDot = true;
            }
        }
        return result;
    };

    const normalizeDecimalValue = (value: string) => {
        const sanitized = sanitizeDecimalInput(value);
        return sanitized.endsWith('.') ? sanitized.slice(0, -1) : sanitized;
    };

    // 2. Chamadas de Contrato (Leitura)
    const { data: offers, refetch: refetchOffers } = useReadContract({
        address: CONTRACT_ADDRESS,
        abi: PropertySaleAbi,
        functionName: 'getPropertyOffers',
        args: [BigInt(property.id)],
    });

    // 3. Cálculos de Estado Derivado
    const activeOffers = offers ? (offers as any[]).filter((offer: any) => offer.active) : [];
    const userOfferIndex = offers ? (offers as any[]).findIndex((offer: any) => offer.active && address && offer.buyer.toLowerCase() === address.toLowerCase()) : -1;
    const isOwner = address && localOwner.toLowerCase() === address.toLowerCase();

    // 4. Hook de Transação (Escrita)
    const { data: hash, writeContract, isPending: isWritePending, error: writeError } = useWriteContract();
    const [showErrorMessage, setShowErrorMessage] = useState(false);
    const errorTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
        hash,
    });

    // Registrar transação no RainbowKit para atualizar saldo automaticamente
    useEffect(() => {
        if (!hash || !address || !chainId) return;

        let description = 'Transação no marketplace';
        if (pendingAction === 'buy') description = `Compra do imóvel #${property.id}`;
        if (pendingAction === 'offer') description = `Oferta no imóvel #${property.id}`;
        if (pendingAction === 'accept') description = `Aceite de oferta #${property.id}`;
        if (pendingAction === 'withdraw') description = `Retirada de oferta #${property.id}`;
        if (pendingAction === 'relist') description = `Relistagem do imóvel #${property.id}`;
        if (pendingAction === 'delist') description = `Retirada de venda #${property.id}`;
        if (pendingAction === 'refund') description = `Reembolso de oferta #${property.id}`;

        addRecentTransaction({
            hash,
            description,
        });
    }, [hash, pendingAction, property.id, addRecentTransaction, address, chainId]);

    useEffect(() => {
        pendingActionRef.current = pendingAction;
    }, [pendingAction]);

    useEffect(() => {
        offerAmountRef.current = offerAmount;
    }, [offerAmount]);

    useEffect(() => {
        relistPriceRef.current = relistPrice;
    }, [relistPrice]);

    // 5. Efeitos (Sincronização e Atualização Otimista)

    // Sincronizar dados após confirmação da transação
    useEffect(() => {
        if (!isConfirmed || !hash || handledHashRef.current === hash) return;
        handledHashRef.current = hash;

        const action = pendingActionRef.current;
        const relistValue = relistPriceRef.current;
        const offerValue = offerAmountRef.current;

        if (action === 'buy' && address) {
            setLocalOwner(address);
            setLocalForSale(false);
        } else if (action === 'relist' && relistValue) {
            setLocalForSale(true);
            setLocalPrice(relistValue);
        } else if (action === 'delist') {
            setLocalForSale(false);
        } else if (action === 'accept') {
            setLocalForSale(false);
        } else if (action === 'offer') {
            setLocalUserOffer(offerValue);
            setShowOfferInput(false);
        } else if (action === 'withdraw') {
            setLocalUserOffer(null);
        }

        queryClient.invalidateQueries({ queryKey: ['properties'] });
        refetchOffers();

        setTimeout(() => {
            queryClient.invalidateQueries({ queryKey: ['properties'] });
            refetchOffers();
            setPendingAction(null);
            setRelistPrice(null);
            if (action !== 'offer') {
                setOfferAmount('');
            }
        }, 2000);
    }, [isConfirmed, hash, queryClient, address, refetchOffers]);

    // Exibir mensagem de sucesso por 5 segundos após confirmação
    useEffect(() => {
        if (isConfirmed) {
            setShowSuccessMessage(true);
            if (successTimeoutRef.current) {
                clearTimeout(successTimeoutRef.current);
            }
            successTimeoutRef.current = setTimeout(() => {
                setShowSuccessMessage(false);
            }, 5000);
        }

        return () => {
            if (successTimeoutRef.current) {
                clearTimeout(successTimeoutRef.current);
                successTimeoutRef.current = null;
            }
        };
    }, [isConfirmed]);

    useEffect(() => {
        if (writeError) {
            setShowErrorMessage(true);
            if (errorTimeoutRef.current) {
                clearTimeout(errorTimeoutRef.current);
            }
            errorTimeoutRef.current = setTimeout(() => {
                setShowErrorMessage(false);
            }, 5000);
        }

        return () => {
            if (errorTimeoutRef.current) {
                clearTimeout(errorTimeoutRef.current);
                errorTimeoutRef.current = null;
            }
        };
    }, [writeError]);

    useEffect(() => {
        if (!offerGraceUntil) return;
        const delay = offerGraceUntil - Date.now();
        if (delay <= 0) {
            setOfferGraceUntil(null);
            return;
        }
        const timeoutId = setTimeout(() => setOfferGraceUntil(null), delay);
        return () => clearTimeout(timeoutId);
    }, [offerGraceUntil]);

    // Sincronizar estado local com props quando não houver ação pendente
    useEffect(() => {
        if (!pendingAction && !isWritePending && !isConfirming) {
            setLocalForSale(property.forSale);
            setLocalOwner(property.owner);
            setLocalPrice(property.price);

            // Sincronizar valor da oferta ativa do usuário
            if (offers) {
                if (userOfferIndex !== -1) {
                    setLocalUserOffer(formatEther(BigInt((offers as any[])[userOfferIndex].amount)));
                    setOfferGraceUntil(null);
                } else if (!localUserOffer) {
                    setLocalUserOffer(null);
                }
            }
        }
    }, [property.forSale, property.owner, property.price, pendingAction, isWritePending, isConfirming, userOfferIndex, offers, localUserOffer]);

    useEffect(() => {
        if (!offers || userOfferIndex !== -1) return;
        const graceActive = offerGraceUntil && offerGraceUntil > Date.now();
        if (!graceActive && pendingAction !== 'offer' && !isWritePending && !isConfirming) {
            setLocalUserOffer(null);
        }
    }, [offers, userOfferIndex, offerGraceUntil, pendingAction, isWritePending, isConfirming]);

    useEffect(() => {
        if (writeError && pendingAction === 'offer') {
            setLocalUserOffer(null);
            setShowOfferInput(true);
        }
    }, [writeError, pendingAction]);

    // 6. Handlers de Ação
    const handleBuy = () => {
        if (!address) {
            alert("Por favor, conecte sua carteira primeiro");
            return;
        }
        if (isOwner) {
            alert("Você já é o dono deste imóvel!");
            return;
        }
        const priceToPay = BigInt(localPrice.toString());
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
        const normalizedAmount = normalizeDecimalValue(offerAmount);
        if (!normalizedAmount || parseFloat(normalizedAmount) <= 0) {
            alert("Digite um valor válido para a oferta");
            return;
        }
        setPendingAction('offer');
        setLocalUserOffer(normalizedAmount);
        setOfferGraceUntil(Date.now() + 15000);
        setShowOfferInput(false);
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'makeOffer',
            args: [BigInt(property.id)],
            value: parseEther(normalizedAmount),
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
        setOfferGraceUntil(null);
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'withdrawOffer',
            args: [BigInt(property.id), BigInt(offerIndex)],
        });
    };

    const handleRelist = () => {
        const newPrice = prompt("Digite o novo preço em ETH:", formatEther(BigInt(localPrice)));
        const normalizedPrice = newPrice ? normalizeDecimalValue(newPrice) : '';
        if (!normalizedPrice || isNaN(parseFloat(normalizedPrice))) return;

        const priceInWei = parseEther(normalizedPrice).toString();
        setRelistPrice(priceInWei);
        setPendingAction('relist');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'relistProperty',
            args: [BigInt(property.id), BigInt(priceInWei)],
        });
    };

    const handleDelist = () => {
        setPendingAction('delist');
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'delistProperty',
            args: [BigInt(property.id)],
        });
    };

    const handleRefundOffer = (offerIndex: number) => {
        setPendingAction('refund');
        setOfferGraceUntil(null);
        writeContract({
            address: CONTRACT_ADDRESS,
            abi: PropertySaleAbi,
            functionName: 'refundOffer',
            args: [BigInt(property.id), BigInt(offerIndex)],
        });
    };

    // 7. Renderização
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
                            <button
                                onClick={handleDelist}
                                disabled={isWritePending || isConfirming}
                                className="h-12 px-6 bg-slate-700 text-slate-200 font-bold rounded-2xl hover:bg-slate-600 active:scale-95 transition-all shadow-lg shadow-slate-700/20 disabled:opacity-50"
                            >
                                {isWritePending || isConfirming ? 'Processando...' : 'Retirar da venda'}
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

                {/* Seção de Ofertas - Sempre que estiver à venda */}
                {localForSale && (
                    <div className="pt-4 border-t border-white/5">
                        {isOwner ? (
                            <button
                                disabled
                                className="w-full h-10 px-4 bg-slate-800 text-slate-500 font-bold rounded-xl border border-white/5 cursor-not-allowed"
                            >
                                Ofertas disponíveis para compradores
                            </button>
                        ) : userOfferIndex !== -1 || localUserOffer ? (
                            <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-2xl text-center">
                                <p className="text-amber-400 text-xs font-bold uppercase mb-1">Sua Oferta está Ativa</p>
                                <p className="text-white font-black text-lg mb-2">
                                    {localUserOffer ? localUserOffer : (offers && userOfferIndex !== -1 ? formatEther(BigInt((offers as any[])[userOfferIndex].amount)) : '...')} ETH
                                </p>
                                <button
                                    onClick={() => handleWithdrawOffer(userOfferIndex)}
                                    disabled={isWritePending || isConfirming}
                                    className="w-full h-10 px-4 bg-red-500/20 text-red-400 font-bold rounded-xl hover:bg-red-500/30 transition-all border border-red-500/20 disabled:opacity-50"
                                >
                                    {isWritePending || isConfirming && pendingAction === 'withdraw' ? 'Retirando...' : 'Desistir da Oferta'}
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
                                            type="text"
                                            inputMode="decimal"
                                            step="0.01"
                                            placeholder="Valor ETH"
                                            value={offerAmount}
                                            onChange={(e) => setOfferAmount(sanitizeDecimalInput(e.target.value))}
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
                                    <div className="flex items-center gap-2">
                                        <button
                                            onClick={() => handleAcceptOffer(index)}
                                            disabled={isWritePending || isConfirming}
                                            className="px-3 py-1.5 bg-emerald-500 text-slate-950 font-bold rounded-lg hover:bg-emerald-400 text-xs transition-all disabled:opacity-50"
                                        >
                                            Aceitar
                                        </button>
                                        <button
                                            onClick={() => handleRefundOffer(index)}
                                            disabled={isWritePending || isConfirming}
                                            className="px-3 py-1.5 bg-red-500/20 text-red-300 font-bold rounded-lg hover:bg-red-500/30 text-xs transition-all border border-red-500/20 disabled:opacity-50"
                                        >
                                            Rejeitar
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {/* Feedback de Erro */}
                {writeError && showErrorMessage && (
                    <div className="mt-4 p-4 bg-red-500/10 border border-red-500/20 rounded-[1.5rem] text-red-400 text-[11px] leading-relaxed">
                        <span className="font-bold uppercase block mb-1 font-mono">Erro na Transação</span>
                        {translateError(writeError)}
                    </div>
                )}

                {/* Feedback de Sucesso */}
                {showSuccessMessage && (
                    <div className="mt-4 p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-[1.5rem] text-emerald-400 text-[11px] leading-relaxed animate-pulse">
                        <span className="font-bold uppercase block mb-1 font-mono">Sucesso</span>
                        Operação finalizada e registrada na blockchain.
                    </div>
                )}
            </div>
        </div>
    );
}
