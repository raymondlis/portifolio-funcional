module ParallelEval
  ( bestParallel
  , mapParallel
  ) where

import Control.Concurrent
  ( MVar
  , forkIO
  , getNumCapabilities
  , newEmptyMVar
  , newMVar
  , putMVar
  , takeMVar
  )
import Control.DeepSeq (NFData, force)
import Control.Exception (evaluate)

bestParallel :: NFData b => (b -> b -> Ordering) -> (a -> IO (Maybe b)) -> [a] -> IO (Maybe b)
bestParallel compareBest f xs = do
  caps <- getNumCapabilities
  let workerCount = max 1 caps
  queue <- newMVar xs
  vars <- mapM (const newEmptyMVar) [1 .. workerCount]
  mapM_ (startBestWorker compareBest f queue) vars
  localBests <- mapM takeMVar vars
  pure (bestMaybe compareBest localBests)

mapParallel :: NFData b => (a -> b) -> [a] -> IO [b]
mapParallel f xs = do
  caps <- getNumCapabilities
  let workerCount = max 1 caps
      indexed = zip [0 :: Int ..] xs
      workerInputs = splitRoundRobin workerCount indexed
  vars <- mapM (const newEmptyMVar) workerInputs
  mapM_ (startWorker f) (zip vars workerInputs)
  workerOutputs <- mapM takeMVar vars
  pure (map snd (sortByIndex (concat workerOutputs)))

startWorker :: NFData b => (a -> b) -> (MVar [(Int, b)], [(Int, a)]) -> IO ()
startWorker f (var, input) =
  let run = do
        evaluated <- evaluate (force [(i, f x) | (i, x) <- input])
        putMVar var evaluated
  in do
    _ <- forkIO run
    pure ()

startBestWorker :: NFData b => (b -> b -> Ordering) -> (a -> IO (Maybe b)) -> MVar [a] -> MVar (Maybe b) -> IO ()
startBestWorker compareBest f queue output =
  let run currentBest = do
        task <- takeTask queue
        case task of
          Nothing -> do
            evaluated <- evaluate (force currentBest)
            putMVar output evaluated
          Just x -> do
            res <- f x
            run (bestMaybe compareBest [currentBest, res])
  in do
    _ <- forkIO (run Nothing)
    pure ()

takeTask :: MVar [a] -> IO (Maybe a)
takeTask queue = do
  tasks <- takeMVar queue
  case tasks of
    [] -> do
      putMVar queue []
      pure Nothing
    x:xs -> do
      putMVar queue xs
      pure (Just x)

splitRoundRobin :: Int -> [a] -> [[a]]
splitRoundRobin n xs = [pick r xs | r <- [0 .. n - 1]]
  where
    pick r = map snd . filter (\(i, _) -> i `mod` n == r) . zip [0 :: Int ..]

sortByIndex :: [(Int, a)] -> [(Int, a)]
sortByIndex [] = []
sortByIndex (x:xs) =
  sortByIndex [y | y <- xs, fst y <= fst x]
    ++ [x]
    ++ sortByIndex [y | y <- xs, fst y > fst x]

bestMaybe :: (b -> b -> Ordering) -> [Maybe b] -> Maybe b
bestMaybe compareBest = foldr step Nothing
  where
    step Nothing best = best
    step value Nothing = value
    step (Just value) (Just best) =
      Just (case compareBest value best of
        GT -> value
        _ -> best)
