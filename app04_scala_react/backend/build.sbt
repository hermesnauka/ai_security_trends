ThisBuild / version      := "0.1.0-phase1"
ThisBuild / scalaVersion := "3.3.8"
// zio-http pulls zio-schema-json (wants zio-json 0.9.1); quill-jdbc-zio wants
// 0.7.1. Newer zio-json is compatible for basic DeriveJsonCodec usage here -
// downgrade sbt's eviction check from hard error to warning.
ThisBuild / evictionErrorLevel := Level.Warn

lazy val root = (project in file("."))
  .settings(
    name := "scalashield-backend",
    libraryDependencies ++= Seq(
      "dev.zio"              %% "zio"                          % "2.1.26",
      "dev.zio"              %% "zio-http"                     % "3.11.3",
      "dev.zio"              %% "zio-json"                     % "0.7.3",
      "io.getquill"          %% "quill-jdbc-zio"               % "4.8.6",
      "org.postgresql"        %  "postgresql"                   % "42.7.13",
      "com.zaxxer"            %  "HikariCP"                    % "7.1.0",
      "org.flywaydb"          %  "flyway-core"                 % "12.10.0",
      "org.flywaydb"          %  "flyway-database-postgresql"  % "12.10.0",
      // D-15: jwt-scala (pdi.jwt) - Scala-idiomatic HS256 JWT; no Java exception types cross into app code
      "com.github.jwt-scala" %% "jwt-core"                     % "9.4.6",
      "org.mindrot"           %  "jbcrypt"                     % "0.4",
      "ch.qos.logback"        %  "logback-classic"             % "1.5.12",
      "dev.zio"              %% "zio-test"                      % "2.1.26" % Test,
      "dev.zio"              %% "zio-test-sbt"                  % "2.1.26" % Test,
    ),
    testFrameworks += new TestFramework("zio.test.sbt.ZTestFramework"),
    assembly / mainClass := Some("com.scalashield.Main"),
    assembly / assemblyMergeStrategy := {
      // JDBC drivers (and other SPI-based libs) register themselves via
      // META-INF/services/* - a blanket META-INF discard silently breaks
      // DriverManager's lookup at runtime even though the jar builds fine.
      case PathList("META-INF", "services", xs @ _*) => MergeStrategy.concat
      case PathList("META-INF", xs @ _*)              => MergeStrategy.discard
      case "module-info.class"                        => MergeStrategy.discard
      case _                                           => MergeStrategy.first
    },
  )
