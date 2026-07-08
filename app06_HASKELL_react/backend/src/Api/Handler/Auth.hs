module Api.Handler.Auth (login) where

import Api.Error (unauthorized)
import Config (Config)
import Control.Monad.IO.Class (liftIO)
import Domain.Types (LoginRequest, LoginResponse)
import Servant (Handler)
import qualified Service.AuthService as Service

login :: Config -> LoginRequest -> Handler LoginResponse
login cfg req = do
  result <- liftIO (Service.login cfg req)
  case result of
    Service.LoginSuccess resp -> pure resp
    Service.LoginInvalidCredentials -> unauthorized "Invalid username or password"
