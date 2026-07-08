module Main (main) where

import qualified ApiSpec
import qualified ServiceSpec
import Test.Hspec (hspec)

main :: IO ()
main = hspec $ do
  ServiceSpec.spec
  ApiSpec.spec
