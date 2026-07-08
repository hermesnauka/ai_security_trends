package com.scalashield.model

import zio.json.{DeriveJsonCodec, JsonCodec}

import java.util.UUID

enum Severity derives JsonCodec:
  case CRITICAL, HIGH, MEDIUM, LOW, INFO

/** Phase 1 scope keeps `stride`/`tags` as plain comma-joined strings in the
  * database (see V1 migration) rather than a normalized join table -
  * acceptable at this data volume; revisit if the full Cornucopia card
  * catalogue (Phase 6+) makes it a hot path. This case class exposes them
  * as the richer `Set[StrideCategory]`/`List[String]` types from PLAN.md
  * section 5.1/5.3 - the repository layer does the string <-> collection
  * conversion, not the API layer.
  */
enum StrideCategory derives JsonCodec:
  case S, T, R, I, D, E

final case class ThreatSummary(
    id: UUID,
    frameworkCode: String,
    code: String,
    title: String,
    severity: Severity,
    category: String,
    stride: Set[StrideCategory],
    tags: List[String],
)

object ThreatSummary:
  given codec: JsonCodec[ThreatSummary] = DeriveJsonCodec.gen[ThreatSummary]

final case class ThreatDetail(
    id: UUID,
    frameworkCode: String,
    frameworkName: String,
    code: String,
    title: String,
    severity: Severity,
    category: String,
    description: String,
    attackVector: String,
    attackSurface: String,
    stride: Set[StrideCategory],
    cveReferences: List[String],
    tags: List[String],
)

object ThreatDetail:
  given codec: JsonCodec[ThreatDetail] = DeriveJsonCodec.gen[ThreatDetail]
