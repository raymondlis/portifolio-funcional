module Statistics
  ( annualizedReturn
  , annualizedVolatility
  , covarianceMatrix
  , mean
  , portfolioReturns
  , sharpe
  , dot
  , meanReturns
  , transpose
  ) where

mean :: [Double] -> Double
mean [] = 0
mean xs = sum xs / fromIntegral (length xs)

meanReturns :: [[Double]] -> [Double]
meanReturns rows = map mean (transpose rows)

portfolioReturns :: [[Double]] -> [Double] -> [Double]
portfolioReturns rows weights = map (`dot` weights) rows

annualizedReturn :: [Double] -> Double
annualizedReturn returns = mean returns * 252

annualizedVolatility :: [[Double]] -> [Double] -> Double
annualizedVolatility cov weights =
  sqrt (quadraticForm weights cov) * sqrt 252

sharpe :: Double -> Double -> Double
sharpe ret vol
  | vol <= 0 = negate (1 / 0)
  | otherwise = ret / vol

covarianceMatrix :: [[Double]] -> [[Double]]
covarianceMatrix rows =
  let cols = transpose rows
  in [[covariance a b | b <- cols] | a <- cols]

covariance :: [Double] -> [Double] -> Double
covariance xs ys
  | n <= 1 = 0
  | otherwise = sum (zipWith (*) centeredX centeredY) / fromIntegral (n - 1)
  where
    n = min (length xs) (length ys)
    mx = mean xs
    my = mean ys
    centeredX = map (\x -> x - mx) (take n xs)
    centeredY = map (\y -> y - my) (take n ys)

quadraticForm :: [Double] -> [[Double]] -> Double
quadraticForm weights matrix =
  sum (zipWith (*) weights (map (`dot` weights) matrix))

dot :: [Double] -> [Double] -> Double
dot xs ys = sum (zipWith (*) xs ys)

transpose :: [[a]] -> [[a]]
transpose [] = []
transpose ([]:_) = []
transpose rows = map head rows : transpose (map tail rows)

