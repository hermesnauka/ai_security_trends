module ServiceSpec (spec) where

import Domain.Types
  ( Page (..),
    Severity (..),
    StrideCategory (..),
    severityFromText,
    severityToText,
    strideFromText,
    strideToText,
  )
import Service.ThreatService (buildPage, maxPageSize, normalizePage, normalizeSize)
import Test.Hspec
import Test.QuickCheck

instance Arbitrary Severity where
  arbitrary = arbitraryBoundedEnum

instance Arbitrary StrideCategory where
  arbitrary = arbitraryBoundedEnum

spec :: Spec
spec = do
  describe "Severity text round-trip" $
    it "every constructor round-trips through severityToText/severityFromText" $
      property $ \s -> severityFromText (severityToText s) == Just (s :: Severity)

  describe "StrideCategory text round-trip" $
    it "every constructor round-trips through strideToText/strideFromText" $
      property $ \s -> strideFromText (strideToText s) == Just (s :: StrideCategory)

  describe "severityFromText" $
    it "is case-insensitive" $
      severityFromText "critical" `shouldBe` Just Critical

  describe "normalizePage" $ do
    it "defaults Nothing to 0" $
      normalizePage Nothing `shouldBe` 0
    it "clamps negative pages to 0" $
      property $ \n -> (n :: Int) < 0 ==> normalizePage (Just n) == 0
    it "passes non-negative pages through unchanged" $
      property $ \n -> (n :: Int) >= 0 ==> normalizePage (Just n) == n

  describe "normalizeSize" $ do
    it "defaults Nothing to 20" $
      normalizeSize Nothing `shouldBe` 20
    it "never returns less than 1" $
      property $ \n -> normalizeSize (Just (n :: Int)) >= 1
    it "never exceeds maxPageSize" $
      property $ \n -> normalizeSize (Just (n :: Int)) <= maxPageSize

  describe "buildPage" $ do
    it "reports zero total pages for zero total elements" $
      pageTotalPages (buildPage ([] :: [Int]) 0 0 20) `shouldBe` 0
    it "computes totalPages as ceil(total / size)" $
      pageTotalPages (buildPage ([] :: [Int]) 45 0 20) `shouldBe` 3
    it "totalPages * size always covers totalElements when size > 0" $
      property $ \total size ->
        (total :: Int) >= 0 && (size :: Int) > 0 && size <= maxPageSize
          ==> let p = buildPage ([] :: [Int]) total 0 size
               in pageTotalPages p * size >= total
