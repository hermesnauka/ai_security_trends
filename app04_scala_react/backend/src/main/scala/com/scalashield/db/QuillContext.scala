package com.scalashield.db

import io.getquill._

/** D-02: ZIO Quill compile-time SQL verification. All query construction
  * below is macro-expanded and checked against the case class shapes at
  * compile time - string-concatenated SQL is not possible through this
  * context, which is the whole point of the architectural decision. */
object Ctx extends PostgresZioJdbcContext(SnakeCase)
