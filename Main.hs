module Main where

import           Control.Monad      (forM_, when)
import           Data.List          (maximumBy, intercalate)
import qualified Data.Map.Strict    as Map
import           Data.Map.Strict    (Map)
import           Data.Ord           (comparing)
import           System.Random      (StdGen, newStdGen, randomR)

-- ════════════════════════════════════════════════════════════════
--  TIPOS DE DADOS E AMBIENTE (DETERMINÍSTICO)
-- ════════════════════════════════════════════════════════════════

data Cell = Start | Frozen | Hole | Goal deriving (Eq, Show)

data Action = GoUp | GoDown | GoLeft | GoRight deriving (Eq, Ord, Show, Enum, Bounded)

type Pos = (Int, Int)
type QTable = Map (Pos, Action) Double

gridSize :: Int
gridSize = 4

grid :: [[Cell]]
grid =
  [ [Start,  Frozen, Frozen, Frozen]
  , [Frozen, Hole,   Frozen, Hole  ]
  , [Frozen, Frozen, Frozen, Hole  ]
  , [Hole,   Frozen, Frozen, Goal  ]
  ]

startPos :: Pos
startPos = (0, 0)

cellAt :: Pos -> Cell
cellAt (r, c) = (grid !! r) !! c

isTerminal :: Pos -> Bool
isTerminal pos = let c = cellAt pos in c == Hole || c == Goal

allActions :: [Action]
allActions = [minBound .. maxBound]

clampPos :: Pos -> Pos
clampPos (r, c) = (max 0 (min (gridSize - 1) r), max 0 (min (gridSize - 1) c))

-- Ambiente 100% Determinístico (Sem escorregar)
applyAction :: Pos -> Action -> Pos
applyAction (r, c) GoUp    = clampPos (r - 1, c    )
applyAction (r, c) GoDown  = clampPos (r + 1, c    )
applyAction (r, c) GoLeft  = clampPos (r,     c - 1)
applyAction (r, c) GoRight = clampPos (r,     c + 1)

envStep :: Pos -> Action -> (Pos, Double, Bool)
envStep pos action =
  let newPos = applyAction pos action
      c      = cellAt newPos
      done   = isTerminal newPos
      reward = if c == Goal then 1.0 
               else if c == Hole then -1.0 
               else -0.01
  in (newPos, reward, done)

-- ════════════════════════════════════════════════════════════════
--  ALGORITMO Q-LEARNING
-- ════════════════════════════════════════════════════════════════

getQ :: QTable -> Pos -> Action -> Double
getQ qt pos act = Map.findWithDefault 0.0 (pos, act) qt

maxQValue :: QTable -> Pos -> Double
maxQValue qt pos = maximum [getQ qt pos a | a <- allActions]

bestAction :: QTable -> Pos -> Action
bestAction qt pos = maximumBy (comparing (getQ qt pos)) allActions

selectAction :: QTable -> Pos -> Double -> StdGen -> (Action, StdGen)
selectAction qt pos eps gen =
  let (roll, gen1) = randomR (0.0, 1.0) gen
  in if roll < eps
       then let (idx, gen2) = randomR (0, length allActions - 1) gen1
            in  (allActions !! idx, gen2)
       else (bestAction qt pos, gen1)

qUpdate :: QTable -> Pos -> Action -> Double -> Pos -> Double -> Double -> QTable
qUpdate qt s a reward s' alphaVal gammaVal =
  let oldQ   = getQ qt s a
      target = reward + if isTerminal s' then 0 else gammaVal * maxQValue qt s'
      newQ   = oldQ + alphaVal * (target - oldQ)
  in Map.insert (s, a) newQ qt

runEpisode :: QTable -> Double -> StdGen -> (QTable, StdGen)
runEpisode qt eps gen = loop startPos qt gen 0
  where
    loop pos qt' gen' steps
      | steps >= 100 || isTerminal pos = (qt', gen')
      | otherwise =
          let (act, gen1) = selectAction qt' pos eps gen'
              (newPos, reward, _done) = envStep pos act
              qt'' = qUpdate qt' pos act reward newPos 0.1 0.99
          in loop newPos qt'' gen1 (steps + 1)

-- ════════════════════════════════════════════════════════════════
--  Geração de JSON para Exportação
-- ════════════════════════════════════════════════════════════════

data StepLog = StepLog Pos Action Double Bool
data Phase = Phase String QTable [StepLog]

-- Simula sem atualizar a QTable e grava os passos
simulatePath :: QTable -> [StepLog]
simulatePath qt = loop startPos 0 []
  where
    loop pos steps acc
      | steps >= 25 = reverse acc -- Limite para não travar (loop infinito na simulação)
      | isTerminal pos = reverse acc
      | otherwise =
          let act = bestAction qt pos
              (newPos, reward, done) = envStep pos act
              logStep = StepLog pos act reward done
          in loop newPos (steps + 1) (logStep : acc)

-- Treina e extrai os "Snapshots" das fases
trainAndCapture :: StdGen -> [Phase]
trainAndCapture gen0 =
  let totalEps = 5000
      
      -- Loop de treinamento
      loop qt gen ep phases
        | ep > totalEps = reverse phases
        | otherwise =
            let progress = fromIntegral ep / fromIntegral totalEps
                eps      = max 0.01 (1.0 * (1.0 - progress))
                (qt', gen') = runEpisode qt eps gen
                
                -- Capturar fases
                newPhases = case ep of
                  5   -> Phase "Inicio do Treino (Tentativa e Erro)" qt' (simulatePath qt') : phases
                  35  -> Phase "Meio do Treino (Aprendendo os Caminhos)" qt' (simulatePath qt') : phases
                  5000 -> Phase "Fim do Treino (Caminho Otimo)" qt' (simulatePath qt') : phases
                  _   -> phases

            in loop qt' gen' (ep + 1) newPhases
            
  in loop Map.empty gen0 1 []

-- Helpers para serializar em JSON "na mão"
showJSONStr :: String -> String
showJSONStr s = "\"" ++ s ++ "\""

stepToJSON :: StepLog -> String
stepToJSON (StepLog (r,c) act rew done) = 
  "{ \"pos\": [" ++ show r ++ "," ++ show c ++ "], " ++
  "\"action\": \"" ++ show act ++ "\", " ++
  "\"reward\": " ++ show rew ++ ", " ++
  "\"done\": " ++ (if done then "true" else "false") ++ " }"

policyToJSON :: QTable -> String
policyToJSON qt =
  let rows = for [0..gridSize-1] $ \r ->
               let cols = for [0..gridSize-1] $ \c ->
                            showJSONStr (show (bestAction qt (r, c)))
               in "[" ++ intercalate ", " cols ++ "]"
  in "[" ++ intercalate ", " rows ++ "]"
  where for = flip map

qValuesToJSON :: QTable -> String
qValuesToJSON qt =
  let rows = for [0..gridSize-1] $ \r ->
               let cols = for [0..gridSize-1] $ \c ->
                            let qUp = getQ qt (r,c) GoUp
                                qDn = getQ qt (r,c) GoDown
                                qLf = getQ qt (r,c) GoLeft
                                qRg = getQ qt (r,c) GoRight
                            in "{ \"up\": " ++ show qUp ++ ", \"down\": " ++ show qDn ++ ", \"left\": " ++ show qLf ++ ", \"right\": " ++ show qRg ++ " }"
               in "[" ++ intercalate ", " cols ++ "]"
  in "[" ++ intercalate ", " rows ++ "]"
  where for = flip map

phaseToJSON :: Phase -> String
phaseToJSON (Phase name qt steps) =
  "{ \"name\": " ++ showJSONStr name ++ ", " ++
  "\"policy\": " ++ policyToJSON qt ++ ", " ++
  "\"qValues\": " ++ qValuesToJSON qt ++ ", " ++
  "\"simulation\": [" ++ intercalate ", " (map stepToJSON steps) ++ "] }"

generateDataJS :: [Phase] -> String
generateDataJS phases =
  "const simData = {\n" ++
  "  \"grid\": [\n" ++
  "    [\"Start\",  \"Frozen\", \"Frozen\", \"Frozen\"],\n" ++
  "    [\"Frozen\", \"Hole\",   \"Frozen\", \"Hole\"  ],\n" ++
  "    [\"Frozen\", \"Frozen\", \"Frozen\", \"Hole\"  ],\n" ++
  "    [\"Hole\",   \"Frozen\", \"Frozen\", \"Goal\"  ]\n" ++
  "  ],\n" ++
  "  \"phases\": [\n" ++
  "    " ++ intercalate ",\n    " (map phaseToJSON phases) ++ "\n" ++
  "  ]\n" ++
  "};"

-- ════════════════════════════════════════════════════════════════
--  PROGRAMA PRINCIPAL
-- ════════════════════════════════════════════════════════════════

main :: IO ()
main = do
  putStrLn "Iniciando treinamento deterministico para as 3 fases..."
  gen <- newStdGen
  let phases = trainAndCapture gen
  
  let jsContent = generateDataJS phases
  writeFile "data.js" jsContent
  
  putStrLn "Sucesso! O arquivo 'data.js' foi gerado."
  putStrLn "Agora voce pode abrir o 'index.html' no navegador."
