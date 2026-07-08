-- | HTTP-level tests against the real API, run against whatever Postgres
-- the standard DB_* env vars point at (scripts/local-dev-up.sh starts one).
-- Applies migrations itself, so this suite is self-sufficient given a
-- running, reachable database -- it is NOT a mocked/in-memory test.
module ApiSpec (spec) where

import Api (Api, server)
import Config (loadConfig)
import qualified Hasql.Connection as Connection
import Migrate (runMigrations)
import Servant (Proxy (..), serve)
import Store.Pool (connectionSettings, newPool)
import System.Directory (getCurrentDirectory)
import System.FilePath ((</>))
import Test.Hspec
import Test.Hspec.Wai

spec :: Spec
spec = with app $ do
  describe "GET /health" $
    it "responds 200" $
      get "/health" `shouldRespondWith` 200

  describe "GET /api/v1/frameworks" $
    it "responds 200 with the seeded frameworks" $
      get "/api/v1/frameworks" `shouldRespondWith` 200

  describe "GET /api/v1/frameworks/:code" $ do
    it "responds 200 for a seeded framework code" $
      get "/api/v1/frameworks/OWASP_WEB" `shouldRespondWith` 200
    it "responds 404 for an unknown framework code" $
      get "/api/v1/frameworks/NOPE" `shouldRespondWith` 404

  describe "GET /api/v1/threats" $
    it "responds 200" $
      get "/api/v1/threats" `shouldRespondWith` 200

  describe "GET /api/v1/threats/:id" $
    it "responds 404 for a well-formed but nonexistent UUID" $
      get "/api/v1/threats/00000000-0000-0000-0000-000000000000" `shouldRespondWith` 404

  describe "POST /api/v1/auth/login" $
    it "responds 401 for bad credentials" $
      post "/api/v1/auth/login" "{\"username\":\"nope\",\"password\":\"nope\"}" `shouldRespondWith` 401
  where
    app = do
      cfg <- loadConfig
      migrationConn <-
        either (\e -> error ("Failed to connect for migrations: " <> show e)) pure
          =<< Connection.acquire (connectionSettings cfg)
      cwd <- getCurrentDirectory
      runMigrations migrationConn (cwd </> "migrations")
      Connection.release migrationConn
      pool <- newPool cfg
      pure (serve (Proxy :: Proxy Api) (server pool cfg))
