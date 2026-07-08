module Api.Handler.Framework (getAll, getByCode) where

import Api.Error (internalError, notFound)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)
import Domain.Types (Framework)
import Servant (Handler)
import qualified Service.FrameworkService as Service
import Store.Pool (Pool)

getAll :: Pool -> Handler [Framework]
getAll pool = do
  result <- liftIO (Service.getAll pool)
  either (const (internalError "Database error")) pure result

getByCode :: Pool -> Text -> Handler Framework
getByCode pool code = do
  result <- liftIO (Service.getByCode pool code)
  case result of
    Left _ -> internalError "Database error"
    Right Nothing -> notFound ("Framework not found: " <> code)
    Right (Just fw) -> pure fw
