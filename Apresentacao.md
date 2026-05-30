# 🧠 Q-Learning: Ensinando uma IA a caminhar no gelo

---

## 🛑 O que é Q-Learning?
É um algoritmo clássico de **Aprendizado por Reforço** (Reinforcement Learning). Ele permite que um agente aprenda a tomar as melhores decisões possíveis em um ambiente, através de tentativa e erro, sem precisar de um modelo prévio de como o ambiente funciona (*model-free*).

---

## ⚙️ Como ele funciona?
O agente interage com o ambiente e recebe **recompensas** ou **penalidades**. Ele atualiza uma tabela (a **Tabela Q**) que guarda o "valor" esperado de tomar uma certa ação em um determinado estado. Com o tempo, essa tabela converge para a política ótima.

**Equação de Bellman (Atualização):**
`Q(estado, ação) = Q_Atual + α * [Recompensa + γ * Max_Q(Próximo_Estado) - Q_Atual]`

---

## 🔑 Principais Conceitos

*   **Estados ($S$):** Onde o agente está. No nosso exemplo, é a coordenada `(x, y)` no lago.
*   **Ações ($A$):** O que o agente pode fazer. Aqui: `Cima, Baixo, Esquerda, Direita`.
*   **Recompensas ($R$):** O retorno imediato. Ex: chegar no objetivo `+1`, cair no buraco `0`.
*   **Função de Valor ($Q$):** O quão "bom" é estar num estado e tomar uma ação específica, considerando o longo prazo.
*   **Política ($\pi$):** A estratégia que o agente usa. Escolher a ação com maior valor Q é a política "Greedy" (Guloso).

---

## ⚖️ Vantagens e Limitações

✅ **Vantagens:**
*   Garante encontrar o caminho ótimo (se houver exploração suficiente).
*   Não precisa de dados de treinamento prévios (aprende do zero).
*   Simples de implementar e entender.

❌ **Limitações:**
*   **Maldição da Dimensionalidade:** Se houver muitos estados (ex: Xadrez), a Tabela Q fica gigantesca e impossível de calcular (aí entra o *Deep Q-Learning*).
*   Demora para convergir em ambientes estocásticos complexos.

---

## 💡 Aplicações Possíveis
1.  **Robótica:** Ensinar robôs a andar ou manipular objetos.
2.  **Games:** Criar NPCs inteligentes ou bots que zeram jogos clássicos.
3.  **Tráfego:** Otimização de semáforos em tempo real.
4.  **Finanças:** Algoritmos de trading baseados em recompensa de lucro.

---

## 🎮 Nosso Exemplo Prático: Frozen Lake (Haskell)

**O Problema:** Um agente precisa atravessar um lago congelado (grid 4x4) do Início (S) até o Objetivo (G). O lago tem Buracos (H), e o gelo é **escorregadio** (estocástico: o agente tenta ir para frente, mas pode escorregar para os lados).

**Como testar:**
O código foi escrito em Haskell funcional. Ele treina o agente por 20.000 episódios e depois mostra:
1. A taxa de sucesso subindo.
2. A política aprendida (qual direção tomar em cada quadrado).
3. Uma simulação ao vivo do agente tentando atravessar o lago!

### Comandos para rodar (na pasta do projeto):
```bash
cabal build
cabal run frozenlake
```
