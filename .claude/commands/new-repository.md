---
description: Add a repository (interface + Mock + Remote) and register it
argument-hint: "<area> <what it loads>"
---
Follow `docs/adding-a-feature.md` → "A repository" for $ARGUMENTS: interface, `Mock*` over `MockJsonDataSource` (use `_ds.guard`), `Remote*` over `RemoteDataSource`, register **both** in `lib/core/bindings/initial_binding.dart`, document the HTTP shape in `docs/API_CONTRACT.md`, add a test with the mock.
