module Store.FrameworkStore (getAll, getByCode) where

import Data.Text (Text)
import Domain.Types (Framework (..))
import qualified Hasql.Decoders as D
import qualified Hasql.Encoders as E
import qualified Hasql.Pool as Pool
import qualified Hasql.Session as Session
import qualified Hasql.Statement as Statement
import Store.Pool (Pool)

frameworkRow :: D.Row Framework
frameworkRow =
  Framework
    <$> D.column (D.nonNullable D.uuid)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable D.text)

getAllStatement :: Statement.Statement () [Framework]
getAllStatement = Statement.preparable sql E.noParams (D.rowList frameworkRow)
  where
    sql = "SELECT id, code, name, version, description, reference_url FROM framework ORDER BY code"

getByCodeStatement :: Statement.Statement Text (Maybe Framework)
getByCodeStatement = Statement.preparable sql encoder (D.rowMaybe frameworkRow)
  where
    sql = "SELECT id, code, name, version, description, reference_url FROM framework WHERE upper(code) = upper($1)"
    encoder = E.param (E.nonNullable E.text)

getAll :: Pool -> IO (Either Pool.UsageError [Framework])
getAll pool = Pool.use pool (Session.statement () getAllStatement)

getByCode :: Pool -> Text -> IO (Either Pool.UsageError (Maybe Framework))
getByCode pool code = Pool.use pool (Session.statement code getByCodeStatement)
