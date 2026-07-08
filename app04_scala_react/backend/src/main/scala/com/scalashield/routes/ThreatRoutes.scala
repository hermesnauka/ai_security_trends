package com.scalashield.routes

import com.scalashield.model.{Page, Severity, StrideCategory, ThreatDetail, ThreatSummary}
import com.scalashield.repository.{FrameworkRepository, ThreatFilter, ThreatRepository, ThreatRow}
import zio._
import zio.http._
import zio.json._

import java.util.UUID
import javax.sql.DataSource
import scala.util.Try

object ThreatRoutes:

  private def parseStride(raw: String): Set[StrideCategory] =
    raw.split(",").iterator.map(_.trim).filter(_.nonEmpty).flatMap(s => Try(StrideCategory.valueOf(s)).toOption).toSet

  private def parseTags(raw: String): List[String] =
    raw.split(",").iterator.map(_.trim).filter(_.nonEmpty).toList

  private def toSummary(row: ThreatRow, codeByFrameworkId: Map[UUID, String]): ThreatSummary =
    ThreatSummary(
      id = row.id,
      frameworkCode = codeByFrameworkId.getOrElse(row.frameworkId, "UNKNOWN"),
      code = row.code,
      title = row.title,
      severity = Severity.valueOf(row.severity),
      category = row.category,
      stride = parseStride(row.stride),
      tags = parseTags(row.tags),
    )

  private def toDetail(row: ThreatRow, codeByFrameworkId: Map[UUID, String], nameByFrameworkId: Map[UUID, String]): ThreatDetail =
    ThreatDetail(
      id = row.id,
      frameworkCode = codeByFrameworkId.getOrElse(row.frameworkId, "UNKNOWN"),
      frameworkName = nameByFrameworkId.getOrElse(row.frameworkId, "Unknown"),
      code = row.code,
      title = row.title,
      severity = Severity.valueOf(row.severity),
      category = row.category,
      description = row.description,
      attackVector = row.attackVector,
      attackSurface = row.attackSurface,
      stride = parseStride(row.stride),
      cveReferences = List.empty, // never populated in Phase 1 seed data - see ThreatRow
      tags = parseTags(row.tags),
    )

  private def queryParam(req: Request, name: String): Option[String] =
    req.url.queryParams.getAll(name).headOption

  private def listThreats(req: Request): ZIO[DataSource, Nothing, Response] =
    (for
      frameworks <- FrameworkRepository.findAll
      idByCode = frameworks.map(f => f.code -> f.id).toMap
      codeById = frameworks.map(f => f.id -> f.code).toMap
      filter = ThreatFilter(
        frameworkId = queryParam(req, "frameworkCode").flatMap(idByCode.get),
        severity = queryParam(req, "severity"),
        stride = queryParam(req, "stride"),
        category = queryParam(req, "category"),
        tag = queryParam(req, "tag"),
        q = queryParam(req, "q"),
      )
      rows <- ThreatRepository.search(filter)
      page = queryParam(req, "page").flatMap(_.toIntOption).getOrElse(0)
      size = queryParam(req, "size").flatMap(_.toIntOption).getOrElse(20)
      summaries = rows.map(toSummary(_, codeById))
    yield Response.json(Page.of(summaries, page, size).toJson)).orDie

  private def getThreat(id: String): ZIO[DataSource, Nothing, Response] =
    (for
      maybeId <- ZIO.succeed(Try(UUID.fromString(id)).toOption)
      response <- maybeId match
        case None => ZIO.succeed(Response.status(Status.BadRequest))
        case Some(uuid) =>
          for
            frameworks <- FrameworkRepository.findAll
            codeById = frameworks.map(f => f.id -> f.code).toMap
            nameById = frameworks.map(f => f.id -> f.name).toMap
            row <- ThreatRepository.findById(uuid)
          yield row match
            case Some(r) => Response.json(toDetail(r, codeById, nameById).toJson)
            case None    => Response.status(Status.NotFound)
    yield response).orDie

  val routes: Routes[DataSource, Response] = Routes(
    Method.GET / "api" / "v1" / "threats" -> handler { (req: Request) => listThreats(req) },
    Method.GET / "api" / "v1" / "threats" / string("id") -> handler { (id: String, _: Request) => getThreat(id) },
  )
