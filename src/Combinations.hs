module Combinations
  ( choose
  , chunksOf
  ) where

choose :: Int -> [a] -> [[a]]
choose 0 _ = [[]]
choose _ [] = []
choose n (x:xs)
  | n < 0 = []
  | otherwise = map (x:) (choose (n - 1) xs) ++ choose n xs

chunksOf :: Int -> [a] -> [[a]]
chunksOf n _
  | n <= 0 = error "chunksOf precisa de tamanho positivo."
chunksOf _ [] = []
chunksOf n xs =
  let (chunk, rest) = splitAt n xs
  in chunk : chunksOf n rest

