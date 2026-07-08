module Domain.Types
  ( Severity (..),
    severityToText,
    severityFromText,
    StrideCategory (..),
    strideToText,
    strideFromText,
    Framework (..),
    ThreatSummary (..),
    ThreatDetail (..),
    Page (..),
    ApiErrorBody (..),
    LoginRequest (..),
    LoginResponse (..),
    uuidToText,
    uuidFromText,
  )
where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (String), object, withText, (.=))
import Data.Text (Text)
import qualified Data.Text as T
import Data.UUID (UUID)
import qualified Data.UUID as UUID
import GHC.Generics (Generic)

-- | Never reachable from 'Nothing'-shaped data: every threat in this Phase-1
-- catalogue has a severity, so this is a plain enum, not a Maybe.
data Severity = Critical | High | Medium | Low | Info
  deriving (Eq, Show, Enum, Bounded)

severityToText :: Severity -> Text
severityToText Critical = "CRITICAL"
severityToText High = "HIGH"
severityToText Medium = "MEDIUM"
severityToText Low = "LOW"
severityToText Info = "INFO"

severityFromText :: Text -> Maybe Severity
severityFromText t = case T.toUpper t of
  "CRITICAL" -> Just Critical
  "HIGH" -> Just High
  "MEDIUM" -> Just Medium
  "LOW" -> Just Low
  "INFO" -> Just Info
  _ -> Nothing

instance ToJSON Severity where
  toJSON = String . severityToText

instance FromJSON Severity where
  parseJSON = withText "Severity" $ \t ->
    maybe (fail ("Invalid severity: " <> T.unpack t)) pure (severityFromText t)

-- | Wire format is a single letter (app01's StrideCategory enum constants
-- literally are S/T/R/I/D/E), but constructors here are spelled out for
-- readability -- 'strideToText'/'strideFromText' are the only place the
-- single-letter wire format is known.
data StrideCategory
  = Spoofing
  | Tampering
  | Repudiation
  | InformationDisclosure
  | DenialOfService
  | ElevationOfPrivilege
  deriving (Eq, Show, Enum, Bounded)

strideToText :: StrideCategory -> Text
strideToText Spoofing = "S"
strideToText Tampering = "T"
strideToText Repudiation = "R"
strideToText InformationDisclosure = "I"
strideToText DenialOfService = "D"
strideToText ElevationOfPrivilege = "E"

strideFromText :: Text -> Maybe StrideCategory
strideFromText t = case T.toUpper t of
  "S" -> Just Spoofing
  "T" -> Just Tampering
  "R" -> Just Repudiation
  "I" -> Just InformationDisclosure
  "D" -> Just DenialOfService
  "E" -> Just ElevationOfPrivilege
  _ -> Nothing

instance ToJSON StrideCategory where
  toJSON = String . strideToText

instance FromJSON StrideCategory where
  parseJSON = withText "StrideCategory" $ \t ->
    maybe (fail ("Invalid STRIDE category: " <> T.unpack t)) pure (strideFromText t)

uuidToText :: UUID -> Text
uuidToText = T.pack . UUID.toString

uuidFromText :: Text -> Maybe UUID
uuidFromText = UUID.fromString . T.unpack

data Framework = Framework
  { frameworkId :: UUID,
    frameworkCode :: Text,
    frameworkName :: Text,
    frameworkVersion :: Text,
    frameworkDescription :: Maybe Text,
    frameworkReferenceUrl :: Maybe Text
  }
  deriving (Eq, Show)

instance ToJSON Framework where
  toJSON f =
    object
      [ "id" .= uuidToText (frameworkId f),
        "code" .= frameworkCode f,
        "name" .= frameworkName f,
        "version" .= frameworkVersion f,
        "description" .= frameworkDescription f,
        "referenceUrl" .= frameworkReferenceUrl f
      ]

data ThreatSummary = ThreatSummary
  { tsId :: UUID,
    tsFrameworkCode :: Text,
    tsCode :: Text,
    tsTitle :: Text,
    tsSeverity :: Severity,
    tsCategory :: Maybe Text,
    tsStride :: [StrideCategory],
    tsTags :: [Text]
  }
  deriving (Eq, Show)

instance ToJSON ThreatSummary where
  toJSON t =
    object
      [ "id" .= uuidToText (tsId t),
        "frameworkCode" .= tsFrameworkCode t,
        "code" .= tsCode t,
        "title" .= tsTitle t,
        "severity" .= tsSeverity t,
        "category" .= tsCategory t,
        "stride" .= tsStride t,
        "tags" .= tsTags t
      ]

data ThreatDetail = ThreatDetail
  { tdId :: UUID,
    tdFrameworkCode :: Text,
    tdFrameworkName :: Text,
    tdCode :: Text,
    tdTitle :: Text,
    tdSeverity :: Severity,
    tdCategory :: Maybe Text,
    tdDescription :: Maybe Text,
    tdAttackVector :: Maybe Text,
    tdAttackSurface :: Maybe Text,
    tdStride :: [StrideCategory],
    tdCveReferences :: [Text],
    tdTags :: [Text]
  }
  deriving (Eq, Show)

instance ToJSON ThreatDetail where
  toJSON t =
    object
      [ "id" .= uuidToText (tdId t),
        "frameworkCode" .= tdFrameworkCode t,
        "frameworkName" .= tdFrameworkName t,
        "code" .= tdCode t,
        "title" .= tdTitle t,
        "severity" .= tdSeverity t,
        "category" .= tdCategory t,
        "description" .= tdDescription t,
        "attackVector" .= tdAttackVector t,
        "attackSurface" .= tdAttackSurface t,
        "stride" .= tdStride t,
        "cveReferences" .= tdCveReferences t,
        "tags" .= tdTags t
      ]

data Page a = Page
  { pageContent :: [a],
    pageTotalElements :: Int,
    pageTotalPages :: Int,
    pageNumber :: Int,
    pageSize :: Int
  }
  deriving (Eq, Show)

instance (ToJSON a) => ToJSON (Page a) where
  toJSON p =
    object
      [ "content" .= pageContent p,
        "totalElements" .= pageTotalElements p,
        "totalPages" .= pageTotalPages p,
        "number" .= pageNumber p,
        "size" .= pageSize p
      ]

data ApiErrorBody = ApiErrorBody
  { errTimestamp :: Text,
    errStatus :: Int,
    errError :: Text,
    errMessage :: Text
  }

instance ToJSON ApiErrorBody where
  toJSON e =
    object
      [ "timestamp" .= errTimestamp e,
        "status" .= errStatus e,
        "error" .= errError e,
        "message" .= errMessage e
      ]

data LoginRequest = LoginRequest
  { username :: Text,
    password :: Text
  }
  deriving (Eq, Show, Generic)

instance FromJSON LoginRequest

data LoginResponse = LoginResponse
  { token :: Text,
    tokenType :: Text,
    role :: Text
  }
  deriving (Eq, Show, Generic)

instance ToJSON LoginResponse
