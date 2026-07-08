module Api.Error (notFound, unauthorized, internalError) where

import Control.Monad.IO.Class (liftIO)
import qualified Data.Aeson as Aeson
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format.ISO8601 (iso8601Show)
import Domain.Types (ApiErrorBody (..))
import Network.HTTP.Types.Header (hContentType)
import Servant (Handler, ServerError (..), err401, err404, err500, throwError)

-- | Matches app01_react's ApiExceptionHandler convention:
-- {timestamp, status, error, message}.
mkErrorBody :: Int -> Text -> Text -> IO Aeson.Value
mkErrorBody status label message = do
  now <- getCurrentTime
  pure (Aeson.toJSON (ApiErrorBody (T.pack (iso8601Show now)) status label message))

respond :: ServerError -> Int -> Text -> Text -> Handler a
respond base status label message = do
  body <- liftIO (mkErrorBody status label message)
  throwError base {errBody = Aeson.encode body, errHeaders = [(hContentType, "application/json")]}

notFound :: Text -> Handler a
notFound = respond err404 404 "Not Found"

unauthorized :: Text -> Handler a
unauthorized = respond err401 401 "Unauthorized"

internalError :: Text -> Handler a
internalError = respond err500 500 "Internal Server Error"
