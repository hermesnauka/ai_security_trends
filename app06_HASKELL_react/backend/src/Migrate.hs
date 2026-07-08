-- | Small custom migration runner instead of hasql-th/Flyway. hasql-th needs
-- a live, already-migrated database just to type-check at compile time --
-- a chicken-and-egg problem for a fresh checkout -- so this project applies
-- migrations with plain @hasql@ (no compile-time schema check) and the
-- Store modules use hand-written Encoders\/Decoders instead. See
-- CLAUDE.md "Known deliberate deviations".
module Migrate (runMigrations) where

import Control.Monad (forM_, unless)
import Data.List (sort)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Hasql.Connection as Connection
import qualified Hasql.Decoders as D
import qualified Hasql.Encoders as E
import qualified Hasql.Session as Session
import qualified Hasql.Statement as Statement
import System.Directory (listDirectory)
import System.FilePath ((</>))

ensureTableStatement :: Statement.Statement () ()
ensureTableStatement = Statement.unpreparable sql E.noParams D.noResult
  where
    sql =
      "CREATE TABLE IF NOT EXISTS schema_migrations \
      \(version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())"

isAppliedStatement :: Statement.Statement Text Bool
isAppliedStatement = Statement.unpreparable sql encoder decoder
  where
    sql = "SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $1)"
    encoder = E.param (E.nonNullable E.text)
    decoder = D.singleRow (D.column (D.nonNullable D.bool))

markAppliedStatement :: Statement.Statement Text ()
markAppliedStatement = Statement.unpreparable sql encoder D.noResult
  where
    sql = "INSERT INTO schema_migrations (version) VALUES ($1)"
    encoder = E.param (E.nonNullable E.text)

-- | Apply every @*.sql@ file in @migrationsDir@, in filename order, that
-- isn't already recorded in @schema_migrations@. Idempotent: safe to call on
-- every process start.
runMigrations :: Connection.Connection -> FilePath -> IO ()
runMigrations conn migrationsDir = do
  run (Session.statement () ensureTableStatement)
  files <- sort <$> listDirectory migrationsDir
  forM_ files $ \file -> do
    let version = T.pack file
    applied <- run (Session.statement version isAppliedStatement)
    unless applied $ do
      contents <- TIO.readFile (migrationsDir </> file)
      run (Session.script contents)
      run (Session.statement version markAppliedStatement)
  where
    run session = do
      result <- Connection.use conn session
      either (\e -> error ("Migration failed: " <> show e)) pure result
