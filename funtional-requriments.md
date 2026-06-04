Requisitos do App — Viagem Surpresa
Visão Geral

Aplicativo mobile multiplataforma desenvolvido em Flutter com foco em experiência emocional e visual para acompanhamento de uma viagem em casal.

O app será centrado em uma experiência offline-first, alimentada inicialmente por arquivos JSON locais, permitindo evolução futura para backend/API.

A aplicação terá 3 abas principais:

Timeline da viagem (principal)
Checklist editável
Controle financeiro

A navegação deve ser simples, fluida e visualmente elegante, com forte apelo emocional e multimídia.

Estrutura Principal de Navegação
Navegação inferior com 3 abas
Aba central (principal)
Timeline

Deve ficar centralizada na Bottom Navigation.

Essa será a experiência principal do aplicativo.

Aba esquerda
Checklist

Lista editável de itens da viagem.

Aba direita
Financeiro

Controle financeiro completo da viagem.

1. Aba Timeline (Principal)
Objetivo

Apresentar toda a viagem em formato de linha do tempo interativa e emocional.

A timeline representa:

planejamento
momentos
experiências
memórias
Estrutura da Timeline

A timeline será composta por etapas/eventos ordenados cronologicamente.

Cada etapa pode conter:

título
descrição
horário/data
localização
1 ou N fotos
emojis decorativos
link de música Spotify
observações
categorias
marcador visual de status
Layout da Timeline
Estrutura visual

Cada item da timeline deve possuir:

indicador visual da linha do tempo
card expandível
área multimídia
identidade visual emocional
Conteúdo de uma etapa
Campos obrigatórios
título
data/hora
Campos opcionais
descrição
lista de fotos
emojis
música Spotify
localização
observações
tags
Fotos

Cada etapa deve suportar:

1 ou múltiplas fotos
grid adaptável
visualização fullscreen
emojis sobrepostos nas imagens
legenda opcional
Emojis

Os emojis podem ser:

decorativos
sentimentais
indicadores de humor

Exemplos:

❤️
✈️
🍷
🌅
📍

Os emojis poderão:

aparecer no card
aparecer sobre fotos
aparecer como destaque da etapa
Integração Spotify

Cada etapa poderá possuir:

link Spotify
preview visual da música
botão “abrir no Spotify”

Objetivo:

associar músicas a momentos da viagem
Finalização da Timeline

Ao concluir a viagem, o usuário poderá:

Exportar a timeline completa

Formato esperado:

PDF premium
álbum digital
storytelling visual

O export deve incluir:

fotos
emojis
textos
músicas referenciadas
datas
layout estilizado

Objetivo:

gerar uma recordação permanente da viagem
2. Aba Checklist
Objetivo

Gerenciar itens necessários para a viagem.

Funcionalidades
Checklist editável

Usuário poderá:

criar itens
editar itens
remover itens
marcar como concluído
Categorias

Exemplos:

documentos
roupas
higiene
eletrônicos
remédios
extras
Funcionalidades adicionais
Progresso visual

Mostrar:

percentual concluído
quantidade pendente
Ordenação

Permitir:

ordenar por categoria
ordenar por status
reorder manual
Persistência

Os dados devem ser:

persistidos localmente
atualizados em tempo real
3. Aba Financeiro
Objetivo

Permitir controle financeiro completo da viagem.

Estrutura principal
Saldo inicial

Usuário informa:

valor de entrada/orçamento inicial da viagem

Exemplo:

R$ 5.000,00
Controle de gastos

Usuário poderá registrar:

valor
categoria
descrição
data
observações
Categorias financeiras

Exemplos:

hospedagem
alimentação
transporte
passeios
compras
emergência
outros
Comportamento do saldo

O sistema deve:

debitar automaticamente os gastos
atualizar saldo restante em tempo real
Dashboard financeiro

A aba deve possuir uma mini dashboard com:

Indicadores principais
saldo inicial
total gasto
saldo atual
Gráficos
Gastos por categoria

Sugestões:

gráfico pizza
barras horizontais
cards percentuais
Histórico financeiro

Lista cronológica contendo:

categoria
valor
data
descrição
Experiência Visual
Direção visual

O aplicativo deve transmitir:

romantismo
elegância
sensação de memória afetiva
Estilo sugerido

Mistura de:

diário de viagem
scrapbook
boarding pass
álbum emocional
Requisitos Técnicos
Plataforma
Android
iOS
Stack sugerida

Frontend:

Flutter

Gerenciamento de estado:

Riverpod

Persistência local:

Isar ou Hive

Modelagem:

freezed
json_serializable

Animações:

LottieFiles
Rive

Gráficos:

fl_chart

Exportação PDF:

pdf
printing
Estrutura de Dados
Modelo orientado a blocos

A timeline deverá utilizar estrutura dinâmica baseada em JSON para permitir expansão futura.

Exemplo de etapa
{
  "id": "event_001",
  "title": "Jantar Especial",
  "dateTime": "2026-07-15T20:00:00",
  "description": "Primeira noite da viagem",
  "emojis": ["❤️", "🍷"],
  "spotifyUrl": "https://open.spotify.com/...",
  "photos": [
    {
      "url": "assets/photos/jantar_1.jpg",
      "emojiOverlay": "❤️"
    }
  ],
  "location": {
    "name": "Restaurante XYZ",
    "lat": -19.9,
    "lng": -43.9
  }
}
Requisitos Futuros (não obrigatórios na V1)
sincronização cloud
compartilhamento em tempo real
múltiplas viagens
autenticação
mapas offline
QR Codes de desbloqueio
revelação gradual de eventos
integração com calendário
geração automática de vídeo da viagem
IA para resumo da viagem
cápsula do tempo digital