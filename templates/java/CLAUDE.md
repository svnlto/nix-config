# Java Project

## Commands

```bash
nix develop              # enter dev shell with jdk, maven, google-java-format
mvn compile              # compile the project
mvn test                 # run tests
mvn package              # build JAR/WAR
mvn clean install        # clean build and install to local repo
google-java-format --replace src/**/*.java  # format all Java files
pre-commit run --all-files  # run all pre-commit hooks
```

## Conventions

- Use Maven standard directory layout (`src/main/java`, `src/test/java`)
- Follow Google Java Style Guide (enforced by `google-java-format`)
- One public class per file, matching filename
- Use `final` for fields that don't change
- Prefer composition over inheritance
- Use records for data-only classes (Java 16+)
- Use `Optional` for nullable return values, never for parameters

## Testing

- JUnit 5 for unit tests
- Use `@DisplayName` for readable test names
- One assertion concept per test method
- Mock external dependencies with Mockito

## Relevant Skills

This project benefits from globally installed Claude Code skills:
- **rest-api-design** — API endpoint design, request/response patterns
- **ci-cd** — Maven build pipeline design
- **database-design** — schema design, JPA/Hibernate patterns
