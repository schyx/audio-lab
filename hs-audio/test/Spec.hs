import Lib (Sound (..), backwards, echo, mix, pan, removeVocals)
import Test.Tasty
import Test.Tasty.HUnit

-- Helper functions for comparing sounds
listEq :: (Fractional a, Ord a) => a -> [a] -> [a] -> Bool
listEq diff xs ys =
  length xs == length ys && all (< diff) (zipWith (\x y -> abs $ x - y) xs ys)

listEqThreshhold :: (Fractional a, Ord a) => [a] -> [a] -> Bool
listEqThreshhold = listEq 1e-4

compareSounds :: Sound -> Sound -> Bool
compareSounds (MkMonoSound r1 s1) (MkMonoSound r2 s2) =
  r1 == r2 && listEqThreshhold s1 s2
compareSounds (MkStereoSound r1 left1 right1) (MkStereoSound r2 left2 right2) =
  r1 == r2 && listEqThreshhold left1 left2 && listEqThreshhold right1 right2
compareSounds _ _ = False

-- Helper function for moving sounds to test output
getTestOutput :: (Show a) => (a -> a -> Bool) -> a -> a -> Assertion
getTestOutput comparison expected result =
  if comparison expected result
    then return ()
    else
      assertFailure $
        "Expected: " ++ show expected ++ ".\nGot: " ++ show result ++ "."

testSounds :: Sound -> Sound -> Assertion
testSounds = getTestOutput compareSounds

-- Tests
main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [unitTests]

unitTests :: TestTree
unitTests =
  testGroup
    "Unit Tests"
    [ testCaseSteps "Backwards mono sounds" $ \_ -> do
        let expected = MkMonoSound 20 [6, 5, 4, 3, 2, 1]
        let result = backwards $ MkMonoSound 20 [1, 2, 3, 4, 5, 6]
        testSounds expected result,
      testCaseSteps "Backwards stereo sounds" $ \_ -> do
        let expected = MkStereoSound 20 [6, 5 .. 1] [12, 11 .. 7]
        let result = backwards $ MkStereoSound 20 [1 .. 6] [7 .. 12]
        testSounds expected result,
      testCaseSteps "Mix different rate mono sounds" $ \_ -> do
        let result = mix (MkMonoSound 30 [1, 2, 3, 4, 5, 6]) (MkMonoSound 20 [1, 2, 3, 4, 5, 6]) 0.5
        case result of
          Nothing -> return ()
          Just res -> assertFailure $ "Expected Nothing, got " ++ show res,
      testCaseSteps "Mix same rate mono sounds" $ \_ -> do
        let expected = MkMonoSound 30 [0.7 + 2.1, 1.4 + 2.4, 2.1 + 2.7, 2.8 + 3.0]
        let result = mix (MkMonoSound 30 [1 .. 6]) (MkMonoSound 30 [7 .. 10]) 0.7
        case result of
          Nothing -> assertFailure "Got Nothing, expected something."
          Just res -> testSounds expected res,
      testCaseSteps "Mix different rate stereo sounds" $ \_ -> do
        let result = mix (MkStereoSound 1 [1 .. 10] [11 .. 20]) (MkStereoSound 2 [21 .. 30] [31 .. 40]) 0.1
        case result of
          Nothing -> return ()
          Just res -> assertFailure $ "Expected Nothing, got " ++ show res,
      testCaseSteps "Mix same rate stereo sounds" $ \_ -> do
        let expected = MkStereoSound 20 [11 .. 20] [12 .. 21]
        let result = mix (MkStereoSound 20 [1 .. 10] [2 .. 11]) (MkStereoSound 20 [21 .. 30] [22 .. 31]) 0.5
        case result of
          Nothing -> assertFailure "Got Nothing, expected something."
          Just res -> testSounds expected res,
      testCaseSteps "Mix mono and stereo sound" $ \_ -> do
        let result1 = mix (MkStereoSound 20 [1 .. 10] [2 .. 11]) (MkMonoSound 20 [3 .. 12]) 0.5
        let result2 = mix (MkMonoSound 20 [3 .. 12]) (MkStereoSound 20 [1 .. 10] [2 .. 11]) 0.5
        case (result1, result2) of
          (Nothing, Nothing) -> return ()
          _ -> assertFailure "Got something, expected Nothing.",
      testCaseSteps "Echo mono sound" $ \_ -> do
        let expected = MkMonoSound 9 [1, 2, 3, 0, 0, 0.7, 1.4, 2.1, 0, 0, 0.49, 0.98, 1.47]
        let result = echo (MkMonoSound 9 [1, 2, 3]) 2 0.6 0.7
        testSounds expected result,
      testCaseSteps "Echo stereo sound" $ \_ -> do
        let expected = MkStereoSound 2 [1.0, 2.7, 4.89, 7.423, 10.1961, 13.13727, 16.196089, 19.3372623, 22.4784356, 25.6196089, 17.7607822, 12.2019555, 8.2531288, 5.4313021, 3.3983754, 1.9176787, 0.823543] [11, 19.7, 26.79, 32.753, 37.9271, 42.54897, 46.784279, 50.749, 53.8901686, 57.0313419, 39.1725152, 26.6136885, 17.7648618, 11.5130351, 7.0791084, 3.9177117, 1.647086]
        let result = echo (MkStereoSound 2 [1 .. 10] [11 .. 20]) 7 0.5 0.7
        testSounds expected result,
      testCaseSteps "Pan mono sound" $ \_ -> do
        let result = pan (MkMonoSound 20 [1 .. 20])
        case result of
          Nothing -> return ()
          Just _ -> assertFailure "Expected Nothing, got something.",
      testCaseSteps "Pan stereo sound" $ \_ -> do
        let expected = MkStereoSound 42 [4, 3 .. 0] [0, 1.5, 1.5, 2.25, 3]
        let result = pan $ MkStereoSound 42 (replicate 5 4) (replicate 2 6 ++ replicate 3 3)
        case result of
          Nothing -> assertFailure "Expected something, got Nothing."
          Just res -> testSounds expected res,
      testCaseSteps "Remove vocals of mono sound" $ \_ -> do
        let result = removeVocals $ MkMonoSound 10 [-5..4]
        case result of
          Nothing -> return ()
          Just _ -> assertFailure "Expected Nothing, got something",
      testCaseSteps "Remove vocals from stereo sound" $ \_ -> do
        let expected = MkMonoSound 30 [-5, 7, -6, 2]
        let result = removeVocals $ MkStereoSound 30 [7, 9, 3, 4] [12, 2, 9, 2]
        case result of
          Nothing -> assertFailure "Expected something, got Nothing."
          Just res -> testSounds expected res
    ]
