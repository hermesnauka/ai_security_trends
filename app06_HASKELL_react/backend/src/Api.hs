module Api (Api, server) where

import qualified Api.Handler.Auth as AuthH
import qualified Api.Handler.Framework as FrameworkH
import qualified Api.Handler.Threat as ThreatH
import Config (Config)
import Data.Aeson (Value, object, (.=))
import Data.Text (Text)
import Domain.Types
import Servant
import Store.Pool (Pool)

type FrameworkApi =
  Get '[JSON] [Framework]
    :<|> Capture "code" Text :> Get '[JSON] Framework

type ThreatApi =
  ( QueryParam "frameworkCode" Text
      :> QueryParam "severity" Text
      :> QueryParam "stride" Text
      :> QueryParam "tag" Text
      :> QueryParam "q" Text
      :> QueryParam "page" Int
      :> QueryParam "size" Int
      :> Get '[JSON] (Page ThreatSummary)
  )
    :<|> Capture "id" Text :> Get '[JSON] ThreatDetail

type AuthApi = "login" :> ReqBody '[JSON] LoginRequest :> Post '[JSON] LoginResponse

type V1Api =
  "frameworks" :> FrameworkApi
    :<|> "threats" :> ThreatApi
    :<|> "auth" :> AuthApi

type HealthApi = "health" :> Get '[JSON] Value

type Api = ("api" :> "v1" :> V1Api) :<|> HealthApi

server :: Pool -> Config -> Server Api
server pool cfg = v1Server :<|> healthHandler
  where
    v1Server = frameworkServer :<|> threatServer :<|> authServer
    frameworkServer = FrameworkH.getAll pool :<|> FrameworkH.getByCode pool
    threatServer = ThreatH.search pool :<|> ThreatH.getById pool
    authServer = AuthH.login cfg
    healthHandler = pure (object ["status" .= ("UP" :: Text)])
