module Report
  ( renderResult
  , writeResult
  ) where

import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory)
import Types (Config(..), EvaluatedPortfolio(..), Portfolio(..))

writeResult :: FilePath -> Config -> EvaluatedPortfolio -> IO ()
writeResult path config result = do
  let dir = takeDirectory path
  if null dir || dir == "."
    then pure ()
    else createDirectoryIfMissing True dir
  writeFile path (renderResult config result)

renderResult :: Config -> EvaluatedPortfolio -> String
renderResult config result =
  unlines
    [ "{"
    , "  \"metadata\": {"
    , "    \"dataPath\": " ++ show (configDataPath config) ++ ","
    , "    \"outputPath\": " ++ show (configOutputPath config) ++ ","
    , "    \"choose\": " ++ show (configChoose config) ++ ","
    , "    \"simulations\": " ++ show (configSimulations config) ++ ","
    , "    \"seed\": " ++ show (configSeed config) ++ ","
    , "    \"mode\": " ++ show (configMode config) ++ ","
    , "    \"limitCombinations\": " ++ show (configLimitCombinations config)
    , "  },"
    , "  \"annualReturn\": " ++ show (annualReturn result) ++ ","
    , "  \"annualVolatility\": " ++ show (annualVolatility result) ++ ","
    , "  \"sharpeRatio\": " ++ show (sharpeRatio result) ++ ","
    , "  \"portfolio\": ["
    , renderWeights (evaluatedPortfolio result)
    , "  ]"
    , "}"
    ]

renderWeights :: Portfolio -> String
renderWeights (Portfolio tickers weights) =
  concat (zipWith renderOne [0 :: Int ..] (zip tickers weights))
  where
    renderOne i (ticker, weight) =
      "    { \"ticker\": " ++ show ticker ++ ", \"weight\": " ++ show weight ++ " }"
        ++ if i == length tickers - 1 then "\n" else ",\n"

