package com.scalashield.routes

import com.scalashield.config.AppConfig
import org.mindrot.jbcrypt.BCrypt
import pdi.jwt.{Jwt, JwtAlgorithm, JwtClaim}
import zio._
import zio.http._
import zio.json._

import java.time.Instant

object AuthRoutes:

  private final case class LoginRequest(username: String, password: String)
  private given JsonDecoder[LoginRequest] = DeriveJsonDecoder.gen

  private final case class LoginResponse(token: String, tokenType: String, role: String)
  private given JsonEncoder[LoginResponse] = DeriveJsonEncoder.gen

  /** D-15: jwt-scala HS256 - no RS256 key pair; secret is shared with sibling apps via JWT_SECRET env var. */
  private def generateToken(username: String, cfg: AppConfig): String =
    val now   = Instant.now()
    val claim = JwtClaim(
      content    = """{"role":"ADMIN"}""",
      subject    = Some(username),
      issuedAt   = Some(now.getEpochSecond),
      expiration = Some(now.plusSeconds(cfg.jwtExpirationHours.toLong * 3600).getEpochSecond),
    )
    Jwt.encode(claim, cfg.jwtSecret, JwtAlgorithm.HS256)

  val routes: Routes[AppConfig, Response] = Routes(
    Method.POST / "api" / "v1" / "auth" / "login" -> handler { (req: Request) =>
      for
        body <- req.body.asString.orDie
        resp <- body.fromJson[LoginRequest] match
          case Left(_) =>
            ZIO.succeed(Response.status(Status.BadRequest))
          case Right(loginReq) =>
            ZIO.serviceWith[AppConfig] { cfg =>
              val usernameOk = loginReq.username == cfg.adminUsername
              val passwordOk =
                cfg.adminPasswordHash.nonEmpty &&
                  BCrypt.checkpw(loginReq.password, cfg.adminPasswordHash)
              if usernameOk && passwordOk then
                val token = generateToken(loginReq.username, cfg)
                Response.json(LoginResponse(token, "Bearer", "ADMIN").toJson)
              else
                Response.status(Status.Unauthorized)
            }
      yield resp
    },
  )
