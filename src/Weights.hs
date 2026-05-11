module Weights
  ( Seed
  , candidateWeights
  ) where

type Seed = Integer

candidateWeights :: Seed -> Int -> [[Double]]
candidateWeights seed assets =
  map normalize (groupsOf assets (randomDoubles seed))

normalize :: [Double] -> [Double]
normalize xs =
  let total = sum xs
  in if total == 0 then replicate (length xs) 0 else map (/ total) xs

randomDoubles :: Seed -> [Double]
randomDoubles seed =
  map toUnit (tail (iterate lcg (positiveSeed seed)))

positiveSeed :: Seed -> Seed
positiveSeed seed = abs seed + 1

lcg :: Seed -> Seed
lcg x = (1103515245 * x + 12345) `mod` 2147483648

toUnit :: Seed -> Double
toUnit x =
  let scaled = fromIntegral (x `mod` 1000000) / 1000000
  in 0.000001 + scaled

groupsOf :: Int -> [a] -> [[a]]
groupsOf n _
  | n <= 0 = []
groupsOf n xs =
  let (group, rest) = splitAt n xs
  in group : groupsOf n rest

