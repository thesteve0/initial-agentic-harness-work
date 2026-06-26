# TODO: Goose Setup

Get Goose installed, talking to the locally served model, and sending traces to MLFlow on OpenShift AI.

## 1. Install Goose

Follow the [Goose installation docs](https://block.github.io/goose/docs/getting-started/installation).

After install, verify:
```bash
goose --version
```

## 2. Find what global config files Goose creates

Before configuring anything, run Goose briefly and inventory what it writes to disk:

```bash
touch /tmp/goose-baseline
# run goose once, exit immediately
goose
# then:
find ~ -maxdepth 5 -newer /tmp/goose-baseline -not -path '*/.git/*' -not -path '*/cache/*' 2>/dev/null
```

Record the config file location here so we know what to symlink into `configs/goose/`.

**Config file location:** `<fill in after running above>`

## 3. Point Goose at the locally served model

Edit the Goose config file found above. Set the model provider to use the local OpenAI-compatible endpoint:

- **Base URL:** `http://<framework-desktop-ip>:<port>/v1`
- **Model name:** `<model name as served by vLLM/etc>`
- **API key:** any non-empty string (local servers typically don't validate)

Verify Goose can complete a simple prompt before moving on.

## 4. Symlink the config into this repo

Once you know the config file path:

```bash
cp <goose-config-path> configs/goose/<filename>
ln -sf "$(pwd)/configs/goose/<filename>" <goose-config-path>
```

Add the symlink command to `scripts/setup_symlinks.sh`.

## 5. Configure OTel to send traces to MLFlow

Add the following to your shell profile (`.bashrc` or `.zshrc`) — these are env vars, not a config file, so there is nothing to symlink:

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=<mlflow-otlp-endpoint-on-openshift-ai>
export OTEL_SERVICE_NAME=goose
export OTEL_RESOURCE_ATTRIBUTES=harness=goose
```

**MLFlow OTLP endpoint:** not yet known — get this from the OpenShift AI MLFlow instance. It will be an HTTPS URL, likely on port 4318 (HTTP/protobuf) or 4317 (gRPC).

Reload your shell and confirm the vars are set:
```bash
echo $OTEL_EXPORTER_OTLP_ENDPOINT
```

## 6. Verify traces are arriving in MLFlow

Run a short Goose session, then check the MLFlow UI for a new experiment/run with spans from `goose`.

If no traces appear:
- Confirm the OTLP endpoint URL and port are correct
- Check whether MLFlow expects HTTP or gRPC (`OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf` or `grpc`)
- Check whether auth headers are required (`OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer <token>`)

## Open questions

- [ ] What is the MLFlow OTLP endpoint URL on OpenShift AI?
- [ ] Does the MLFlow endpoint require auth headers?
- [ ] What model are we serving and on what port?
- [ ] Does Goose have a config file, or is everything env vars?
