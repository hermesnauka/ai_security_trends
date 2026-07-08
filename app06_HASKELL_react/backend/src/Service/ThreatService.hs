module Service.ThreatService
  ( ThreatQuery (..),
    defaultPageSize,
    maxPageSize,
    normalizePage,
    normalizeSize,
    buildPage,
    search,
    getById,
  )
where

import Data.Text (Text)
import Data.UUID (UUID)
import Domain.Types (Page (..), ThreatDetail, ThreatSummary)
import qualified Hasql.Pool as Pool
import Store.Pool (Pool)
import qualified Store.ThreatStore as Store

data ThreatQuery = ThreatQuery
  { tqFrameworkCode :: Maybe Text,
    tqSeverity :: Maybe Text,
    tqStride :: Maybe Text,
    tqTag :: Maybe Text,
    tqQ :: Maybe Text,
    tqPage :: Maybe Int,
    tqSize :: Maybe Int
  }

defaultPageSize :: Int
defaultPageSize = 20

-- | Caps ?size= so a careless or malicious request can't force an unbounded
-- table scan; app01 has no such cap (Spring Data's default is unbounded).
maxPageSize :: Int
maxPageSize = 200

-- | Mirrors Spring Data's behaviour: negative/missing page clamps to 0.
normalizePage :: Maybe Int -> Int
normalizePage = max 0 . maybe 0 id

normalizeSize :: Maybe Int -> Int
normalizeSize = max 1 . min maxPageSize . maybe defaultPageSize id

buildPage :: [a] -> Int -> Int -> Int -> Page a
buildPage items total page size =
  Page
    { pageContent = items,
      pageTotalElements = total,
      pageTotalPages = if size <= 0 then 0 else (total + size - 1) `div` size,
      pageNumber = page,
      pageSize = size
    }

search :: Pool -> ThreatQuery -> IO (Either Pool.UsageError (Page ThreatSummary))
search pool q = do
  let page = normalizePage (tqPage q)
      size = normalizeSize (tqSize q)
      filt =
        Store.ThreatFilter
          (tqFrameworkCode q)
          (tqSeverity q)
          (tqStride q)
          (tqTag q)
          (tqQ q)
  result <- Store.search pool filt page size
  pure (fmap (\(items, total) -> buildPage items total page size) result)

getById :: Pool -> UUID -> IO (Either Pool.UsageError (Maybe ThreatDetail))
getById = Store.getById
