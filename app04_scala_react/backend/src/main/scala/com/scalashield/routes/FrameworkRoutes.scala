package com.scalashield.routes

import com.scalashield.repository.FrameworkRepository
import zio._
import zio.http._
import zio.json._

import javax.sql.DataSource

object FrameworkRoutes:
  val routes: Routes[DataSource, Response] = Routes(
    Method.GET / "api" / "v1" / "frameworks" -> handler { (_: Request) =>
      FrameworkRepository.findAll.map(list => Response.json(list.toJson)).orDie
    },
    Method.GET / "api" / "v1" / "frameworks" / string("code") -> handler { (code: String, _: Request) =>
      FrameworkRepository
        .findByCode(code)
        .map {
          case Some(f) => Response.json(f.toJson)
          case None    => Response.status(Status.NotFound)
        }
        .orDie
    },
  )
