module Main (main) where

import Api (Api, server)
import Config (Config (..), loadConfig)
import qualified Hasql.Connection as Connection
import Migrate (runMigrations)
import Network.Wai.Handler.Warp (run)
import Servant (Proxy (..), serve)
import Store.Pool (connectionSettings, newPool)
import System.Directory (getCurrentDirectory)
import System.FilePath ((</>))

main :: IO ()
main = do
  cfg <- loadConfig
  putStrLn ("Connecting to database " <> show (cfgDbName cfg) <> " at " <> show (cfgDbHost cfg) <> ":" <> show (cfgDbPort cfg))

  migrationConn <-
    either (\e -> error ("Failed to connect for migrations: " <> show e)) pure
      =<< Connection.acquire (connectionSettings cfg)
  cwd <- getCurrentDirectory
  runMigrations migrationConn (cwd </> "migrations")
  Connection.release migrationConn

  pool <- newPool cfg
  putStrLn ("HaskShield API listening on port " <> show (cfgPort cfg))
  run (cfgPort cfg) (serve (Proxy :: Proxy Api) (server pool cfg))
