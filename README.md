# Otimizacao de Carteira Dow Jones em Haskell

Projeto individual de Programacao Funcional para encontrar, por forca bruta, a carteira com maior Sharpe Ratio entre combinacoes de 25 ou mais das 30 acoes do Dow Jones Industrial Average.

## Requisitos Atendidos

- Dados do segundo semestre de 2025: `01/07/2025` a `31/12/2025`.
- 30 acoes do Dow Jones.
- Combinatoria escolhendo 25 ou mais empresas dentre 30.
- Sorteio parametrizavel de carteiras por combinacao, com padrao de `1.000.000`.
- Carteiras long-only, soma dos pesos igual a `1` e peso maximo de `20%` por ativo.
- Simulacao paralelizada.
- Funcoes financeiras e funcoes avaliadas em paralelo sao puras.
- Implementacao em Haskell para atender o criterio B+.

## Componentes Dow Jones Usados

A lista padrao do projeto para 2025 e:

```text
AAPL, AMGN, AMZN, AXP, BA, CAT, CRM, CSCO, CVX, DIS,
GS, HD, HON, IBM, JNJ, JPM, KO, MCD, MMM, MRK,
MSFT, NKE, NVDA, PG, SHW, TRV, UNH, V, VZ, WMT
```

Esta lista corresponde aos componentes reportados em publicacoes de mercado de julho/dezembro de 2025.

## Formato dos Dados

O programa espera um CSV de precos com a primeira coluna `Date` e as demais colunas com os tickers:

```csv
Date,AAPL,AMGN,AMZN,...
2025-07-01,100.0,101.0,102.0,...
2025-07-02,101.0,101.5,103.0,...
```

O arquivo principal esperado e:

```text
data/prices_2025_h2_real.csv
```

## Como Instalar

Instale GHC e Cabal via GHCup:

```bash
ghcup install ghc
ghcup install cabal
```

Depois, na raiz do projeto:

```bash
cabal build
```

## Como Rodar

```bash
cabal run portfolio-funcional -- \
  --data data/prices_2025_h2_real.csv \
  --output results/teste_rapido.json \
  --choose 25 \
  --simulations 1000 \
  --limit-combinations 10 \
  --chunk-size 2 \
  --mode parallel \
  +RTS -N
```

Execucao com os parametros do projeto:

```bash
cabal run portfolio-funcional -- \
  --data data/prices_2025_h2_real.csv \
  --output results/best_portfolio.json \
  --choose 25 \
  --simulations 1000000 \
  --chunk-size 50 \
  --mode parallel \
  +RTS -N
```

Para comparar com modo sequencial:

```bash
cabal run portfolio-funcional -- \
  --data data/prices_2025_h2_real.csv \
  --output results/sequential_result.json \
  --choose 25 \
  --simulations 1000000 \
  --chunk-size 50 \
  --mode sequential
```

## Parametros

- `--data`: caminho do CSV de precos.
- `--output`: caminho do JSON de resultado.
- `--choose`: quantidade de empresas por carteira.
- `--simulations`: quantidade de carteiras sorteadas por combinacao.
- `--chunk-size`: quantidade de combinacoes por bloco de trabalho.
- `--seed`: semente deterministica para reproducibilidade.
- `--mode`: `parallel` ou `sequential`.
- `--limit-combinations`: limita o numero de combinacoes processadas, util para testes e benchmarks parciais.

## Como Funciona

O programa le os precos, ordena por data, converte precos em retornos diarios e gera combinacoes de 25 ou mais tickers entre os 30 componentes do Dow Jones (o programa avalia todos os tamanhos entre o valor de `--choose` e 30).

Para cada combinacao:

1. Gera carteiras candidatas de forma deterministica a partir de uma semente.
2. Normaliza os pesos para soma `1`.
3. Filtra pesos invalidos, principalmente qualquer ativo acima de `20%`.
4. Calcula retorno anualizado.
5. Calcula matriz de covariancia e volatilidade anualizada.
6. Calcula Sharpe Ratio como `retorno anualizado / volatilidade anualizada`.
7. Guarda a melhor carteira da combinacao.

No final, o programa reduz os melhores resultados parciais e salva a melhor carteira global.

## Programacao Funcional

As funcoes centrais sao puras:

- `pricesToReturns`
- `choose`
- `candidateWeights`
- `validWeights`
- `covarianceMatrix`
- `portfolioReturns`
- `annualizedReturn`
- `annualizedVolatility`
- `evaluateCombination`
- `evaluateChunk`

O IO fica restrito a:

- Ler CSV.
- Parsear argumentos.
- Criar threads.
- Escrever o resultado.

A paralelizacao usa `forkIO` e `MVar` apenas na borda de orquestracao. Cada thread executa `evaluateChunk`, que e uma funcao pura sobre dados imutaveis.

## Resultado

O resultado e salvo em JSON no arquivo especificado pelo parametro `--output`, dentro da pasta `results/`, com o seguinte formato:

```json
{
  "metadata": {
    "dataPath": "data/prices_2025_h2_real.csv",
    "simulations": 1000000,
    "seed": 42,
    "mode": "Parallel",
    "limitCombinations": "Nothing"
  },
  "annualReturn": 0.0,
  "annualVolatility": 0.0,
  "sharpeRatio": 0.0,
  "portfolio": [
    { "ticker": "AAPL", "weight": 0.05 }
  ]
}
```