#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
CONFIG="$OPENCLAW_DIR/openclaw.json"
EXTENSION_DIR="$OPENCLAW_DIR/extensions/openclaw-weixin"

echo "==> Removing old extension..."
rm -rf "$EXTENSION_DIR"

echo "==> Backing up config..."
cp "$CONFIG" "$CONFIG.wechat"
cp "$CONFIG" "$CONFIG.nowechat"

echo "==> Stripping openclaw-weixin entries from config..."
node -e '
const fs = require("fs");
const path = process.argv[1];
const config = JSON.parse(fs.readFileSync(path, "utf8"));

function strip(obj) {
  if (Array.isArray(obj)) {
    return obj.filter(item => {
      if (typeof item === "string" && item.includes("openclaw-weixin")) return false;
      if (typeof item === "object" && item !== null && JSON.stringify(item).includes("openclaw-weixin")) return false;
      return true;
    }).map(strip);
  }
  if (typeof obj === "object" && obj !== null) {
    const result = {};
    for (const [k, v] of Object.entries(obj)) {
      if (typeof v === "string" && v.includes("openclaw-weixin")) continue;
      if (typeof v === "object" && v !== null && JSON.stringify(v).includes("openclaw-weixin")) continue;
      result[k] = strip(v);
    }
    return result;
  }
  return obj;
}

fs.writeFileSync(path, JSON.stringify(strip(config), null, 2) + "\n");
' "$CONFIG.nowechat"

echo "==> Applying stripped config..."
cp "$CONFIG.nowechat" "$CONFIG"

echo "==> Restarting gateway..."
openclaw gateway restart

echo "==> Installing plugin from local directory..."
openclaw plugins install .

echo "==> Restoring original config..."
cp "$CONFIG.wechat" "$CONFIG"

echo "==> Restarting gateway..."
openclaw gateway restart

echo "==> Done!"
