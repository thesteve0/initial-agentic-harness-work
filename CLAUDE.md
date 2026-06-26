# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repo supports a personal feasibility study: can a fully local, open-source agentic stack replace proprietary harnesses (Claude Code, ChatGPT, Cursor) for everyday work? The work spans coding, writing (blog posts, CFPs), technical planning, land management, home construction, purchasing decisions, and ADHD support.

Three harnesses — **Goose**, **Hermes Agent**, and **OpenCode** — are evaluated against a locally served LLM on a Framework Desktop (AMD Ryzen AI 395+, 96GB unified GPU memory). Quality and speed are the primary axes; cost is not a concern.

OpenTelemetry output from each harness is forwarded to an **MLFlow OTel endpoint** on **OpenShift AI** for objective run comparison. Subjective quality is captured alongside OTel run IDs using a 3-point scale: `-1` (bad), `0` (neutral), `1` (helpful), plus a free-text notes field explaining the why behind each rating.

## Evaluation Approach

Two phases, run in sequence:

1. **Controlled** — the same benchmark tasks run identically across all three harnesses. Establishes a baseline comparison.
2. **Naturalistic** — real daily work tasks assigned to whichever harness seems appropriate, logged over time.

## Repository Structure

```
benchmarks/
  tasks/       # markdown files — one per task, with prompt and success criteria
  results/     # one markdown file per task, recording scores and OTel run IDs per harness
worklog/       # naturalistic phase — notes and ratings from real work sessions
configs/       # harness config files, symlinked to each harness's default location
  goose/
  hermes/
  opencode/
scripts/       # symlink setup and any run helpers
```

### Result File Format

```markdown
## Task: <task name>

| Harness | Score | Notes |
|---------|-------|-------|
| Goose   | 1     | Good output, needed one revision |
| Hermes  | 0     | Correct but generic |
| OpenCode| -1    | Looped on tool calls, never produced output |

OTel run IDs: goose=abc123, hermes=def456, opencode=ghi789
```

Scores: `1` = helpful, `0` = neutral, `-1` = bad. Notes should capture the failure mode or standout behavior, not just restate the score.

## Architecture

```
┌─────────────┐   ┌──────────────┐   ┌──────────────┐
│    Goose    │   │ Hermes Agent │   │  OpenCode    │
└──────┬──────┘   └──────┬───────┘   └──────┬───────┘
       │                 │                   │
       │    (OpenAI-compatible API)           │
       └──────────┬──────┴───────────────────┘
                  │
          ┌───────▼────────┐
          │  Local Model   │
          │  (vLLM / etc.) │
          └────────────────┘
       │                 │                   │
       │         (OTel OTLP export)          │
       └──────────┬──────┴───────────────────┘
                  │
          ┌───────▼────────┐
          │  OTel Collector │
          └───────┬────────┘
                  │
          ┌───────▼────────────────┐
          │  MLFlow OTel Endpoint  │
          │  (OpenShift AI)        │
          └────────────────────────┘
```

**Key integration points:**
- All three harnesses are configured with the same local model endpoint so results are comparable
- OTel instrumentation is first-class — traces, metrics, and logs from each harness run flow to MLFlow
- MLFlow is used for experiment tracking and run comparison across harnesses (not for model serving)
- The MLFlow instance is remote (OpenShift AI), not local

## OpenShift AI Cluster Access

The MLFlow instance runs on a Red Hat OpenShift AI cluster in AWS. The cluster has no GPU — it is used strictly for remote MLFlow tracing and evaluation.

- **OpenShift Console:** https://console-openshift-console.apps.agentic-harness.sandbox5530.opentlc.com
- **RHOAI Console:** https://data-science-gateway.apps.agentic-harness.sandbox5530.opentlc.com/
- **Authentication:** OAuth via GitHub

## OTel Wiring per Harness

### Goose

Goose uses standard OTel environment variables. Point it at the MLFlow OTLP endpoint:

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=<mlflow-otel-endpoint>   # e.g. http://mlflow.openshift.svc:4318
export OTEL_SERVICE_NAME=goose
export OTEL_RESOURCE_ATTRIBUTES=harness=goose
# Optional per-signal overrides: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, etc.
# Optional sampling: OTEL_TRACES_SAMPLER=parentbased_traceidratio OTEL_TRACES_SAMPLER_ARG=1.0
```

Docs: [Goose observability env vars](https://goose-docs.ai/docs/guides/environment-variables/#observability-configuration)

### Hermes Agent

Hermes Agent ([repo](https://github.com/NousResearch/hermes-agent), [docs](https://hermes-agent.nousresearch.com/docs)) has **no built-in OTel support**. Tracing is added via the third-party [`hermes-otel`](https://briancaffey.github.io/hermes-otel) plugin.

**Install Hermes Agent:**
```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

**Configure local model endpoint** in `config.yaml`:
```yaml
model:
  provider: custom
  base_url: "http://localhost:<port>/v1"
  default: "<model-name>"
```
Or via env vars: `OPENAI_BASE_URL` + `OPENAI_API_KEY`.

**Install the OTel plugin:**
```bash
hermes plugins install briancaffey/hermes-otel
```

**Configure the plugin** — use the **generic OTLP** backend to target MLFlow:
```yaml
# hermes-otel config.yaml
backend: otlp
otlp_endpoint: <mlflow-otel-endpoint>
capture_previews: false
```

The plugin emits dual-convention attributes (`gen_ai.*` and `llm.token_count.*`) automatically.
MLflow tracing docs: [Tracing Hermes Agent | MLflow](https://mlflow.org/docs/latest/tracing/integrations/hermes-agent)

### OpenCode

Uses the [`opencode-plugin-otel`](https://github.com/DEVtheOPS/opencode-plugin-otel) plugin (OTLP/gRPC). Register in `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["@devtheops/opencode-plugin-otel"]
}
```

Then set env vars:

```bash
export OPENCODE_ENABLE_TELEMETRY=1
export OPENCODE_OTLP_ENDPOINT=<mlflow-otel-endpoint>
export OPENCODE_OTLP_PROTOCOL=grpc          # or http/protobuf depending on MLFlow endpoint
export OPENCODE_RESOURCE_ATTRIBUTES=harness=opencode
```

Optional: set `OPENCODE_METRIC_PREFIX=claude_code.` to mirror Claude Code's dashboard signals.

## Harnesses

| Harness | OTel Mechanism | Reference |
|---------|----------------|-----------|
| [Goose](https://github.com/block/goose) | Native OTel env vars (`OTEL_*`) | [Goose docs](https://goose-docs.ai/docs/guides/environment-variables/#observability-configuration) |
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | `hermes-otel` third-party plugin + `config.yaml` | [hermes-otel](https://briancaffey.github.io/hermes-otel), [MLflow integration](https://mlflow.org/docs/latest/tracing/integrations/hermes-agent) |
| [OpenCode](https://github.com/opencode-ai/opencode) | `opencode-plugin-otel` (`OPENCODE_*` env vars) | [opencode-plugin-otel](https://github.com/DEVtheOPS/opencode-plugin-otel) |
