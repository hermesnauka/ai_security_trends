module Store.Pool (Pool, newPool, connectionSettings) where

import Config (Config (..))
import qualified Hasql.Connection.Settings as ConnSettings
import qualified Hasql.Pool as Pool
import qualified Hasql.Pool.Config as PoolConfig

type Pool = Pool.Pool

connectionSettings :: Config -> ConnSettings.Settings
connectionSettings cfg =
  ConnSettings.hostAndPort (cfgDbHost cfg) (fromIntegral (cfgDbPort cfg))
    <> ConnSettings.user (cfgDbUser cfg)
    <> ConnSettings.password (cfgDbPassword cfg)
    <> ConnSettings.dbname (cfgDbName cfg)

newPool :: Config -> IO Pool
newPool cfg =
  Pool.acquire
    ( PoolConfig.settings
        [ PoolConfig.size 10,
          PoolConfig.staticConnectionSettings (connectionSettings cfg)
        ]
    )
