# OpenTelemetry Astronomy Shop

The Astronomy Shop is a microservice application that demonstrates OpenTelemetry
instrumentation. Application source and service tests are under `src/`; shared
telemetry definitions are under `telemetry-schema/`, and integration tests are
under `test/telemetry/`. Service Dockerfiles and Compose manifests describe build
inputs and runtime configuration. See `CONTRIBUTING.md` and service documentation
for development guidance. Upstream copyright notices and `LICENSE` are retained.

This source export comes from open-telemetry/opentelemetry-demo release 3.1.0,
commit dedc0178918e260823323b8d95005a8cb924b007. It has a fresh local Git baseline,
not upstream history. No dependencies have been installed or application services
started. Existing source, tests and telemetry configuration are unchanged.

`compose.defaults` records public non-secret configuration defaults from that
revision for source inspection. It is not a complete runtime environment:
credentials, machine-specific mounts and local `.env` files are not distributed.
The upstream Makefile still expects operator-supplied environment files.
Do not run its default startup on a shared host without reviewing mounts,
published ports, dependencies and local configuration.

The optional agent service's recorded model conversations are not distributed.
Its replay mode is consequently incomplete. Ordinary source references to those
files remain unchanged. This export is for source inspection and authoring, not
a claim that every optional startup profile is runnable.
