-- | Minimal hand-rolled HS256 JWT: sign a subject + role claim, verify a
-- compact token. Deliberately not using the @jose@ package -- its API is
-- polymorphic over MonadRandom\/MonadError\/MonadTime and genuinely fiddly
-- for a "sign one HS256 token" use case, which is unnecessary build risk on
-- a freshly-installed toolchain. HS256 with a shared secret is what
-- app01_react's JwtService actually does (@Keys.hmacShaKeyFor@), so this
-- matches the real contract, not the RS256 described in PLAN.md's D-04.
module Auth.Jwt
  ( Claims (..),
    issueToken,
    verifyToken,
  )
where

import qualified Data.Aeson as Aeson
import Data.Aeson ((.:), (.=))
import Data.ByteArray (convert)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base64.URL as B64URL
import qualified Data.ByteString.Char8 as BSC
import qualified Data.ByteString.Lazy as BSL
import Crypto.Hash.Algorithms (SHA256 (..))
import Crypto.MAC.HMAC (HMAC, hmac, hmacGetDigest)
import Data.Text (Text)
import qualified Data.Text.Encoding as TE
import Data.Time.Clock.POSIX (getPOSIXTime)

data Claims = Claims
  { claimsSubject :: Text,
    claimsRole :: Text,
    claimsExpiresAt :: Int
  }
  deriving (Eq, Show)

instance Aeson.ToJSON Claims where
  toJSON c =
    Aeson.object
      [ "sub" .= claimsSubject c,
        "role" .= claimsRole c,
        "exp" .= claimsExpiresAt c
      ]

instance Aeson.FromJSON Claims where
  parseJSON = Aeson.withObject "Claims" $ \o ->
    Claims <$> o .: "sub" <*> o .: "role" <*> o .: "exp"

-- | base64url with padding stripped, per the JWS compact serialization spec.
b64urlEncode :: BS.ByteString -> BS.ByteString
b64urlEncode = BS.filter (/= 61) . B64URL.encode

-- | Re-add '=' padding before decoding: we stripped it on encode, and this
-- library's decoder expects properly padded input.
b64urlDecode :: BS.ByteString -> Either String BS.ByteString
b64urlDecode bs = B64URL.decode (bs <> BS.replicate padLen 61)
  where
    padLen = (4 - BS.length bs `mod` 4) `mod` 4

headerSegment :: BS.ByteString
headerSegment =
  b64urlEncode (BSL.toStrict (Aeson.encode (Aeson.object ["alg" .= ("HS256" :: Text), "typ" .= ("JWT" :: Text)])))

sign :: Text -> BS.ByteString -> BS.ByteString
sign secret signingInput =
  b64urlEncode (convert (hmacGetDigest (hmac (TE.encodeUtf8 secret) signingInput :: HMAC SHA256)))

-- | Issue a compact JWT for the given subject/role, expiring
-- @expirationMinutes@ from now.
issueToken :: Text -> Text -> Text -> Int -> IO Text
issueToken secret subject userRole expirationMinutes = do
  now <- round <$> getPOSIXTime
  let expiresAt = now + expirationMinutes * 60
      payloadSegment = b64urlEncode (BSL.toStrict (Aeson.encode (Claims subject userRole expiresAt)))
      signingInput = headerSegment <> "." <> payloadSegment
      signature = sign secret signingInput
  pure (TE.decodeUtf8 (signingInput <> "." <> signature))

-- | Verify a compact JWT's signature and expiry, returning its claims if valid.
verifyToken :: Text -> Text -> IO (Maybe Claims)
verifyToken secret tokenText =
  case BSC.split '.' (TE.encodeUtf8 tokenText) of
    [h, p, s]
      | s == sign secret (h <> "." <> p) -> do
          now <- round <$> getPOSIXTime
          pure $ do
            payloadBytes <- either (const Nothing) Just (b64urlDecode p)
            claims <- Aeson.decodeStrict payloadBytes
            if claimsExpiresAt claims > now then Just claims else Nothing
    _ -> pure Nothing
