import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { checkRecipeSource, sha256 } from "./recipe-contract.mjs";

const testsDirectory = path.dirname(fileURLToPath(import.meta.url));
const recipeDirectory = path.dirname(testsDirectory);
const derivativePath = path.join(recipeDirectory, "kubernetes-containers.bicep");
const upstreamPath = path.join(
  recipeDirectory,
  "upstream",
  "kubernetes-containers.bicep"
);
const provenancePath = path.join(recipeDirectory, "provenance.json");

const [derivative, upstream, provenanceText] = await Promise.all([
  readFile(derivativePath, "utf8"),
  readFile(upstreamPath, "utf8"),
  readFile(provenancePath, "utf8")
]);
const provenance = JSON.parse(provenanceText);

test("pins the exact upstream recipe", () => {
  assert.equal(sha256(upstream), provenance.upstreamSha256);
  assert.equal(sha256(derivative), provenance.derivativeSha256);
  assert.notEqual(provenance.derivativeSha256, provenance.upstreamSha256);
});

test("keeps every required hostPath guard and output field", () => {
  assert.deepEqual(checkRecipeSource(derivative), []);
});

const guardMutations = [
  {
    name: "enabling host paths by default",
    find: "param enableHostPathVolumes bool = false",
    replace: "param enableHostPathVolumes bool = true",
    expected: "Missing default-off platform gate."
  },
  {
    name: "replacing exact approval with a prefix check",
    find: "contains(allowedHostPaths, string(volume.value.path))",
    replace: "startsWith(allowedHostPaths[0], string(volume.value.path))",
    expected: "Missing exact-match allowlist check."
  },
  {
    name: "removing normalized volume collision validation",
    find: "contains(standardVolumeNames, toLower(volume.key))",
    replace: "false",
    expected: "Missing normalized volume collision check."
  },
  {
    name: "removing existing mount destination validation",
    find: "contains(existingMountDestinations, '${toLower(mount.container)}|${mount.mountPath}')",
    replace: "false",
    expected: "Missing existing mount destination collision check."
  },
  {
    name: "removing read-only enforcement",
    find: "fail('The platform owner requires every Kubernetes hostPath mount to set readOnly to true.')",
    replace: "mount",
    expected: "Missing read-only enforcement."
  },
  {
    name: "dropping generated mount readOnly",
    find: "readOnly: mount.readOnly",
    replace: "readOnly: false",
    expected: "Missing mount readOnly generation."
  },
  {
    name: "dropping generated hostPath type",
    find: "hostPath: {\n    path: volume.value.path\n    type: volume.value.type",
    replace: "hostPath: {\n    path: volume.value.path",
    expected: "Missing hostPath volume generation."
  },
  {
    name: "replacing the narrow contract with a raw PodSpec override",
    find: "var requestedHostPathItems =",
    replace: "var rawPodSpec = resourceProperties.platformOptions.rawPodSpec\nvar requestedHostPathItems =",
    expected: "The derivative must not expose an unrestricted PodSpec override."
  }
];

for (const mutation of guardMutations) {
  test(`rejects mutation: ${mutation.name}`, () => {
    assert.ok(
      derivative.includes(mutation.find),
      `Mutation fixture is stale: ${mutation.find}`
    );
    const errors = checkRecipeSource(
      derivative.replace(mutation.find, mutation.replace)
    );
    assert.ok(errors.includes(mutation.expected), errors.join("\n"));
  });
}
