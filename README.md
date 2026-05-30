# Q-Learning: Frozen Lake em Haskell

https://levy-777.github.io/HaskellQ/

## Descrição

Implementação do algoritmo **Q-Learning** (Aprendizado por Reforço) aplicado ao 
problema do **Frozen Lake** (Lago Congelado) em **Haskell**.

### O Problema

Um agente deve navegar por um lago congelado representado por um grid 4×4:

```
S F F F       S = Início (Start)
F H F H       F = Gelo seguro (Frozen)
F F F H       H = Buraco (Hole) — cair = fim do episódio
H F F G       G = Objetivo (Goal) — recompensa = 1.0
```

O gelo é **escorregadio**: ao tentar se mover em uma direção, há apenas 1/3 de 
chance de ir na direção desejada. O agente pode escorregar para uma das duas 
direções perpendiculares (1/3 de chance para cada).

### O Algoritmo

O **Q-Learning** é um algoritmo de aprendizado por reforço que aprende uma 
**tabela Q** mapeando pares (estado, ação) para valores de qualidade:

```
Q(s,a) ← Q(s,a) + α · [r + γ · max_a' Q(s',a') − Q(s,a)]
```

Onde:
- **α** (alpha) = taxa de aprendizado (0.1)
- **γ** (gamma) = fator de desconto (0.99) 
- **ε** (epsilon) = taxa de exploração (começa em 1.0, decai linearmente)

## Como Compilar e Executar

### Pré-requisitos

- **GHC** (Glasgow Haskell Compiler) — versão 8.0 ou superior
- **Cabal** — gerenciador de pacotes do Haskell

Se você não tem o Haskell instalado, baixe o **GHCup**: https://www.haskell.org/ghcup/

### Compilar e executar

```bash
# Entrar na pasta do projeto
cd haskellQ

# Atualizar dependências e compilar
cabal update
cabal build

# Executar
cabal run frozenlake
```

### Alternativa: compilação direta com GHC

```bash
# Se os pacotes 'containers' e 'random' já estiverem instalados
ghc -O2 Main.hs -o frozenlake
./frozenlake
```

## Saída do Programa

O programa exibe:

1. **Ambiente** — O grid do Frozen Lake com legenda
2. **Hiperparâmetros** — Configuração do Q-Learning
3. **Treinamento** — Treina 20.000 episódios com gelo escorregadio
4. **Estatísticas** — Gráfico de barras com taxa de sucesso por fase
5. **Tabela Q** — Valores aprendidos para cada par (estado, ação)
6. **Política** — Setas indicando a melhor ação em cada posição
7. **Simulação** — 3 execuções do agente treinado (com pausas visuais)
8. **Comparação** — Retreina sem escorregamento para comparar resultados

## Estrutura do Código

O arquivo `Main.hs` está organizado em seções:

| Seção | Descrição |
|-------|-----------|
| **Tipos de Dados** | `Cell`, `Action`, `Pos`, `QTable`, `Config` |
| **Ambiente** | Grid, transições, escorregamento |
| **Q-Learning** | `getQ`, `selectAction`, `qUpdate`, `runEpisode`, `train` |
| **Visualização** | Cores ANSI, grid, política, estatísticas, simulação |
| **Main** | Orquestra toda a demonstração |

## Conceitos Demonstrados

- **Estados**: posições (i,j) no grid 4×4
- **Ações**: GoUp, GoDown, GoLeft, GoRight
- **Recompensas**: +1.0 ao chegar no objetivo, 0.0 caso contrário
- **Política ε-greedy**: balanço entre exploração e explotação
- **Ambiente estocástico**: transições probabilísticas (gelo escorregadio)
- **Convergência**: o agente melhora progressivamente ao longo dos episódios
