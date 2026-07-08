package com.scalashield.model

import zio.json.{DeriveJsonCodec, JsonCodec}

import java.util.UUID

final case class Framework(
    id: UUID,
    code: String,
    name: String,
    version: String,
    description: String,
    referenceUrl: String,
)

object Framework:
  given codec: JsonCodec[Framework] = DeriveJsonCodec.gen[Framework]
