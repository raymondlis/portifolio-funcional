module Main where

import Combinations (choose, chunksOf)
import CsvLoader (pricesToReturns, readPriceTable)
import Data.List (maximumBy)
import Data.Maybe (catMaybes)
import DowJones (dowJonesTickers2025)
import ParallelEval (bestParallel)
import Report (writeResult)
import Simulation (evaluateChunk)
import System.Environment (getArgs)
import System.Exit (die)
import Text.Read (readMaybe)
import Types (Config(..), EvaluatedPortfolio(..), Mode(..))

defaultConfig :: Config
defaultConfig = Config
  { configDataPath = "data/prices_2025_h2.csv"
  , configOutputPath = "results/best_portfolio.json"
  , configChoose = 20
  , configSimulations = 1000000
  , configChunkSize = 50
  , configSeed = 42
  , configMode = Parallel
  , configLimitCombinations = Nothing
  }

-- | Estratégia de execução:
-- 1. Gera todas as combinações (Lazy)
-- 2. Divide em blocos (Chunks) para paralelismo
-- 3. Processa cada bloco em paralelo usando 'parListChunk'
main :: IO ()
main = do
  args <- getArgs
  config <- parseArgs defaultConfig args
  priceTable <- readPriceTable (configDataPath config)
  let returnTable = pricesToReturns priceTable
      allCombinations = [configChoose config .. length dowJonesTickers2025] >>= \n ->
                          choose n dowJonesTickers2025
      combinations = maybe id take (configLimitCombinations config) allCombinations
      chunks = chunksOf (configChunkSize config) combinations
      totalChunks = length chunks
      evaluateIndexed (index, chunk) = do
        let res = evaluateChunk returnTable (configSimulations config)
                  (configSeed config + fromIntegral (index * configChunkSize config))
                  chunk
        putStrLn $ "[" ++ show (index + 1) ++ "/" ++ show totalChunks ++ "] Chunk finalizado"
        return res
  putStrLn ("Modo: " ++ show (configMode config))
  putStrLn ("Combinacoes no escopo desta execucao: " ++ combinationScopeText config)
  putStrLn ("Simulacoes por combinacao: " ++ show (configSimulations config))
  result <- case configMode config of
    Sequential -> bestMaybe <$> mapM evaluateIndexed (zip [0..] chunks)
    Parallel -> bestParallel compareSharpe evaluateIndexed (zip [0..] chunks)
  case result of
    Nothing -> die "Nenhuma carteira valida encontrada."
    Just best -> do
      writeResult (configOutputPath config) config best
      putStrLn ("Resultado salvo em " ++ configOutputPath config)
      putStrLn ("Melhor Sharpe: " ++ show (sharpeRatio best))

bestMaybe :: [Maybe EvaluatedPortfolio] -> Maybe EvaluatedPortfolio
bestMaybe values =
  case catMaybes values of
    [] -> Nothing
    xs -> Just (maximumBy (\a b -> compare (sharpeRatio a) (sharpeRatio b)) xs)

compareSharpe :: EvaluatedPortfolio -> EvaluatedPortfolio -> Ordering
compareSharpe a b = compare (sharpeRatio a) (sharpeRatio b)

combinationScopeText :: Config -> String
combinationScopeText config =
  case configLimitCombinations config of
    Just n -> show n
    Nothing -> "todas as combinacoes 30 choose " ++ show (configChoose config)

parseArgs :: Config -> [String] -> IO Config
parseArgs config [] = pure config
parseArgs _ ("--help":_) = die usage
parseArgs config ("--data":value:rest) =
  parseArgs config { configDataPath = value } rest
parseArgs config ("--output":value:rest) =
  parseArgs config { configOutputPath = value } rest
parseArgs config ("--choose":value:rest) =
  parseInt "--choose" value >>= \n -> parseArgs config { configChoose = n } rest
parseArgs config ("--simulations":value:rest) =
  parseInt "--simulations" value >>= \n -> parseArgs config { configSimulations = n } rest
parseArgs config ("--chunk-size":value:rest) =
  parseInt "--chunk-size" value >>= \n -> parseArgs config { configChunkSize = n } rest
parseArgs config ("--seed":value:rest) =
  parseInteger "--seed" value >>= \n -> parseArgs config { configSeed = n } rest
parseArgs config ("--limit-combinations":value:rest) =
  parseInt "--limit-combinations" value >>= \n ->
    parseArgs config { configLimitCombinations = Just n } rest
parseArgs config ("--mode":value:rest) =
  case value of
    "parallel" -> parseArgs config { configMode = Parallel } rest
    "sequential" -> parseArgs config { configMode = Sequential } rest
    _ -> die "--mode deve ser parallel ou sequential."
parseArgs _ (unknown:_) = die ("Argumento desconhecido: " ++ unknown ++ "\n\n" ++ usage)

parseInt :: String -> String -> IO Int
parseInt name value =
  case readMaybe value of
    Just n | n > 0 -> pure n
    _ -> die (name ++ " precisa ser um inteiro positivo.")

parseInteger :: String -> String -> IO Integer
parseInteger name value =
  case readMaybe value of
    Just n -> pure n
    _ -> die (name ++ " precisa ser um inteiro.")

usage :: String
usage = unlines
  [ "Uso:"
  , "  cabal run portfolio-funcional -- [opcoes] +RTS -N"
  , ""
  , "Opcoes:"
  , "  --data FILE"
  , "  --output FILE"
  , "  --choose N"
  , "  --simulations N"
  , "  --chunk-size N"
  , "  --seed N"
  , "  --mode parallel|sequential"
  , "  --limit-combinations N"
  ]
