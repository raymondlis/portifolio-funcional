module Simulation
  ( evaluateCombination
  , evaluateChunk
  , validWeights
  ) where

import Data.List (elemIndex, maximumBy)
import Data.Maybe (catMaybes)
import Statistics
  ( annualizedVolatility
  , covarianceMatrix
  , dot
  , meanReturns
  , sharpe
  )
import Types (EvaluatedPortfolio(..), Portfolio(..), PriceRow(..), PriceTable(..), Ticker)
import Weights (candidateWeights)

evaluateChunk :: PriceTable -> Int -> Integer -> [[Ticker]] -> Maybe EvaluatedPortfolio
evaluateChunk table simulations seed combinations =
  bestMaybe (zipWith evaluateOne [0..] combinations)
  where
    evaluateOne offset tickers =
      evaluateCombination table simulations (seed + offset) tickers

evaluateCombination :: PriceTable -> Int -> Integer -> [Ticker] -> Maybe EvaluatedPortfolio
evaluateCombination table simulations seed tickers = do
  indices <- traverse (`elemIndex` tableTickers table) tickers
  let returnRows = selectColumns indices (map priceValues (tableRows table))
      assetMeans = meanReturns returnRows
      cov = covarianceMatrix returnRows
      -- Filtra primeiro para garantir que 'simulations' seja a quantidade de carteiras EFETIVAS
      weights = take simulations $ filter validWeights (candidateWeights seed (length tickers))
      evaluated = map (evaluateWeights tickers assetMeans cov) weights
  bestEvaluated evaluated

evaluateWeights :: [Ticker] -> [Double] -> [[Double]] -> [Double] -> EvaluatedPortfolio
evaluateWeights tickers assetMeans cov weights =
  let ret = dot assetMeans weights * 252
      vol = annualizedVolatility cov weights
      sr = sharpe ret vol
  in EvaluatedPortfolio
      { evaluatedPortfolio = Portfolio tickers weights
      , annualReturn = ret
      , annualVolatility = vol
      , sharpeRatio = sr
      }

validWeights :: [Double] -> Bool
validWeights weights =
  all (>= 0) weights
    && all (<= 0.20 + epsilon) weights
    && abs (sum weights - 1) <= epsilon
  where
    epsilon = 0.000001

selectColumns :: [Int] -> [[Double]] -> [[Double]]
selectColumns indices = map (\row -> map (row !!) indices)

bestMaybe :: [Maybe EvaluatedPortfolio] -> Maybe EvaluatedPortfolio
bestMaybe values =
  bestEvaluated (catMaybes values)

bestEvaluated :: [EvaluatedPortfolio] -> Maybe EvaluatedPortfolio
bestEvaluated [] = Nothing
bestEvaluated xs = Just (maximumBy compareSharpe xs)

compareSharpe :: EvaluatedPortfolio -> EvaluatedPortfolio -> Ordering
compareSharpe a b = compare (sharpeRatio a) (sharpeRatio b)
