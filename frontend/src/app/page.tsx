'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { Marketplace } from '../components/Marketplace';

export default function LandingPage() {
  const { isConnected } = useAccount();

  return (
    <div className="min-h-screen bg-slate-950 text-white selection:bg-emerald-500/30">
      {/* Navigation */}
      <nav className="fixed top-0 w-full z-50 border-b border-white/5 bg-slate-950/50 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 bg-gradient-to-br from-emerald-400 to-cyan-500 rounded-xl flex items-center justify-center shadow-lg shadow-emerald-500/20">
              <span className="font-bold text-slate-950">RWA</span>
            </div>
            <span className="font-bold text-xl tracking-tight">Imob</span>
          </div>

          <div className="flex items-center gap-8">
            <a href="#marketplace" className="text-sm font-medium text-slate-400 hover:text-white transition-colors">Marketplace</a>
            <a href="#" className="text-sm font-medium text-slate-400 hover:text-white transition-colors">Home</a>
            <ConnectButton />
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="pt-32 pb-20 px-6">
        <div className="max-w-7xl mx-auto text-center space-y-8">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold animate-pulse">
            <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
            Imobiliário Blockchain ao Vivo
          </div>

          <h1 className="text-6xl md:text-8xl font-extrabold tracking-tight leading-[1.1]">
            O Futuro do Mercado <br />
            <span className="bg-gradient-to-r from-emerald-400 via-cyan-500 to-blue-600 bg-clip-text text-transparent">
              Imobiliário é On-chain.
            </span>
          </h1>

          <p className="max-w-2xl mx-auto text-xl text-slate-400 leading-relaxed">
            Invista em ativos imobiliários de alta performance com a liquidez e transparência da blockchain. Tokenização RWA de ponta a ponta.
          </p>

          <div className="flex items-center justify-center gap-4 pt-4">
            <a href="#marketplace" className="h-14 px-8 bg-white text-slate-950 font-bold rounded-2xl hover:scale-105 transition-transform flex items-center active:scale-95 shadow-xl shadow-white/10">
              Explorar Marketplace
            </a>
            <a href="#how-it-works" className="h-14 px-8 bg-slate-900 border border-white/10 font-bold rounded-2xl hover:bg-slate-800 transition-colors inline-flex items-center justify-center">
              Como Funciona
            </a>
          </div>
        </div>

        {/* Marketplace Section */}
        <section id="marketplace" className="max-w-7xl mx-auto mt-40">
          <div className="flex items-end justify-between mb-12">
            <div>
              <h2 className="text-4xl font-bold tracking-tight">Marketplace RWA</h2>
              <p className="text-slate-400 mt-2">Ativos tokenizados sob gestão e monitoramento via Ponder.</p>
            </div>
            <div className="h-[1px] flex-1 bg-white/5 mx-10 mb-4 hidden md:block"></div>
          </div>

          <Marketplace />
        </section>

        {/* How It Works Section */}
        <section id="how-it-works" className="max-w-7xl mx-auto mt-32">
          <div className="flex items-end justify-between mb-10">
            <div>
              <h2 className="text-4xl font-bold tracking-tight">Como Funciona</h2>
              <p className="text-slate-400 mt-2">Processo e segurança na compra e venda on-chain.</p>
            </div>
            <div className="h-[1px] flex-1 bg-white/5 mx-10 mb-4 hidden md:block"></div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="p-8 rounded-3xl bg-slate-900/50 border border-white/5 backdrop-blur-sm hover:border-emerald-500/30 transition-all">
              <p className="text-emerald-400 text-xs font-bold uppercase tracking-widest">1. Listagem</p>
              <h3 className="text-2xl font-bold mt-3">Tokenização do imóvel</h3>
              <p className="text-slate-400 mt-3 text-sm leading-relaxed">
                O imóvel é registrado como NFT (ERC-721) com preço, metadata e histórico. A listagem é pública e verificável na blockchain.
              </p>
            </div>
            <div className="p-8 rounded-3xl bg-slate-900/50 border border-white/5 backdrop-blur-sm hover:border-emerald-500/30 transition-all">
              <p className="text-emerald-400 text-xs font-bold uppercase tracking-widest">2. Negociação</p>
              <h3 className="text-2xl font-bold mt-3">Compra direta ou oferta</h3>
              <p className="text-slate-400 mt-3 text-sm leading-relaxed">
                Compradores podem adquirir pelo preço fixo ou enviar ofertas. O vendedor aceita a melhor proposta e a transferência ocorre on-chain.
              </p>
            </div>
            <div className="p-8 rounded-3xl bg-slate-900/50 border border-white/5 backdrop-blur-sm hover:border-emerald-500/30 transition-all">
              <p className="text-emerald-400 text-xs font-bold uppercase tracking-widest">3. Segurança</p>
              <h3 className="text-2xl font-bold mt-3">Liquidação segura</h3>
              <p className="text-slate-400 mt-3 text-sm leading-relaxed">
                O contrato segue padrões OpenZeppelin, evita reentrância e usa o padrão CEI. Pagamentos e transferências são atômicos.
              </p>
            </div>
          </div>

          <div className="mt-10 grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="p-7 rounded-3xl bg-slate-900/30 border border-white/5">
              <h4 className="text-lg font-bold">Transparência e rastreabilidade</h4>
              <p className="text-slate-400 mt-2 text-sm leading-relaxed">
                Todas as operações ficam registradas em eventos e podem ser auditadas em tempo real via indexação do Ponder.
              </p>
            </div>
            <div className="p-7 rounded-3xl bg-slate-900/30 border border-white/5">
              <h4 className="text-lg font-bold">Custódia do usuário</h4>
              <p className="text-slate-400 mt-2 text-sm leading-relaxed">
                Você mantém a custódia da sua carteira. As transações exigem confirmação e não há intermediários.
              </p>
            </div>
          </div>
        </section>

        {/* Stats / Features Grid */}
        <div className="max-w-7xl mx-auto mt-32 grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            { label: 'Volume Total', value: '$12.4M+', desc: 'Indexado via Ponder' },
            { label: 'Propriedades', value: '142', desc: 'Ativos verificados' },
            { label: 'Investidores', value: '1,800+', desc: 'Comunidade Global' },
          ].map((stat, i) => (
            <div key={i} className="p-8 rounded-3xl bg-slate-900/50 border border-white/5 backdrop-blur-sm group hover:border-emerald-500/30 transition-all hover:translate-y-[-4px]">
              <p className="text-slate-500 text-sm font-semibold uppercase tracking-wider">{stat.label}</p>
              <p className="text-4xl font-bold mt-2 text-white group-hover:text-emerald-400 transition-colors">{stat.value}</p>
              <p className="text-slate-400 text-sm mt-1">{stat.desc}</p>
            </div>
          ))}
        </div>
      </main>

      {/* Background Decor */}
      <div className="fixed top-0 left-1/2 -translate-x-1/2 -z-10 w-full h-full max-w-7xl">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-emerald-500/20 blur-[120px] rounded-full"></div>
        <div className="absolute bottom-[20%] right-[-10%] w-[30%] h-[30%] bg-blue-600/20 blur-[100px] rounded-full"></div>
      </div>
    </div>
  );
}
