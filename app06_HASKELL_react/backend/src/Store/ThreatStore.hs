module Store.ThreatStore
  ( ThreatFilter (..),
    search,
    getById,
  )
where

import Data.Functor.Contravariant ((>$<))
import Data.Int (Int32, Int64)
import Data.Text (Text)
import Domain.Types
import qualified Hasql.Decoders as D
import qualified Hasql.Encoders as E
import qualified Hasql.Pool as Pool
import qualified Hasql.Session as Session
import qualified Hasql.Statement as Statement
import Store.Pool (Pool)
import Data.UUID (UUID)

data ThreatFilter = ThreatFilter
  { tfFrameworkCode :: Maybe Text,
    tfSeverity :: Maybe Text,
    tfStride :: Maybe Text,
    tfTag :: Maybe Text,
    tfQ :: Maybe Text
  }

filterEncoder :: E.Params ThreatFilter
filterEncoder =
  (tfFrameworkCode >$< E.param (E.nullable E.text))
    <> (tfSeverity >$< E.param (E.nullable E.text))
    <> (tfStride >$< E.param (E.nullable E.text))
    <> (tfTag >$< E.param (E.nullable E.text))
    <> (tfQ >$< E.param (E.nullable E.text))

-- | Every optional filter is expressed as a NULL-check against the same
-- five positional params, so the statement's shape never changes -- no
-- dynamic SQL construction, no injection surface beyond ordinary
-- parameterization.
whereClause :: Text
whereClause =
  "  ($1::text IS NULL OR upper(f.code) = upper($1)) \
  \AND ($2::text IS NULL OR upper(t.severity) = upper($2)) \
  \AND ($3::text IS NULL OR upper($3) = ANY(t.stride)) \
  \AND ($4::text IS NULL OR EXISTS (SELECT 1 FROM unnest(t.tags) tg WHERE lower(tg) = lower($4))) \
  \AND ($5::text IS NULL OR lower(t.title) LIKE '%' || lower($5) || '%' \
  \      OR lower(coalesce(t.description, '')) LIKE '%' || lower($5) || '%')"

toStrideList :: Maybe [Text] -> [StrideCategory]
toStrideList = maybe [] (concatMap (maybe [] pure . strideFromText))

toTextList :: Maybe [Text] -> [Text]
toTextList = maybe [] id

summaryRow :: D.Row ThreatSummary
summaryRow =
  mk
    <$> D.column (D.nonNullable D.uuid)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable (D.listArray (D.nonNullable D.text)))
    <*> D.column (D.nullable (D.listArray (D.nonNullable D.text)))
  where
    mk tid fwCode code title sevText category strideArr tagsArr =
      ThreatSummary
        { tsId = tid,
          tsFrameworkCode = fwCode,
          tsCode = code,
          tsTitle = title,
          tsSeverity = maybe Info id (severityFromText sevText),
          tsCategory = category,
          tsStride = toStrideList strideArr,
          tsTags = toTextList tagsArr
        }

fst3 :: (a, b, c) -> a
fst3 (a, _, _) = a

snd3 :: (a, b, c) -> b
snd3 (_, b, _) = b

thd3 :: (a, b, c) -> c
thd3 (_, _, c) = c

searchStatement :: Statement.Statement (ThreatFilter, Int32, Int32) [ThreatSummary]
searchStatement = Statement.preparable sql encoder (D.rowList summaryRow)
  where
    sql =
      "SELECT t.id, f.code, t.code, t.title, t.severity, t.category, t.stride, t.tags \
      \FROM threat t JOIN framework f ON f.id = t.framework_id \
      \WHERE "
        <> whereClause
        <> " ORDER BY f.code, t.code LIMIT $6 OFFSET $7"
    encoder =
      (fst3 >$< filterEncoder)
        <> (snd3 >$< E.param (E.nonNullable E.int4))
        <> (thd3 >$< E.param (E.nonNullable E.int4))

countStatement :: Statement.Statement ThreatFilter Int64
countStatement = Statement.preparable sql filterEncoder decoder
  where
    sql = "SELECT count(*) FROM threat t JOIN framework f ON f.id = t.framework_id WHERE " <> whereClause
    decoder = D.singleRow (D.column (D.nonNullable D.int8))

search :: Pool -> ThreatFilter -> Int -> Int -> IO (Either Pool.UsageError ([ThreatSummary], Int))
search pool filt page size = do
  let limit = fromIntegral size :: Int32
      offset = fromIntegral (page * size) :: Int32
  itemsResult <- Pool.use pool (Session.statement (filt, limit, offset) searchStatement)
  case itemsResult of
    Left e -> pure (Left e)
    Right items -> do
      countResult <- Pool.use pool (Session.statement filt countStatement)
      case countResult of
        Left e -> pure (Left e)
        Right total -> pure (Right (items, fromIntegral total))

detailRow :: D.Row ThreatDetail
detailRow =
  mk
    <$> D.column (D.nonNullable D.uuid)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nonNullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable D.text)
    <*> D.column (D.nullable (D.listArray (D.nonNullable D.text)))
    <*> D.column (D.nullable (D.listArray (D.nonNullable D.text)))
    <*> D.column (D.nullable (D.listArray (D.nonNullable D.text)))
  where
    mk tid fwCode fwName code title sevText category desc attackVector attackSurface strideArr cveArr tagsArr =
      ThreatDetail
        { tdId = tid,
          tdFrameworkCode = fwCode,
          tdFrameworkName = fwName,
          tdCode = code,
          tdTitle = title,
          tdSeverity = maybe Info id (severityFromText sevText),
          tdCategory = category,
          tdDescription = desc,
          tdAttackVector = attackVector,
          tdAttackSurface = attackSurface,
          tdStride = toStrideList strideArr,
          tdCveReferences = toTextList cveArr,
          tdTags = toTextList tagsArr
        }

getByIdStatement :: Statement.Statement UUID (Maybe ThreatDetail)
getByIdStatement = Statement.preparable sql encoder (D.rowMaybe detailRow)
  where
    sql =
      "SELECT t.id, f.code, f.name, t.code, t.title, t.severity, t.category, t.description, \
      \t.attack_vector, t.attack_surface, t.stride, t.cve_references, t.tags \
      \FROM threat t JOIN framework f ON f.id = t.framework_id WHERE t.id = $1"
    encoder = E.param (E.nonNullable E.uuid)

getById :: Pool -> UUID -> IO (Either Pool.UsageError (Maybe ThreatDetail))
getById pool tid = Pool.use pool (Session.statement tid getByIdStatement)
