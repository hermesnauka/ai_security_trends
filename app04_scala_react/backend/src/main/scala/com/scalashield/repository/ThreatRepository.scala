package com.scalashield.repository

import com.scalashield.db.Ctx
import zio._

import java.sql.SQLException
import java.util.UUID
import javax.sql.DataSource

/** DB row shape - separate from the API-facing model.ThreatSummary/
  * ThreatDetail because those expose richer types (Set[StrideCategory],
  * frameworkCode instead of frameworkId) that don't map 1:1 onto columns.
  * `cve_references` is deliberately not read here - no Phase 1 seed row
  * ever populates it, so the API layer just returns List.empty for it
  * rather than threading an always-empty column through Quill.
  */
final case class ThreatRow(
    id: UUID,
    frameworkId: UUID,
    code: String,
    title: String,
    severity: String,
    category: String,
    description: String,
    attackVector: String,
    attackSurface: String,
    stride: String,
    tags: String,
)

final case class ThreatFilter(
    frameworkId: Option[UUID] = None,
    severity: Option[String] = None,
    stride: Option[String] = None,
    category: Option[String] = None,
    tag: Option[String] = None,
    q: Option[String] = None,
)

object ThreatRepository:
  import Ctx._
  import io.getquill._

  private inline def threatSchema = querySchema[ThreatRow]("threat")

  /** D-02: ZIO Quill dynamic query. Filters are only known at request time,
    * so this uses Quill's dynamicQuerySchema API rather than a fully static
    * `quote { ... }` block - but every predicate still goes through the
    * same compile-time-checked `quote`/`lift` machinery per filter, so
    * string-concatenated SQL is still not possible here.
    */
  def search(filter: ThreatFilter): ZIO[DataSource, SQLException, List[ThreatRow]] =
    var q = dynamicQuerySchema[ThreatRow]("threat")
    filter.frameworkId.foreach(v => q = q.filter(row => quote(row.frameworkId == lift(v))))
    filter.severity.foreach(v => q = q.filter(row => quote(row.severity == lift(v.toUpperCase))))
    filter.stride.foreach(v => q = q.filter(row => quote(row.stride like lift(s"%${v.toUpperCase}%"))))
    filter.category.foreach(v => q = q.filter(row => quote(row.category == lift(v))))
    filter.tag.foreach(v => q = q.filter(row => quote(row.tags like lift(s"%$v%"))))
    filter.q.foreach { v =>
      val pattern = s"%${v.toLowerCase}%"
      q = q.filter(row => quote(row.title.toLowerCase.like(lift(pattern)) || row.description.toLowerCase.like(lift(pattern))))
    }
    Ctx.run(q)

  def findById(id: UUID): ZIO[DataSource, SQLException, Option[ThreatRow]] =
    Ctx.run(threatSchema.filter(t => t.id == lift(id))).map(_.headOption)
