module CsvLoader
  ( readPriceTable
  , pricesToReturns
  ) where

import Data.Char (isSpace)
import Data.List (sortOn)
import Data.Time (Day, defaultTimeLocale, parseTimeM)
import Types (PriceRow(..), PriceTable(..))

readPriceTable :: FilePath -> IO PriceTable
readPriceTable path = do
  content <- readFile path
  case lines content of
    [] -> fail "CSV vazio."
    headerLine:rowLines -> do
      let header = map trim (splitComma headerLine)
      case header of
        [] -> fail "CSV sem cabecalho."
        dateColumn:tickers
          | map toLowerAscii dateColumn /= "date" ->
              fail "A primeira coluna do CSV deve ser Date."
          | null tickers ->
              fail "CSV precisa ter pelo menos um ticker alem da coluna Date."
          | otherwise -> do
              rows <- traverse (parsePriceRow (length tickers)) (filter (not . null) rowLines)
              pure PriceTable
                { tableTickers = tickers
                , tableRows = sortOn priceDate rows
                }

parsePriceRow :: Int -> String -> IO PriceRow
parsePriceRow expectedValues line =
  case map trim (splitComma line) of
    [] -> fail "Linha vazia inesperada."
    dateText:valuesText -> do
      day <- parseDay dateText
      values <- traverse parseDouble valuesText
      if length values == expectedValues
        then pure PriceRow { priceDate = day, priceValues = values }
        else fail ("Linha com quantidade incorreta de colunas: " ++ line)

pricesToReturns :: PriceTable -> PriceTable
pricesToReturns PriceTable { tableTickers = tickers, tableRows = rows } =
  PriceTable tickers (zipWith toReturnRow rows (drop 1 rows))
  where
    toReturnRow previous current =
      PriceRow
        { priceDate = priceDate current
        , priceValues = zipWith dailyReturn (priceValues previous) (priceValues current)
        }

    dailyReturn previous current =
      if previous == 0 then 0 else (current / previous) - 1

parseDay :: String -> IO Day
parseDay text =
  case parseTimeM True defaultTimeLocale "%Y-%m-%d" text of
    Just day -> pure day
    Nothing -> fail ("Data invalida, use YYYY-MM-DD: " ++ text)

parseDouble :: String -> IO Double
parseDouble text =
  case reads text of
    [(value, rest)] | all isSpace rest -> pure value
    _ -> fail ("Numero invalido: " ++ text)

splitComma :: String -> [String]
splitComma [] = [""]
splitComma (',':xs) = "" : splitComma xs
splitComma (x:xs) =
  case splitComma xs of
    [] -> [[x]]
    y:ys -> (x:y) : ys

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

toLowerAscii :: Char -> Char
toLowerAscii c
  | c >= 'A' && c <= 'Z' = toEnum (fromEnum c + 32)
  | otherwise = c

