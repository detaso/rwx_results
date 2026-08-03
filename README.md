# RWX Results

[RWX](https://www.rwx.com/) builds CI/CD tooling.

[Captain](https://www.rwx.com/captain) is an open source CLI that can detect and quarantine flaky tests,
automatically retry failed tests, partition files for parallel execution,
and more. It's compatible with 17 testing frameworks.

RWX Results is a GitHub Action that reports on the Captain results for a Pull Request.

## Get Started

```yaml
name: Tests

on:
  push:
  pull_request:

jobs:
  tests:
    name: Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - uses: rwx-research/setup-captain@v1

      - run: captain run tests
        env:
          RWX_ACCESS_TOKEN: ${{ secrets.RWX_ACCESS_TOKEN }}

      - uses: detaso/rwx_results@v1
        with:
          rwx-access-token: ${{ secrets.RWX_ACCESS_TOKEN }}
          captain-test-suite-id: tests
```

## Versioning

Pick a ref based on how much churn you want:

| Ref | Resolves to |
| --- | --- |
| `@v1` | Latest release in the 1.x line. Recommended. |
| `@v1.2.0` | Exactly that release, immutably. |
| `@main` | The most recent release once one has been cut, since `main` pins it after each release. |

Each release publishes an immutable `ghcr.io/detaso/rwx_results:X.Y.Z` image
and moves `:v1` to match. Because the action metadata records the exact image
tag, `@v1.2.0` runs 1.2.0's code and nothing else.

That guarantee covers releases cut from 1.2.0 onward. Tags predating this scheme
(`v1.0.0`, `v1.1.0`) pin the moving `:v1` image, so they track the newest release
rather than the version they name.

Releases are cut by running the **Release** workflow with a version like
`1.2.0`. Use its `dry_run` option to rehearse without publishing.
