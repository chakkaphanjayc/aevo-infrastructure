import { access, readFile } from "node:fs/promises";
import { resolve } from "node:path";

const root = resolve(import.meta.dir, "..");

async function exists(relativePath: string): Promise<boolean> {
  try {
    await access(resolve(root, relativePath));
    return true;
  } catch {
    return false;
  }
}

async function contains(relativePath: string, value: string): Promise<boolean> {
  try {
    return (await readFile(resolve(root, relativePath), "utf8")).includes(value);
  } catch {
    return false;
  }
}

const checks: Array<[string, boolean]> = [
  ["Core API migrator project", await exists("../aevo-core-api/src/Aevo.CoreApi.Migrator/Aevo.CoreApi.Migrator.csproj")],
  ["Core API migration ownership readme", await exists("../aevo-core-api/db/migrations/README.md")],
  ["Core control-plane migration authority ledger", await exists("../aevo-core-api/db/migrations/0013_control_plane_migration_authority.sql")],
  ["Machine-readable HUB-005 authority inventory", await exists("../docs/hub-system/inventory/migration-authority.json")],
  ["Historical app migrations are not Core ownership", (await contains("../aevo-core-api/db/migrations/README.md", "not part of the Core API migration history")) && (await contains("../aevo-core-api/db/migrations/README.md", "0022` through `0027"))],
  ["Core migration-only service account", await contains("modules/iam/main.tf", 'migrate  = "aevo-migrate-${var.environment}"')],
  ["Hub has no migration write runner", !(await exists("../aevo-hub/scripts/migrate.ts"))],
  ["Hub has no legacy migration command", !(await contains("../aevo-hub/package.json", "legacy-compat"))],
  ["Hub launcher starts Core/Edge target", (await contains("../aevo-hub/scripts/dev.ts", 'label: "core-api"')) && (await contains("../aevo-hub/scripts/dev.ts", 'label: "edge"'))],
  ["Root launcher does not start Hub gateway", !(await contains("../scripts/local-dev.ts", ["apps", "gateway", "src", "index.ts"].join("/")))]
];

const failed = checks.filter(([, passed]) => !passed);
for (const [label, passed] of checks) console.log(`${passed ? "PASS" : "FAIL"}  ${label}`);
if (failed.length > 0) process.exitCode = 1;
else console.log("Migration ownership is Core API/Infrastructure controlled.");
