module Config (Config (..), loadConfig) where

import Data.Text (Text)
import qualified Data.Text as T
import System.Environment (lookupEnv)
import Text.Read (readMaybe)

data Config = Config
  { cfgDbHost :: Text,
    cfgDbPort :: Int,
    cfgDbName :: Text,
    cfgDbUser :: Text,
    cfgDbPassword :: Text,
    cfgJwtSecret :: Text,
    cfgJwtExpirationMinutes :: Int,
    cfgAdminUsername :: Text,
    cfgAdminPasswordHash :: Text,
    cfgPort :: Int
  }

-- | Mirrors the env vars app01_react's application.yml/local-dev-up.sh
-- already use (DB_*, JWT_SECRET, ADMIN_*) so both backends share one .env.
loadConfig :: IO Config
loadConfig = do
  dbHost <- envText "DB_HOST" "localhost"
  dbPort <- envRead "DB_PORT" 5432
  dbName <- envRequired "DB_NAME"
  dbUser <- envRequired "DB_USER"
  dbPassword <- envRequired "DB_PASSWORD"
  jwtSecret <- envRequired "JWT_SECRET"
  jwtExpirationMinutes <- envRead "JWT_EXPIRATION_MINUTES" 60
  adminUsername <- envRequired "ADMIN_USERNAME"
  adminPasswordHash <- envRequired "ADMIN_PASSWORD_HASH"
  port <- envRead "PORT" 8080
  pure
    Config
      { cfgDbHost = dbHost,
        cfgDbPort = dbPort,
        cfgDbName = dbName,
        cfgDbUser = dbUser,
        cfgDbPassword = dbPassword,
        cfgJwtSecret = jwtSecret,
        cfgJwtExpirationMinutes = jwtExpirationMinutes,
        cfgAdminUsername = adminUsername,
        cfgAdminPasswordHash = adminPasswordHash,
        cfgPort = port
      }
  where
    envText name def = maybe def T.pack <$> lookupEnv name
    envRead name def = maybe def (\v -> maybe def id (readMaybe v)) <$> lookupEnv name
    envRequired name = do
      mv <- lookupEnv name
      case mv of
        Just v -> pure (T.pack v)
        Nothing -> error ("Missing required environment variable: " <> name)
