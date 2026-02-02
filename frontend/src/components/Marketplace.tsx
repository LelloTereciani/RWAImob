'use client';

import { useProperties } from '../hooks/useProperties';
import { PropertyCard } from './PropertyCard';
import { RegisterPropertyModal } from './RegisterPropertyModal';
import { RemovePropertyModal } from './RemovePropertyModal';

export function Marketplace() {
    const { data: properties, isLoading, error } = useProperties();

    if (isLoading) return <div className="text-center py-20 text-slate-500 animate-pulse text-2xl font-bold">Carregando Ativos Disponíveis...</div>;

    if (error) return <div className="text-center py-20 text-red-400">Erro ao carregar marketplace. Certifique-se que o Ponder está rodando.</div>;

    const listedProperties = properties ?? [];

    return (
        <div className="py-10">
            <div className="flex flex-wrap gap-4 mb-10">
                <RegisterPropertyModal />
                <RemovePropertyModal />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                {listedProperties.length > 0 ? (
                    listedProperties.map((property: any) => (
                        <PropertyCard
                            key={property.id}
                            property={property}
                        />
                    ))
                ) : (
                    <div className="col-span-full text-center py-20 bg-slate-900/20 rounded-3xl border border-dashed border-white/10">
                        <p className="text-slate-400 text-lg">Nenhum imóvel disponível no momento.</p>
                        <p className="text-slate-500 text-sm mt-2 font-medium">Use a CLI ou o painel Admin para listar novos ativos.</p>
                    </div>
                )}
            </div>
        </div>
    );
}
