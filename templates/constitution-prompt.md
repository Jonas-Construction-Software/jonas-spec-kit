Create a constitution for spec-driven AI development in our organization. The constitution must be actionable, testable, and enforceable: every principle should include (1) rationale, (2) MUST/SHOULD language, (3) measurable acceptance criteria, and (4) common anti-patterns to avoid.

Focus areas (prioritize in this order): code quality & maintainability, testing & coverage, architecture & dependency rules, security & configuration, user experience consistency (Angular), performance & scalability, and DevOps/CI quality gates.

Use and encode the following organization conventions and “golden path” requirements:

GENERAL ENGINEERING
- Write clean, self-explanatory, testable code. Prefer readability over cleverness. No commented-out or dead code.
- Each file defines one primary class/component; target <1000 lines.
- Prefer small, composable units; avoid large “god” services.

C# / BACKEND (.NET) NAMING & STRUCTURE
- PascalCase for classes/interfaces/structs/public members; interfaces prefixed with “I”.
- camelCase for private/internal fields, locals, parameters.
- REST endpoints use kebab-case.
- Namespaces: <Product>.<TopModule>.<SubModule>; file name matches class name.
- File/member order: using → fields → constants → properties → constructors → methods (public then private).

C# / BACKEND PRACTICES
- No hard-coded strings/paths: use constants + configuration.
- Avoid methods with >3–4 parameters; introduce DTOs/value objects.
- Use C# type aliases (int, string, etc.).
- Exception handling: in try/catch, log with ILogger<T> (Serilog) and rethrow with “throw;” (no wrapping unless explicitly required).
- Collections: prefer IEnumerable<T> / IList<T> over concrete list types in public APIs.

ARCHITECTURE (DEFAULT FOR ALL NEW WORK)
- Use Domain-Centric Architecture: domain is central and framework-agnostic.
- Domain layer defines behavior; API and Data depend on Domain, never the reverse.
- Controllers never access data directly.
- Use repository pattern with EF Core + fluent configuration.
- Logging: Serilog + ILogger<T>.
- RESTful ASP.NET Core APIs with Swagger/OpenAPI and JWT security.
- Configuration: appsettings.json + environment overrides; secrets in Azure Key Vault.
- Legacy tech (EF6/WCF/log4net/WebForms) requires an explicit owner + deprecation plan.

DATA RULES
- Normalize and choose SQL vs NoSQL per use case.
- Prefer integer surrogate keys.
- Encrypt sensitive data; separate app and DB servers when applicable.
- Use stored procedures for frequent operations (when justified by profiling).

ANGULAR / FRONTEND RULES
- Filenames: feature.type.ts (e.g., user-profile.service.ts); one component per file.
- Classes: UpperCamelCase + suffix (Component/Service/Pipe/Module); selectors in kebab-case.
- Flat folder structure with feature modules; SharedModule for reusable code; do not provide stateful services in SharedModule.
- SRP for components/services.
- Member order: properties first, then methods (public before private; alphabetized where practical).
- Best practices: use *ngIf (no CSS hiding); prefer OnPush; async pipe; unsubscribe/cleanup in ngOnDestroy; cache repeated API calls; observables for reactive updates.

DEVOPS & QUALITY GATES
- CI/CD via Azure DevOps YAML pipelines with shared templates, PR triggers, build/test/deploy.
- One repo equals one build; exclude bin/obj/node_modules; commit frequently.
- Feature branches; build from dev; release branch after freeze.
- Enforce build, tests, coverage, and static analysis (StyleCop). Coverage reports via OpenCover → Cobertura.
- Testing: MSTest or xUnit with Moq; require meaningful unit tests and (when appropriate) integration tests.

OUTPUT REQUIREMENTS
- Produce principles that guide spec-to-code workflow: how to translate specs into implementation, how to structure changes, how to define “done”, and how to handle uncertainty or conflicting requests (“favor domain-centric architecture and modern standards; propose compliant alternatives”).
- Include explicit “Quality Bar” sections for Backend, Frontend, Data, and DevOps.
- Include a “Non-Negotiables” section and an “Exception Process” section (who/what must be documented to allow deviations).
- Ensure the constitution is concise enough to be used daily, but strict enough to prevent architectural drift.
