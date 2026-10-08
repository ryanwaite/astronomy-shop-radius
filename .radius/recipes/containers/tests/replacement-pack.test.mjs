import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { access, readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const testsDirectory = path.dirname(fileURLToPath(import.meta.url));
const radiusDirectory = path.resolve(testsDirectory, "../../..");
const replacementPath = path.join(
  radiusDirectory,
  "recipes",
  "containers",
  "integrations",
  "azure-v0.61.1-replacement.bicep"
);
const provenancePath = path.join(
  radiusDirectory,
  "recipes",
  "containers",
  "provenance.json"
);
const autoDiscoveredPackPath = path.join(
  radiusDirectory,
  "custom-recipe-pack.bicep"
);
const [replacement, provenanceText] = await Promise.all([
  readFile(replacementPath, "utf8"),
  readFile(provenancePath, "utf8")
]);
const provenance = JSON.parse(provenanceText);

const resourceTypesCommit = "18142182e52e19a46b0ed172037357e8e142dcd2";
const replacementSource =
  "ghcr.io/ryanwaite/astronomy-shop-radius/containers-hostpath:experimental-af56964";
const defaultPackId =
  "/planes/radius/local/resourceGroups/default/providers/Radius.Core/recipePacks/default";
const replacementPackId =
  "/planes/radius/local/resourceGroups/default/providers/Radius.Core/recipePacks/azure-avm";

// Hashes are from the v0.61.1 Azure pack after the pinned workflow replaces
// every Kubernetes recipe's mutable latest tag with resourceTypesCommit.
const baselineRecipeHashes = {
  "Radius.Data/redisCaches":
    "f2cb4eccc4dc1f952d6b2e7e89bbdd8b6b9926a3fee03d1766eba9e0b5c445ae",
  "Radius.AI/models":
    "49354b1665bb9a34926854b68e0ddeba1dbdc281f8fdc6aaea66d6ef0dec2175",
  "Radius.AI/search":
    "e9b37d3793e14723290924c2187d84b53c334059e57553d29ce2d132415a2406",
  "Radius.Data/mongoDatabases":
    "a9ee5c49a6a6826bebac0659fee377ad3fd2fd9083867cc09d21891e38d4cb4a",
  "Radius.Data/mySqlDatabases":
    "27b2f9a78eeb53280f3c1104066adf94d98382880713058e8b180540639271bc",
  "Radius.Data/postgreSqlDatabases":
    "78c527e66e406ccf0b309f394e17360bd5a19da87a232bd3192143e3ba06df88",
  "Radius.Data/sqlServerDatabases":
    "0c616e78248118e361af11f46dae8bdbf473fbfdd78a729d4e8a38b43f2ddc72",
  "Radius.Messaging/rabbitMQ":
    "c9d7dd6d3fc6eabc460514fb622627b7257aa642b56cce08cc7de8ece450f38a",
  "Radius.Messaging/kafka":
    "d1ed33e0e45ee458da282c866323c11f022f22f6f9f6195116283af0b6a28df5",
  "Radius.Storage/objectStorage":
    "d10dd6d7633e6561f19c2682abf9833efb981f5079c35361d6b5451825e444fb",
  "Radius.Compute/containers":
    "deacbbec774dbeafb54f297f46af1adbbd5a847c5e635ee61a9cc9b150fcd8f3",
  "Radius.Compute/persistentVolumes":
    "101b1093fbae9b8ebc88cdaceea7cb4df06b756a94285d39894d95be87532453",
  "Radius.Security/secrets":
    "d53747aaab381e8dcf939a374d679d988203179139a9e930d9c9b235619400e4",
  "Radius.Compute/routes":
    "fc1dd9b7a2298f4487d3e0840c1a637e2be603619b83b9a6732cda3fea0ea26f",
  "Radius.Compute/containerImages":
    "e641f3708d5ab67dba884bc58aef87e2aad73198ecd0853d8ebfda130275f9c7"
};

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

function findObjectBlock(source, start) {
  const openingBrace = source.indexOf("{", start);
  let depth = 0;
  let inString = false;

  for (let index = openingBrace; index < source.length; index += 1) {
    const character = source[index];
    if (character === "'" && source[index - 1] !== "\\") {
      inString = !inString;
      continue;
    }
    if (inString) {
      continue;
    }
    if (character === "{") {
      depth += 1;
    } else if (character === "}") {
      depth -= 1;
      if (depth === 0) {
        return source.slice(start, index + 1).trim();
      }
    }
  }

  throw new Error("Unclosed Bicep object.");
}

function extractRecipes(source) {
  const recipePattern = /^\s{6}'([^']+)':\s*\{/gm;
  const recipes = new Map();
  const normalizedNames = new Set();
  let match;

  while ((match = recipePattern.exec(source)) !== null) {
    const name = match[1];
    const normalizedName = name.toLowerCase();
    if (normalizedNames.has(normalizedName)) {
      throw new Error(`Duplicate recipe type after normalization: ${name}`);
    }
    const block = findObjectBlock(source, match.index);
    normalizedNames.add(normalizedName);
    recipes.set(name, block);
    recipePattern.lastIndex = match.index + block.length;
  }

  return recipes;
}

function replacementContractErrors(source) {
  const errors = [];
  let recipes;
  try {
    recipes = extractRecipes(source);
  } catch (error) {
    return [error.message];
  }

  const expectedNames = Object.keys(baselineRecipeHashes).sort();
  const actualNames = [...recipes.keys()].sort();
  if (actualNames.length === 0) {
    errors.push("Replacement recipe inventory is empty.");
  }
  if (JSON.stringify(actualNames) !== JSON.stringify(expectedNames)) {
    errors.push("Replacement recipe inventory differs from the selected baseline.");
  }

  for (const [name, expectedHash] of Object.entries(baselineRecipeHashes)) {
    const block = recipes.get(name);
    if (!block || name === "Radius.Compute/containers") {
      continue;
    }
    if (sha256(block) !== expectedHash) {
      errors.push(`Baseline recipe changed unexpectedly: ${name}`);
    }
  }

  const containerBlock = recipes.get("Radius.Compute/containers") ?? "";
  const requiredContainerFragments = [
    `source: '${replacementSource}'`,
    "enableHostPathVolumes: true",
    "allowedHostPaths: [\n            '/'\n            '/var/run/docker.sock'\n          ]",
    "requireReadOnlyHostPathMounts: true"
  ];
  for (const fragment of requiredContainerFragments) {
    if (!containerBlock.includes(fragment)) {
      errors.push(`Missing replacement container contract: ${fragment}`);
    }
  }

  const requiredOperatorInputs = [
    "param routesGatewayName string",
    "param routesGatewayNamespace string = 'default'",
    "param containerImagesRegistry string",
    "param containerImagesRegistrySecretName string = ''",
    "param postgreSqlServerConfigurations array = []"
  ];
  const sourceLines = source.split("\n");
  for (const fragment of requiredOperatorInputs) {
    if (!sourceLines.includes(fragment)) {
      errors.push(`Changed prospective baseline input: ${fragment}`);
    }
  }

  if (!source.includes("name: 'azure-avm'")) {
    errors.push("Replacement must update the existing azure-avm pack identity.");
  }
  if (
    source.includes("ghcr.io/radius-project/kube-recipes/") &&
    source.includes(":latest'")
  ) {
    errors.push("Replacement pack contains an unpinned Kubernetes recipe.");
  }
  if (
    !source.includes(
      `ghcr.io/radius-project/kube-recipes/containerimages:${resourceTypesCommit}`
    )
  ) {
    errors.push("Replacement pack does not use the selected resource-type pin.");
  }

  return errors;
}

function planReplacementAttachments(existingPackIds) {
  if (
    !Array.isArray(existingPackIds) ||
    existingPackIds.length === 0 ||
    existingPackIds.some(
      (packId) => typeof packId !== "string" || packId.length === 0
    )
  ) {
    throw new Error("Existing recipe-pack attachments must be nonempty strings.");
  }

  const normalized = existingPackIds.map((packId) => packId.toLowerCase());
  if (new Set(normalized).size !== normalized.length) {
    throw new Error("Existing recipe-pack attachments are ambiguous.");
  }
  if (normalized.includes(defaultPackId.toLowerCase())) {
    throw new Error("The conflicting default recipe pack is still attached.");
  }

  const replacementIndex = normalized.indexOf(replacementPackId.toLowerCase());
  if (replacementIndex === -1) {
    throw new Error("The original azure-avm recipe-pack attachment is absent.");
  }

  return existingPackIds.map((packId, index) =>
    index === replacementIndex ? replacementPackId : packId
  );
}

test("preserves the complete effective baseline except containers", () => {
  assert.deepEqual(replacementContractErrors(replacement), []);
  assert.equal(extractRecipes(replacement).size, 15);
  assert.equal(
    sha256(replacement),
    provenance.replacementRecipePack.replacementSha256
  );
});

test("keeps the Azure example outside current workflow auto-discovery", async () => {
  await assert.rejects(access(autoDiscoveredPackPath), { code: "ENOENT" });
  assert.equal(
    provenance.replacementRecipePack.selectedForCurrentTarget,
    false
  );
  assert.equal(provenance.registrationInvestigation.selectedTarget, "local-podman");
});

test("plans a prospective idempotent update and preserves unrelated packs", () => {
  const otherPack =
    "/planes/radius/local/resourceGroups/default/providers/Radius.Core/recipePacks/telemetry";
  const existing = [replacementPackId, otherPack];
  const planned = planReplacementAttachments(existing);
  assert.deepEqual(planned, existing);
  assert.deepEqual(planReplacementAttachments(planned), planned);
});

test("rejects an absent original attachment", () => {
  assert.throws(
    () =>
      planReplacementAttachments([
        "/planes/radius/local/resourceGroups/default/providers/Radius.Core/recipePacks/other"
      ]),
    /original azure-avm recipe-pack attachment is absent/
  );
});

test("rejects ambiguous attachments case-insensitively", () => {
  assert.throws(
    () =>
      planReplacementAttachments([
        replacementPackId,
        replacementPackId.toUpperCase()
      ]),
    /attachments are ambiguous/
  );
});

test("rejects the conflicting default attachment", () => {
  assert.throws(
    () => planReplacementAttachments([replacementPackId, defaultPackId]),
    /conflicting default recipe pack is still attached/
  );
});

const contractMutations = [
  {
    name: "dropping an unrelated baseline recipe",
    mutate: (source) =>
      source.replace(
        extractRecipes(source).get("Radius.AI/search"),
        ""
      ),
    expected: "Replacement recipe inventory differs from the selected baseline."
  },
  {
    name: "changing an unrelated baseline recipe",
    mutate: (source) =>
      source.replace(
        "mcr.microsoft.com/bicep/avm/res/search/search-service:0.12.2",
        "mcr.microsoft.com/bicep/avm/res/search/search-service:0.12.3"
      ),
    expected: "Baseline recipe changed unexpectedly: Radius.AI/search"
  },
  {
    name: "adding a case-insensitive duplicate recipe",
    mutate: (source) =>
      source.replace(
        "      'Radius.Compute/containers': {",
        "      'radius.compute/containers': {\n        kind: 'bicep'\n        source: 'duplicate'\n      }\n      'Radius.Compute/containers': {"
      ),
    expected: "Duplicate recipe type after normalization"
  },
  {
    name: "changing an approved host path",
    mutate: (source) =>
      source.replace("            '/var/run/docker.sock'", "            '/var/run'"),
    expected: "Missing replacement container contract"
  },
  {
    name: "exposing writable host mounts",
    mutate: (source) =>
      source.replace(
        "requireReadOnlyHostPathMounts: true",
        "requireReadOnlyHostPathMounts: false"
      ),
    expected: "Missing replacement container contract"
  },
  {
    name: "changing the in-place pack identity",
    mutate: (source) => source.replace("name: 'azure-avm'", "name: 'shop-hostpath'"),
    expected: "Replacement must update the existing azure-avm pack identity."
  },
  {
    name: "restoring a mutable Kubernetes recipe",
    mutate: (source) =>
      source.replace(
        `containerimages:${resourceTypesCommit}`,
        "containerimages:latest"
      ),
    expected: "Replacement pack contains an unpinned Kubernetes recipe."
  },
  {
    name: "silently defaulting the operator registry",
    mutate: (source) =>
      source.replace(
        "param containerImagesRegistry string",
        "param containerImagesRegistry string = 'ghcr.io/ryanwaite/astronomy-shop-radius'"
      ),
    expected: "Changed prospective baseline input"
  }
];

for (const mutation of contractMutations) {
  test(`rejects mutation: ${mutation.name}`, () => {
    const errors = replacementContractErrors(mutation.mutate(replacement));
    assert.ok(
      errors.some((error) => error.includes(mutation.expected)),
      errors.join("\n")
    );
  });
}
