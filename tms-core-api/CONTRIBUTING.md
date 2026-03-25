# Contributing

Thanks for contributing to DriverApp. A few quick guidelines to get started:

- Use the Maven wrapper for all commands: `./mvnw`.
- Commit small, focused changes and open a Pull Request against `main`.
- Run tests locally:

```bash
./mvnw -B clean verify
```

- Formatting: we recommend using your IDE's formatter or apply the project's formatter if configured.
- For API changes, update or regenerate the OpenAPI spec (springdoc) and consider generating clients.

See `CODE_STYLE.md` for style rules.
