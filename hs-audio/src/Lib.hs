module Lib
  ( Sound (..),
    getSound,
    writeSound,
    backwards,
    mix,
    echo,
    pan,
    removeVocals,
  )
where

import Data.WAVE

type Rate = Int
type Sample = Double

data Sound = MkMonoSound Rate [Sample] | MkStereoSound Rate [Sample] [Sample]
  deriving (Show)

getSound :: String -> Bool -> IO Sound
getSound file stereo = do
  WAVE header samples <- getWAVEFile file
  let WAVEHeader chan sr _ _ = header
  let rate = sr
  let left = map (sampleToDouble . head) samples
  let right = map (sampleToDouble . (if chan == 2 then last else head)) samples
  if stereo
    then return $ MkStereoSound rate left right
    else return $ MkMonoSound rate $ zipWith (\a b -> (a + b) / 2) left right

createWave :: Sound -> WAVE
createWave (MkMonoSound rate samples) = WAVE header samps
  where header = WAVEHeader 1 rate 16 $ Just $ length samples
        samps = map (\x -> [doubleToSample x]) samples
createWave (MkStereoSound rate left right) = WAVE header samps
  where header = WAVEHeader 2 rate 16 $ Just $ length left
        samps = zipWith (\a b -> [doubleToSample a, doubleToSample b]) left right

writeSound :: String -> Sound -> IO ()
writeSound file sound = do
  let wave = createWave sound
  putWAVEFile file wave

-- |
-- - Reverse the input sound's samples.
-- - Output a new sound containing the samples of the input sound in reverse order, with the same input rate.
-- -
backwards :: Sound -> Sound
backwards = error "Not yet implemented!"

-- |
-- - Mix the two sounds with given ratio
-- - If the two sounds have different rates, output Nothing
-- -
mix :: Sound -> Sound -> Float -> Maybe Sound
mix = error "Not yet implemented!"

-- |
-- - Echo the given sound
-- - Compute a new signal consisting of several scaled-down and delayed version of the input sound.
-- -
echo :: Sound -> Int -> Float -> Float -> Sound
echo = error "Not yet implemented!"

-- |
-- - If the input is a stereo sound, output Just the panned sound
-- - Otherwise, output Nothing
pan :: Sound -> Maybe Sound
pan = error "Not yet implemented"

-- |
-- - If the input is a stereo sound, output the sound with vocals removed
-- = Otherwise, output Nothing
removeVocals :: Sound -> Maybe Sound
removeVocals = error "Not yet implemented"
