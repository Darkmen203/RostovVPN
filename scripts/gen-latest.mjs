// node scripts/gen-latest.mjs <VERSION> <CDN_BASE> [assetsDir]
import { createHash } from "crypto";
import { promises as fs } from "fs";
import path from "path";

const [,, VERSION, CDN_BASE_INPUT, ASSETS_DIR_INPUT] = process.argv;
const CDN_BASE = (CDN_BASE_INPUT || "").replace(/\/+$/,"");
if (!VERSION || !CDN_BASE) {
  console.error("Usage: node scripts/gen-latest.mjs <VERSION> <CDN_BASE> [assetsDir]");
  process.exit(1);
}
const assetsDir = path.resolve(ASSETS_DIR_INPUT || `artifacts/${VERSION}`);

const detect = (filename) => {
  const f = filename.toLowerCase();
  if (f.includes("windows")) {
    return { platform: "Windows",
      type: f.endsWith(".msix") ? "MSIX" : f.endsWith(".zip") ? "Portable" : "Setup",
      arch: f.includes("x64") ? "x64" : (f.includes("arm64") ? "arm64" : "")
    };
  }
  if (f.includes("macos")) {
    return { platform: "macOS",
      type: f.endsWith(".dmg") ? "DMG" : "Installer",
      arch: "universal"
    };
  }
  if (f.includes("linux")) {
    return { platform: "Linux",
      type: f.endsWith(".appimage") ? "AppImage" : (f.endsWith(".deb") ? "DEB" : "RPM"),
      arch: f.includes("x64") ? "x64" : ""
    };
  }
  if (f.includes("android")) {
    return { platform: "Android",
      type: f.endsWith(".aab") ? ".aab" : "APK",
      arch: f.includes("arm64") ? "arm64" : (f.includes("arm7") ? "arm7" :
            (f.includes("x86_64") ? "x86_64" : "universal"))
    };
  }
  return { platform: "Unknown", type: "", arch: "" };
};

const files = (await fs.readdir(assetsDir))
  .filter(f => !f.endsWith(".sha256") && !f.startsWith("Source code"));
if (!files.length) {
  console.error(`No files in ${assetsDir}`);
  process.exit(1);
}

const assets = [];
for (const f of files) {
  const full = path.join(assetsDir, f);
  const buf = await fs.readFile(full);
  const sha = createHash("sha256").update(buf).digest("hex");
  const { size } = await fs.stat(full);
  await fs.writeFile(path.join(assetsDir, f + ".sha256"), `${sha}  ${f}\n`);

  const meta = detect(f);
  assets.push({
    platform: meta.platform,
    arch: meta.arch,
    type: meta.type,
    filename: f,
    url: `${CDN_BASE}/releases/${encodeURIComponent(VERSION)}/${encodeURIComponent(f)}`,
    size,
    sha256: sha
  });
}

const latest = {
  version: VERSION,
  releasedAt: new Date().toISOString(),
  telegramChannelUrl: "https://t.me/rostovvpn",
  telegramFaqUrl: "https://t.me/rostovvpn_faq",
  microsoftStoreUrl: "https://apps.microsoft.com/store/detail/placeholder",
  assets
};

await fs.mkdir("artifacts", { recursive: true });
await fs.writeFile("artifacts/latest.json", JSON.stringify(latest, null, 2));
console.log(`latest.json generated with ${assets.length} assets`);
