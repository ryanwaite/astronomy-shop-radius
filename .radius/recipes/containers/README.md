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

## Offline checks and current blocker

Run the source and guard-mutation checks with the Node interpreter supplied by
the Radius extension:

```text
"/opt/homebrew/bin/node" --test .radius/recipes/containers/tests/recipe-contract.test.mjs
```

These checks verify pinned provenance and fail when critical gates, collision
checks, or generated host-volume fields are removed. They do not execute the
Bicep recipe and cannot establish generated Kubernetes manifest behavior.

The supported Radius tooling available to this repository can validate an
application model or publish a recipe to a registry. This increment is not
authorized to publish, and direct `rad` or managed-binary invocation is
prohibited. The recipe therefore remains **uncompiled and unpackaged** until a
supported local compiler path is available. It is not registered to an
Environment and does not make the Shop model, deployment, runtime comparison,
or benchmark fixture eligible.
