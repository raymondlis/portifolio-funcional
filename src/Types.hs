module Types
  ( Ticker
  , PriceRow(..)
  , PriceTable(..)
  , Portfolio(..)
  , EvaluatedPortfolio(..)
  , Config(..)
  , Mode(..)
  ) where

import Control.DeepSeq (NFData(..))
import Data.Time (Day)

type Ticker = String

data PriceRow = PriceRow
  { priceDate :: Day
  , priceValues :: [Double]
  } deriving (Eq, Show)

data PriceTable = PriceTable
  { tableTickers :: [Ticker]
  , tableRows :: [PriceRow]
  } deriving (Eq, Show)

data Portfolio = Portfolio
  { portfolioTickers :: [Ticker]
  , portfolioWeights :: [Double]
  } deriving (Eq, Show)

data EvaluatedPortfolio = EvaluatedPortfolio
  { evaluatedPortfolio :: Portfolio
  , annualReturn :: Double
  , annualVolatility :: Double
  , sharpeRatio :: Double
  } deriving (Eq, Show)

data Mode = Sequential | Parallel
  deriving (Eq, Show)

data Config = Config
  { configDataPath :: FilePath
  , configOutputPath :: FilePath
  , configChoose :: Int
  , configSimulations :: Int
  , configChunkSize :: Int
  , configSeed :: Integer
  , configMode :: Mode
  , configLimitCombinations :: Maybe Int
  } deriving (Eq, Show)

instance NFData PriceRow where
  rnf (PriceRow d xs) = rnf d `seq` rnf xs

instance NFData PriceTable where
  rnf (PriceTable ts rows) = rnf ts `seq` rnf rows

instance NFData Portfolio where
  rnf (Portfolio ts ws) = rnf ts `seq` rnf ws

instance NFData EvaluatedPortfolio where
  rnf (EvaluatedPortfolio p ret vol sr) =
    rnf p `seq` rnf ret `seq` rnf vol `seq` rnf sr

