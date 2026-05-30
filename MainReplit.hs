module Main where

import Control.Monad (forM_)
import Data.List (maximumBy)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Ord (comparing)
import System.Random (StdGen, newStdGen, randomR)

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
      -- Pequena penalidade de -0.01 por passo para incentivar caminhos curtos e evitar que ele fique preso na parede
      -- Recompensa +1.0 no objetivo, -1.0 no buraco
      reward = if c == Goal then 1.0 
               else if c == Hole then -1.0 
               else -0.01
  in (newPos, reward, done)

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
              (newPos, reward, _) = envStep pos act
              qt'' = qUpdate qt' pos act reward newPos 0.1 0.99
          in loop newPos qt'' gen1 (steps + 1)

train :: StdGen -> [(String, QTable)]
train gen0 =
  let totalEps = 5000  -- Aumentado para dar mais tempo de aprendizado
      loop qt gen ep phases
        | ep > totalEps = reverse phases
        | otherwise =
            let progress = fromIntegral ep / fromIntegral totalEps
                eps      = max 0.01 (1.0 * (1.0 - progress))
                (qt', gen') = runEpisode qt eps gen
                
                newPhases = case ep of
                  5   -> ("FASE 1: Inicio do Treino (Episodio 5)", qt') : phases
                  35  -> ("FASE 2: Meio do Treino (Episodio 35)", qt') : phases
                  5000 -> ("FASE 3: Fim do Treino (Episodio 5000)", qt') : phases
                  _   -> phases

            in loop qt' gen' (ep + 1) newPhases
            
  in loop Map.empty gen0 1 []

actionArrow :: Action -> String
actionArrow GoUp    = "^"
actionArrow GoDown  = "v"
actionArrow GoLeft  = "<"
actionArrow GoRight = ">"

printPolicy :: QTable -> IO ()
printPolicy qt = do
  putStrLn "    +---+---+---+---+"
  forM_ [0 .. gridSize - 1] $ \r -> do
    putStr "    |"
    forM_ [0 .. gridSize - 1] $ \c -> do
      let pos = (r, c)
          cell = cellAt pos
      if cell == Hole then putStr " H |"
      else if cell == Goal then putStr " G |"
      else putStr $ " " ++ actionArrow (bestAction qt pos) ++ " |"
    putStrLn "\n    +---+---+---+---+"

printGrid :: Pos -> IO ()
printGrid agentPos = do
  putStrLn "    +---+---+---+---+"
  forM_ [0 .. gridSize - 1] $ \r -> do
    putStr "    |"
    forM_ [0 .. gridSize - 1] $ \c -> do
      let pos = (r, c)
          cell = cellAt pos
      if pos == agentPos
        then putStr " # |"
        else if cell == Hole then putStr " H |"
        else if cell == Goal then putStr " G |"
        else putStr " . |"
    putStrLn "\n    +---+---+---+---+"

simulate :: QTable -> IO ()
simulate qt = loop startPos 0
  where
    loop pos steps = do
      putStrLn $ "\n  Passo " ++ show steps
      printGrid pos
      if isTerminal pos
         then if cellAt pos == Goal
                 then putStrLn "  >>> OBJETIVO ALCANCADO! Vitoria! <<<"
                 else putStrLn "  >>> CAIU NO BURACO! Derrota! <<<"
         else if steps >= 15
                 then putStrLn "  >>> FICOU ANDANDO EM CIRCULOS (Estourou o limite de passos) <<<"
                 else do
                   let act = bestAction qt pos
                   putStrLn $ "  Decisao tomada: " ++ show act
                   let (newPos, _, _) = envStep pos act
                   loop newPos (steps + 1)

main :: IO ()
main = do
  putStrLn "Iniciando treinamento do Q-Learning...\n"
  gen <- newStdGen
  let phases = train gen
  
  forM_ phases $ \(title, qt) -> do
    putStrLn "=========================================================="
    putStrLn $ " " ++ title
    putStrLn "=========================================================="
    putStrLn "\nA MATRIZ DE DECISOES (O que o robo acha melhor fazer):"
    printPolicy qt
    putStrLn "\nSIMULACAO PRATICA (O robo tentando andar com esse cerebro):"
    simulate qt
    putStrLn "\n"
    
  putStrLn "Treinamento concluido!"
