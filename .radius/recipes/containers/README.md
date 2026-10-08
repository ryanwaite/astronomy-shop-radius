# Customer-owned Kubernetes container recipe

This directory contains a narrow derivative of the upstream
`Radius.Compute/containers` Kubernetes recipe. It adds guarded `hostPath`
volumes without changing the application source or replacing the Radius
resource type.

The owner-approved policy boundary is recorded in
[radius-performance-demo PR25](https://github.com/ryanwaite/radius-performance-demo/pull/25)
at commit `c02036ec120474edaf5fd4e28e2981bd42fdbda9`.

## Provenance

The unmodified source is preserved under `upstream/`. The derivative is based
on:

- Repository: `radius-project/resource-types-contrib`
- Commit: `18142182e52e19a46b0ed172037357e8e142dcd2`
- Path: `Compute/containers/recipes/kubernetes/bicep/kubernetes-containers.bicep`
- SHA-256: `607cc7ad043231f91392a86d85b1899eafab2cc27c2ec6aeed3b55182fcd4fc7`
- License: Apache-2.0, preserved in `UPSTREAM-LICENSE`

That source is byte-identical to upstream commit
`842973883bd6de255031f80c1f6959ef15ac8269` as inspected on October 8, 2026.

## Contract

Host paths remain disabled unless the platform owner supplies recipe
parameters:

| Parameter | Default | Meaning |
|---|---:|---|
| `enableHostPathVolumes` | `false` | Enables processing of host-path requests. |
| `allowedHostPaths` | `[]` | Exact Kubernetes node paths the recipe may mount. |
| `requireReadOnlyHostPathMounts` | `true` | Rejects any requested host mount that is not explicitly read-only. |

The allowlist uses exact string matches. Approving `/` does **not** implicitly
approve `/var`, `/var/log`, or any other path. Explicitly approving `/` still
exposes a broad view of the node filesystem even when mounted read-only.

Workloads request volumes through the existing open `platformOptions` property:

```bicep
platformOptions: {
  kubernetes: {
    hostPathVolumes: {
      hostfs: {
        path: '/'
        type: 'Directory'
        mounts: [
          {
            container: 'otelCollector'
            mountPath: '/hostfs'
            readOnly: true
          }
        ]
      }
      runtimeSocket: {
        path: '/var/run/docker.sock'
        type: 'Socket'
        mounts: [
          {
            container: 'otelCollector'
            mountPath: '/var/run/docker.sock'
            readOnly: true
          }
        ]
      }
    }
  }
}
```

The platform-owner parameters are recipe inputs, not workload properties.
Workload input therefore cannot enable the feature, expand the allowlist, or
disable the read-only requirement.

The derivative rejects:

- host paths while the platform gate is disabled;
- paths not present in the exact-match allowlist;
- relative paths and unsupported Kubernetes `hostPath.type` values;
- host volume names that collide after the recipe's lowercase normalization;
- ordinary volumes with zero or multiple sources;
- ambiguous container names after lowercase normalization;
- unknown container keys;
- duplicate host mounts or collisions with existing mount destinations; and
- writable mounts while the read-only platform control is enabled.

Existing secret, persistent, empty-directory, connection, init-container,
probe, Dapr, autoscaling, service, and output behavior remains in the copied
recipe.

## Security and runtime limits

Kubernetes Baseline and Restricted Pod Security Standards reject `hostPath`.
Enabling this recipe capability neither changes admission policy nor creates an
exemption. The platform owner must select an explicitly permitted environment.

A read-only socket mount prevents replacing the socket file through the mount.
It does **not** make operations sent through the socket API read-only. The
service listening at `/var/run/docker.sock` must also be compatible with the
Kubernetes node and intended collector configuration.

The paths refer to the Kubernetes node, which may be a VM rather than the
developer workstation.

## Validation and publication evidence

Run the source and guard-mutation checks with the Node interpreter supplied by
the Radius extension:

```text
"/opt/homebrew/bin/node" --test .radius/recipes/containers/tests/recipe-contract.test.mjs
```

These checks verify pinned provenance and fail when critical gates, collision
checks, or generated host-volume fields are removed. They do not execute the
Bicep recipe and cannot establish generated Kubernetes manifest behavior.

On October 8, 2026, the managed `radius_publish_recipe` tool built and
published this recipe to the immutable experimental target:

```text
br:ghcr.io/ryanwaite/astronomy-shop-radius/containers-hostpath:experimental-af56964
```

The first managed compile rejected an invalid standard-volume source-count
expression. The expression was repaired to count matching source names with
`filter()` and `length()`. GHCR initially rejected upload because the active
stored credential lacked package scope. After the repository owner completed
the supported GitHub authorization, the managed publisher succeeded without
changing package visibility.

Published identity:

- GHCR package:
  `ryanwaite/astronomy-shop-radius/containers-hostpath`
- Tag: `experimental-af56964`
- Package version ID: `1354574463`
- Visibility: private
- Manifest digest:
  `sha256:633ae50ea645e8d19d71de2bcf03e7266dc1c5e2675fe00cfad21f391a5457e3`
- Bicep module layer digest:
  `sha256:3b60a06798e00e66c583527b3fff8a2f73f95943688776c1df53714c1b471c31`
- Bicep module config digest:
  `sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a`
- Compiled Bicep version: `0.42.1.51946`

The published manifest and both blobs were fetched from GHCR. Their byte counts
and SHA-256 values match the OCI descriptors. Inspection of the real compiled
template confirmed:

- the three platform parameters and their secure defaults;
- compiled host-path request, validation, mount, and Pod-volume variables;
- the Deployment template consumes the combined Pod volumes; and
- the recipe still emits the Radius `result.resources` and `result.values`
  output shape.

This is real compiler evidence, but its boundary is narrow:

- the derivative compiles as a Radius Bicep recipe;
- the published OCI manifest and compiled Bicep template match their recorded
  digests;
- no positive or negative recipe input was evaluated;
- no generated Kubernetes Deployment or Pod manifest was inspected; and
- the source and mutation tests are not substitutes for recipe execution.

No direct `rad`, direct Bicep invocation, package-visibility change, or CLI
fallback publication was used.

## Recipe-pack and Environment prerequisite

Publication alone is not registration. A `Radius.Core/recipePacks` resource
must map `Radius.Compute/containers` to the published derivative and pass these
platform-owned defaults:

```bicep
parameters: {
  enableHostPathVolumes: true
  allowedHostPaths: [
    '/'
    '/var/run/docker.sock'
  ]
  requireReadOnlyHostPathMounts: true
}
```

The target Environment must then reference that pack. Radius rejects an
Environment when two attached packs define the same resource type,
case-insensitively. The managed default Kubernetes pack already defines
`Radius.Compute/containers`, so the derivative cannot be appended alongside
that pack.

The deployment workflow's custom-pack action preserves existing packs,
including the default pack. Using it unchanged for this derivative would
therefore fail Environment validation rather than override the default
container recipe. A supported registration increment must instead establish a
replacement pack that contains every recipe the Shop model relies on and
replaces the default pack atomically, or use another operator-owned Environment
configuration that attaches only non-conflicting packs. It must not silently
drop the existing `Radius.Compute/containerImages` or
`Radius.Security/secrets` recipes.

This conclusion was checked against:

- `radius-project/radius` commit
  `b8300b4bb7dc01ac379f127637de138d8ce4e99f`, whose Environment controller
  returns a conflict when different attached packs define the same resource
  type; and
- `radius-project/ai-extensions` commit
  `21ebde52bf8979f3765bd675356780731e422f63`, whose
  `apply-custom-recipe-packs` action deploys custom packs and unions them with
  the Environment's existing packs.

No replacement pack or Environment update has been authored or applied in this
increment. The next authoring increment must create that replacement pack using
the published tag above, preserve every other recipe required by the selected
Shop model, and update the deployment workflow or operator-owned Environment
definition so the replacement is attached without the conflicting default
pack. Executed recipe evaluation remains a separate validation step after that
registration source exists.

The recipe is not registered to an Environment and does not make the Shop
model, deployment, runtime comparison, or benchmark fixture eligible.
