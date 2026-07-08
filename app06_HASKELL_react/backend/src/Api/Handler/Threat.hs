module Api.Handler.Threat (search, getById) where

import Api.Error (internalError, notFound)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)
import Domain.Types (Page, ThreatDetail, ThreatSummary, uuidFromText)
import Servant (Handler)
import qualified Service.ThreatService as Service
import Store.Pool (Pool)

search ::
  Pool ->
  Maybe Text ->
  Maybe Text ->
  Maybe Text ->
  Maybe Text ->
  Maybe Text ->
  Maybe Int ->
  Maybe Int ->
  Handler (Page ThreatSummary)
search pool frameworkCode severity stride tag q page size = do
  let query = Service.ThreatQuery frameworkCode severity stride tag q page size
  result <- liftIO (Service.search pool query)
  either (const (internalError "Database error")) pure result

getById :: Pool -> Text -> Handler ThreatDetail
getById pool idText =
  case uuidFromText idText of
    Nothing -> notFound ("Threat not found: " <> idText)
    Just tid -> do
      result <- liftIO (Service.getById pool tid)
      case result of
        Left _ -> internalError "Database error"
        Right Nothing -> notFound ("Threat not found: " <> idText)
        Right (Just t) -> pure t
