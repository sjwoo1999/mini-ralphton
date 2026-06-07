# codex-ralph

GitHub URL: https://github.com/sjwoo1999/mini-ralphton

`codex-ralph` is a Ralphthon Track 1 harness: Codex writes code, but shell gates decide whether work is done. The live target is a 16-smoke engine suite plus a small SPEC-B workload, with completion defined by `bash harness/verify.sh` and backlog exhaustion.

## Quickstart

```sh
npm install
bash harness/run_smokes.sh
bash harness/verify.sh
```

## Demo Loop

```sh
bash harness/start_run.sh
bash harness/codex_loop.sh
```

## What Counts

| Area | Gate |
|---|---|
| Verify engine | `harness/smoke_verify.sh` has exactly 8 smokes |
| Backlog engine | `harness/smoke_backlog.sh` has exactly 8 smokes |
| Workload | SPEC-B `[S1]` through `[S8]` pass through Vitest |
| Submission | `harness/submission_requirements.sh` checks the GitHub URL and optional artifacts |

Prior art: this repo carries event-kit instructions and references, but the runnable harness and app code are written here for the Codex track.
