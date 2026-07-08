module Service.FrameworkService (getAll, getByCode) where

import Data.Text (Text)
import Domain.Types (Framework)
import qualified Hasql.Pool as Pool
import Store.Pool (Pool)
import qualified Store.FrameworkStore as Store

getAll :: Pool -> IO (Either Pool.UsageError [Framework])
getAll = Store.getAll

getByCode :: Pool -> Text -> IO (Either Pool.UsageError (Maybe Framework))
getByCode = Store.getByCode
