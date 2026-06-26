# Agentic Harness Evaluation

A personal feasibility study: can a fully local, open-source agentic stack replace proprietary harnesses (Claude Code, ChatGPT, Cursor) for everyday work?

Three harnesses — **Goose**, **Hermes Agent**, and **OpenCode** — are evaluated against a locally served LLM on a Framework Desktop (AMD Ryzen AI 395+, 96GB unified GPU memory). Quality and speed are the primary axes; cost is not a concern.

## Evaluation Approach

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

## Architecture

All three harnesses connect to the same local model via an OpenAI-compatible API. OpenTelemetry traces, metrics, and logs from each harness flow to an MLFlow instance on OpenShift AI for objective run comparison. Subjective quality is captured alongside OTel run IDs using a 3-point scale (`-1` bad, `0` neutral, `1` helpful) plus free-text notes.

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

## Harnesses

| Harness | OTel Mechanism | Reference |
|---------|----------------|-----------|
| [Goose](https://github.com/block/goose) | Native OTel env vars (`OTEL_*`) | [Goose docs](https://goose-docs.ai/docs/guides/environment-variables/#observability-configuration) |
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | `hermes-otel` third-party plugin + `config.yaml` | [hermes-otel](https://briancaffey.github.io/hermes-otel), [MLflow integration](https://mlflow.org/docs/latest/tracing/integrations/hermes-agent) |
| [OpenCode](https://github.com/opencode-ai/opencode) | `opencode-plugin-otel` (`OPENCODE_*` env vars) | [opencode-plugin-otel](https://github.com/DEVtheOPS/opencode-plugin-otel) |

## OpenShift AI Cluster Access

The MLFlow instance runs on a Red Hat OpenShift AI cluster in AWS. The cluster has no GPU — it is used strictly for remote MLFlow tracing and evaluation.

- **OpenShift Console:** https://console-openshift-console.apps.agentic-harness.sandbox5530.opentlc.com
- **RHOAI Console:** https://data-science-gateway.apps.agentic-harness.sandbox5530.opentlc.com/
- **Authentication:** OAuth via GitHub
