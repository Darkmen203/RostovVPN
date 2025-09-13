#!/usr/bin/env node
// scripts/gen-latest.mjs
import fs from "fs";
import path from "path";
import { createHash } from "crypto";

const [,, versionArg, cdnBaseArg, artifactsDirArg] = process.argv;

if (!versionArg || !cdnBaseArg || !artifactsDirArg) {
  console.error("Usage: node scripts/gen-latest.mjs <version> <cdnBase> <artifactsDir>");
  process.exit(2);
}

const version = String(versionArg).trim().replace(/^v/, "");
const cdnBase = String(cdnBaseArg).replace(/\/+$/,"");
const dir = path.resolve(artifactsDirArg);

const PRODUCT = "RostovVPN";

// -------- helpers --------
function sha256File(file) {
  return new Promise((resolve, reject) => {
    const h = createHash("sha256");
    const s = fs.createReadStream(file);
    s.on("error", reject);
    s.on("data", (chunk) => h.update(chunk));
    s.on("end", () => resolve(h.digest("hex")));
  });
}

function detectMeta(filename) {
  const f = filename;
  const lower = f.toLowerCase();

  const has = (needle) => lower.includes(needle);
  const ends = (ext) => lower.endsWith(ext);

  // Defaults
  let platform = "Unknown";
  let type = "";
  let arch = "";

  // --- ANDROID ---
  if (ends(".apk") || has("android")) {
    platform = "Android";
    type = "APK";
    if (has("universal")) arch = "universal";
    else if (has("arm64") || has("aarch64")) arch = "arm64";
    else if (has("arm7") || has("armv7")) arch = "arm7";
    else if (has("x86_64") || has("x64")) arch = "x86_64";
  }
  if (ends(".aab")) {
    platform = "Android";
    type = ".aab";
    if (!arch) arch = "market";
  }

  // --- WINDOWS ---
  if (ends(".exe")) {
    platform = "Windows";
    type = "Setup";
    if (has("x64") || has("amd64")) arch = "x64";
  } else if (ends(".msix")) {
    platform = "Windows";
    type = "MSIX";
    if (has("x64") || has("amd64")) arch = "x64";
  } else if (ends(".zip") && (has("windows") || has("portable"))) {
    platform = "Windows";
    type = "Portable";
    if (has("x64") || has("amd64")) arch = "x64";
  }

  // --- macOS ---
  if (ends(".dmg")) {
    platform = "macOS";
    type = "DMG";
    if (!arch) arch = "universal";
  } else if (ends(".pkg")) {
    platform = "macOS";
    type = "Installer";
    if (!arch) arch = "universal";
  }

  // --- Linux ---
  if (ends(".appimage")) {
    platform = "Linux";
    type = "AppImage";
    if (has("x64") || has("amd64")) arch = "x64";
  } else if (ends(".deb")) {
    platform = "Linux";
    type = "DEB";
    if (has("x64") || has("amd64")) arch = "x64";
  } else if (ends(".rpm")) {
    platform = "Linux";
    type = "RPM";
    if (has("x64") || has("amd64")) arch = "x64";
  }

  // Fallbacks for names that include the platform word
  if (platform === "Unknown") {
    if (has("linux")) platform = "Linux";
    if (has("windows")) platform = "Windows";
    if (has("macos") || has("darwin") || has("osx")) platform = "macOS";
    if (has("android")) platform = "Android";
  }

  return { platform, type, arch };
}

// -------- main --------
async function main() {
  const entries = await fs.promises.readdir(dir, { withFileTypes: true });

  // Фильтруем только обычные файлы-артефакты
  const files = entries
    .filter(e => e.isFile())
    .map(e => e.name)
    .filter(n => !/^Source code/i.test(n));

  const assets = [];
  for (const name of files) {
    const filePath = path.join(dir, name);
    const st = await fs.promises.stat(filePath);
    const { platform, type, arch } = detectMeta(name);
    const url = `${cdnBase}/releases/${version}/${encodeURIComponent(name)}`;
    const sha256 = await sha256File(filePath);

    assets.push({
      platform,
      arch,
      type,
      filename: name,
      url,
      size: st.size,
      sha256
    });
  }

  // Сортировка стабильная: сперва Android/Windows/macOS/Linux, затем по имени
  const order = { Android: 0, Windows: 1, macOS: 2, Linux: 3, Unknown: 9 };
  assets.sort((a, b) =>
    (order[a.platform] ?? 9) - (order[b.platform] ?? 9) ||
    String(a.filename).localeCompare(String(b.filename))
  );

  const out = {
    version,
    releasedAt: new Date().toISOString(),
    telegramChannelUrl: "https://t.me/rostovvpn",
    telegramFaqUrl: "https://t.me/rostovvpn_faq",
    microsoftStoreUrl: "https://apps.microsoft.com/detail/9N9HX27F15C2",
    assets
  };

  const outDir = dir; // кладём рядом с артефактами конкретной версии
  const latestPath = path.join(outDir, "latest.json");
  await fs.promises.writeFile(latestPath, JSON.stringify(out, null, 4));
  console.log("Wrote:", latestPath);

  // Дублируем в artifacts/latest.json (чтобы следующий шаг мог подобрать)
  const artifactsRoot = path.resolve(dir, "..");
  const topLatest = path.join(artifactsRoot, "latest.json");
  await fs.promises.writeFile(topLatest, JSON.stringify(out, null, 4));
  console.log("Wrote:", topLatest);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
