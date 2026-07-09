---
description: Look up documentation for any library
argument-hint: <library> [query]
---

# /docs

Fetches current documentation and code examples for a library via Context7.

## [01]-[USAGE]

```text
/docs <library> [query]
```

- `library`: the library name, or a Context7 ID starting with `/`
- `query`: the lookup focus; sharpens relevance ranking

## [02]-[EXAMPLES]

```text
/docs react hooks
/docs next.js authentication
/docs prisma relations
/docs /vercel/next.js/v15.1.8 app router
/docs /supabase/supabase row level security
```

## [03]-[RESOLUTION]

1. A library argument starting with `/` is used directly as the Context7 ID.
2. Otherwise `resolve-library-id` finds the best matching library.
3. `query-docs` fetches documentation relevant to the query.
4. Results carry code examples and explanations.

## [04]-[VERSION_PINNING]

A version segment in the library ID pins the documentation to that release:

```text
/docs /vercel/next.js/v15.1.8 middleware
/docs /facebook/react/v19.0.0 use hook
```
