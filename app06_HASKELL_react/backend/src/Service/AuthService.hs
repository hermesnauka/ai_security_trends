module Service.AuthService (LoginResult (..), login) where

import qualified Auth.Jwt as Jwt
import Config (Config (..))
import Data.Password.Bcrypt (Bcrypt, PasswordCheck (..), PasswordHash (..), checkPassword, mkPassword)
import Domain.Types (LoginRequest (..), LoginResponse (..))

data LoginResult = LoginSuccess LoginResponse | LoginInvalidCredentials

-- | Checks the submitted credentials against the single configured admin
-- account (dev-only single-admin auth, no user table -- matches
-- app01_react's AuthController exactly, including reusing its bcrypt hash
-- format so ADMIN_PASSWORD_HASH is interoperable between both backends).
login :: Config -> LoginRequest -> IO LoginResult
login cfg req
  | username req /= cfgAdminUsername cfg = pure LoginInvalidCredentials
  | otherwise =
      case checkPassword (mkPassword (password req)) (PasswordHash (cfgAdminPasswordHash cfg) :: PasswordHash Bcrypt) of
        PasswordCheckFail -> pure LoginInvalidCredentials
        PasswordCheckSuccess -> do
          tok <- Jwt.issueToken (cfgJwtSecret cfg) (cfgAdminUsername cfg) "ADMIN" (cfgJwtExpirationMinutes cfg)
          pure (LoginSuccess (LoginResponse tok "Bearer" "ADMIN"))
