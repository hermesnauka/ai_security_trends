<!-- SECURE pattern -->
<!-- WHY: an exact, reviewed version pin means a build only ever resolves to a version the team has actually vetted -->
<dependency>
    <groupId>org.example</groupId>
    <artifactId>some-lib</artifactId>
    <version>1.4.2</version>
</dependency>
<!-- plus, in CI: mvn org.owasp:dependency-check-maven:check -->
