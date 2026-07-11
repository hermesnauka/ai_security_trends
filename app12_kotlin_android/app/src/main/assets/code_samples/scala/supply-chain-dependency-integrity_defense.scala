// SECURE pattern
// WHY: an exact version means the build always resolves to a reviewed artifact, and sbt-dependency-check
// runs OWASP's SCA scanner against every build (mirrors this project's own composer audit + WPScan gate)
libraryDependencies += "org.example" %% "some-lib" % "2.3.1"

// project/plugins.sbt
addSbtPlugin("net.vonbuchholtz" % "sbt-dependency-check" % "5.1.0")

// build.sbt
dependencyCheckFailBuildOnCVSS := 7.0
