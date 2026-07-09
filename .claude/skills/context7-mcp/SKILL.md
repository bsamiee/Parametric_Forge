---
name: context7-mcp
description: >-
  Current library, framework, and API documentation through the Context7 MCP tools
  `resolve-library-id` and `query-docs` — signatures, configuration, setup, and code
  examples from live indexed docs instead of training-data recall. Use for setup or
  configuration questions, code generation involving a library, API references, or any
  mention of a specific framework — React, Vue, Next.js, Prisma, Supabase, and peers.
  General web research beyond indexed library docs belongs to tavily-dynamic-search.
---

# [CONTEXT7]

Library questions resolve against live indexed documentation, never training data: `resolve-library-id` maps a library name to a Context7 ID, `query-docs` answers one scoped question against that ID. A known ID in the `/org/project` or `/org/project/version` form passes straight to `query-docs` with no resolution step.

## [01]-[FLOW]

- [RESOLVE]: `resolve-library-id` takes `libraryName` plus the full question as `query` for relevance ranking. Selection prefers the exact or closest name match, higher benchmark scores, official or primary packages over community forks, and a version-specific ID whenever the task names a version.
- [QUERY]: `query-docs` takes the chosen `libraryId` and one specific question. Each call carries a single concept — a question spanning distinct concepts splits into one call per concept, capped at three calls per question.
- [APPLY]: The fetched signatures and examples land in the answer as verified fact; the library version rides along only when it changes the guidance.

## [02]-[QUERY_SHAPE]

```text rejected
query: "auth"
```

```text accepted
libraryId: /supabase/supabase
query: "How to verify a JWT and read the authenticated user in a server-side route"
```

Specific, task-shaped queries return targeted sections; bare keywords return noise. The user's own phrasing, passed whole, outperforms a paraphrase.

## [03]-[FALLBACK]

A library or version absent from the index routes to its own repository or documentation site through tavily-dynamic-search — never to memory.
