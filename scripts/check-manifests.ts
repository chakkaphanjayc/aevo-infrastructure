import { readdir, readFile } from "node:fs/promises";
import { join, relative } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const ignoredDirectories = new Set([".git", ".terraform", "node_modules"]);
const ignoredFiles = new Set([".env", ".env.local"]);
const secretPatterns = [
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/u,
  /(?:SUPABASE|FIREBASE|GOOGLE)_SERVICE_ACCOUNT_(?:KEY|JSON)\s*=/u,
  /"private_key"\s*:\s*"-----BEGIN/u
];

async function filesUnder(directory: string): Promise<string[]> {
  const entries = await readdir(directory, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    if (ignoredDirectories.has(entry.name)) continue;
    if (entry.isDirectory()) files.push(...await filesUnder(join(directory, entry.name)));
    else if (!ignoredFiles.has(entry.name) && !entry.name.endsWith(".tfstate")) files.push(join(directory, entry.name));
  }
  return files;
}

const files = await filesUnder(root);
const violations: string[] = [];
for (const file of files) {
  const content = await readFile(file, "utf8");
  if (secretPatterns.some((pattern) => pattern.test(content))) violations.push(relative(root, file));
}

const requiredPaths = [
  "bootstrap",
  "envs/nonprod",
  "envs/prod",
  "modules/cloud-run",
  "modules/cloud-sql",
  "modules/eventing",
  "modules/iam",
  "modules/secret-manager"
];
for (const requiredPath of requiredPaths) {
  const exists = files.some((file) => relative(root, file).startsWith(`${requiredPath}/`));
  if (!exists) violations.push(`${requiredPath}/ (missing)`);
}

if (violations.length > 0) {
  throw new Error(`Infrastructure manifest check failed:\n${violations.join("\n")}`);
}

console.log(`Infrastructure manifest check passed for ${files.length} files.`);
