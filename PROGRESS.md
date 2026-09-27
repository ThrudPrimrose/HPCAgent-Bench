# release-v0.1 cleanup: progress and design changes

Running log of the unbloat/unslop/registry work on `release-v0.1`. Deleted before the release PR merges.

## Decisions

- No package rename; `hpcagent_bench` stays.
- Registries move to decorators on one shared `hpcagent_bench/registry.py`: frameworks, kernels (yaml and
  `@kernel` interchangeable), syntax checks + MCP tools, harnesses. Adding one = files in one folder + a
  registration.
- Yaml keeps only what code reads (experiment tags, input/output names, ...); unread entries such as
  taxonomy go.
- De-duplication and design pass: everything, including high-risk items, with behaviour kept identical
  (translators proven against a golden corpus of emitted code).
- CI toolchain: GCC >= 15 is enforced by `scripts/checks/verify_toolchain.py` (CI installs GCC 16).

## Checkpoints

| # | Commit | What |
|---|---|---|
| 1 | `1ae90de` | Merged CI fixes: translator test stand-ins carry `dtype=None`; gemm score accepts the c-autopar fallback. |
| 2 | `eedbe2b` | mi200 arms: a hosted model needs only `partition-mi200.env`; a served model needs its own `partition-mi200-<model>.env`. GCC >= 15 toolchain gate. |
| 3 | `9121285` | Dead code found by vulture removed (~90 lines). Most vulture hits were false positives (kernel entry points loaded by name, FastAPI routes, http.server overrides, CLI enum choices, TYPE_CHECKING imports). |

## In progress

| Workstream | Scope | Status |
|---|---|---|
| Docs | One owner per topic; merge perf_protocol, job_submission, owed_and_checkpointing, AMD-SUBMISSION; delete local_coding_agents; fix ~20 stale references; drop mi200-serving docs; ~7.9k -> ~5.2k lines | running |
| Registries | `registry.py`; `@framework` replacing FRAMEWORK_META + ~8 hand-kept name lists; `@harness` (listed in 4 places today); `@syntax_check` / `@tool` in the agent image; registry.yaml pruning | running |
| Kernels | Manifest key audit (drop unread keys from 702 yaml); `@kernel` read statically, interchangeable with yaml | running |
| Translators | Shared AST helpers, BaseEmitter scaffolding, Fortran kernel/helper merge, dace_emit split, shared type oracle; two suspected bugs (C OpenMP pinned constants, Fortran helper int kinds) | running |

## Queued

1. Shared utilities: `util/` for env files (~12 parsers), read-only SQLite (~20 opens; fixes `?`/`#` path bug),
   coercion helpers, repo paths, `git HEAD`, HTTP JSON + polling (16 sites); one test loader fixture.
2. Deletions: one-shot porting scripts; tests that only assert deleted symbols are gone.
3. Module splits: `agent_driver.py` (3.3k lines) into a package; `scoring.py` distributed/ML split and
   `graded_score` stages; `remaining_kernels.py` into `owed.py`; lazy CLI subcommands; importable
   `experiments` (drops `sys.path` hacks).
4. Config knobs: every `HPCAGENT_BENCH_*` read through `config`, prune single-use knobs, one kernel timeout;
   `run_cluster.sh` topology/port math into Python.
5. Comment and docstring trimming in the heaviest files.
