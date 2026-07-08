package com.scalashield.repository

import com.scalashield.db.Ctx
import com.scalashield.model.Framework
import zio._

import java.sql.SQLException
import javax.sql.DataSource

/** Class name matches the table name ("framework") so Quill's SnakeCase
  * naming strategy infers the right table without an explicit querySchema. */
object FrameworkRepository:
  import Ctx._
  import io.getquill._

  def findAll: ZIO[DataSource, SQLException, List[Framework]] =
    Ctx.run(query[Framework])

  def findByCode(code: String): ZIO[DataSource, SQLException, Option[Framework]] =
    Ctx.run(query[Framework].filter(f => f.code == lift(code))).map(_.headOption)
