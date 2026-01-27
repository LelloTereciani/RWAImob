/**
 * Traduz mensagens de erro do Web3/Ethereum para português
 */
export function translateError(error: Error | null): string {
    if (!error) return '';

    const message = error.message.toLowerCase();

    // Erros do usuário
    if (message.includes('user rejected') || message.includes('user denied')) {
        return 'Transação rejeitada pelo usuário';
    }

    if (message.includes('insufficient funds')) {
        return 'Saldo insuficiente para completar a transação';
    }

    // Erros do contrato
    if (message.includes('property not for sale')) {
        return 'Propriedade não está à venda';
    }

    if (message.includes('insufficient payment')) {
        return 'Valor enviado é insuficiente';
    }

    if (message.includes('cannot buy own property')) {
        return 'Você não pode comprar sua própria propriedade';
    }

    if (message.includes('not property owner')) {
        return 'Você não é o dono desta propriedade';
    }

    if (message.includes('already for sale')) {
        return 'Propriedade já está à venda';
    }

    if (message.includes('offer not active')) {
        return 'Oferta não está mais ativa';
    }

    if (message.includes('invalid offer index')) {
        return 'Índice de oferta inválido';
    }

    // Erros de rede
    if (message.includes('network') || message.includes('connection')) {
        return 'Erro de conexão com a rede';
    }

    if (message.includes('timeout')) {
        return 'Tempo de espera esgotado';
    }

    // Erros de gas
    if (message.includes('gas')) {
        return 'Erro relacionado ao gas da transação';
    }

    if (message.includes('nonce')) {
        return 'Erro de nonce - tente novamente';
    }

    // Erros genéricos
    if (message.includes('execution reverted')) {
        return 'Transação revertida pelo contrato';
    }

    if (message.includes('invalid address')) {
        return 'Endereço inválido';
    }

    if (message.includes('invalid amount')) {
        return 'Valor inválido';
    }

    // Se não encontrou tradução, retorna a primeira linha do erro original
    return error.message.split('\n')[0];
}
