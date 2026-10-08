import { createHash } from "node:crypto";

const requiredFragments = [
  [
    "default-off platform gate",
    "param enableHostPathVolumes bool = false"
  ],
  [
    "empty exact-path allowlist",
    "param allowedHostPaths array = []"
  ],
  [
    "default-on read-only policy",
    "param requireReadOnlyHostPathMounts bool = true"
  ],
  [
    "disabled request failure",
    "fail('Kubernetes hostPath volumes are disabled by the platform owner.')"
  ],
  [
    "absolute host-path validation",
    "fail('Every Kubernetes hostPath must be an absolute path.')"
  ],
  [
    "exact-match allowlist check",
    "contains(allowedHostPaths, string(volume.value.path))"
  ],
  [
    "host-path type validation",
    "fail('The requested Kubernetes hostPath type is not supported.')"
  ],
  [
    "normalized volume collision check",
    "contains(standardVolumeNames, toLower(volume.key))"
  ],
  [
    "normalized container ambiguity check",
    "length(normalizedContainerNames) != length(union(normalizedContainerNames, normalizedContainerNames))"
  ],
  [
    "existing mount destination collision check",
    "contains(existingMountDestinations, '${toLower(mount.container)}|${mount.mountPath}')"
  ],
  [
    "read-only enforcement",
    "fail('The platform owner requires every Kubernetes hostPath mount to set readOnly to true.')"
  ],
  [
    "standard volume source validation",
    "Every standard volume must specify exactly one source"
  ],
  [
    "hostPath volume generation",
    "hostPath: {\n    path: volume.value.path\n    type: volume.value.type"
  ],
  [
    "mount readOnly generation",
    "readOnly: mount.readOnly"
  ],
  [
    "connection secret collision behavior",
    "Connection secret keys must produce unique environment variable names after uppercasing."
  ],
  [
    "existing hosts output",
    "values: empty(servicesConfig) ? {} : { hosts: hostsMap }"
  ]
];

export function sha256(source) {
  return createHash("sha256").update(source).digest("hex");
}

export function checkRecipeSource(source) {
  const errors = [];

  for (const [name, fragment] of requiredFragments) {
    if (!source.includes(fragment)) {
      errors.push(`Missing ${name}.`);
    }
  }

  if (/startsWith\s*\(\s*allowedHostPaths/u.test(source)) {
    errors.push("Host-path approval must use exact matches, not prefix matching.");
  }

  if (source.includes("podSpecOverride") || source.includes("rawPodSpec")) {
    errors.push("The derivative must not expose an unrestricted PodSpec override.");
  }

  return errors;
}
