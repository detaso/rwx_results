# RWX Results

[RWX](https://www.rwx.com/) builds CI/CD tooling.

[Captain](https://www.rwx.com/captain) is an open source CLI that can detect and quarantine flaky tests,
automatically retry failed tests, partition files for parallel execution,
and more. It's compatible with 17 testing frameworks.

RWX Results is a GitHub Action that reports on the Captain results for a Pull Request.

## Get Started

```
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
