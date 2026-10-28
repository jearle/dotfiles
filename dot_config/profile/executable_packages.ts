#!/usr/bin/env bun
import { existsSync, readdirSync, readFileSync } from "fs";
import { homedir, platform } from "os";
import { join, basename } from "path";

interface ProfileConfig {
  macos?: {
    formulas?: string[];
    casks?: string[];
  };
  linux?: {
    packages?: string[];
    flatpak?: string[];
  };
  windows?: {
    winget?: string[];
    scoop?: string[];
  };
}

const HOME = homedir();
const MISE_PACKAGES_CONFIG = join(HOME, ".config", "mise", "packages.toml");
const PROFILE_CONFIG = join(HOME, ".config", "profile", "config.toml");

function getConfigPath(): string {
  if (existsSync(MISE_PACKAGES_CONFIG)) return MISE_PACKAGES_CONFIG;
  return PROFILE_CONFIG;
}

function getPlatform(): "macos" | "linux" | "windows" | "unknown" {
  switch (platform()) {
    case "darwin":
      return "macos";
    case "linux":
      return "linux";
    case "win32":
      return "windows";
    default:
      return "unknown";
  }
}

function runCommand(command: string[], options: { ignoreErrors?: boolean } = {}): { success: boolean; stdout: string; stderr: string } {
  try {
    const proc = Bun.spawnSync(command, {
      stdout: "pipe",
      stderr: "pipe",
      env: process.env,
    });
    return {
      success: proc.exitCode === 0,
      stdout: proc.stdout.toString(),
      stderr: proc.stderr.toString(),
    };
  } catch (error) {
    if (!options.ignoreErrors) {
      console.error(`Failed to execute: ${command.join(" ")}`, error);
    }
    return { success: false, stdout: "", stderr: String(error) };
  }
}

function loadConfig(): ProfileConfig {
  const configPath = getConfigPath();
  if (!existsSync(configPath)) {
    return {};
  }
  const content = readFileSync(configPath, "utf-8");
  return Bun.TOML.parse(content) as ProfileConfig;
}

function installOrReport(command: string[]): void {
  const result = runCommand(command);
  if (!result.success) {
    console.error(`Failed: ${command.join(" ")}\n${result.stderr.trim()}`);
  }
}

function syncMise(): void {
  const miseBinary = getPlatform() === "windows" ? "mise" : runCommand(["which", "mise"], { ignoreErrors: true }).stdout.trim() || "mise";
  const result = runCommand([miseBinary, "install", "-y"]);
  if (!result.success && result.stderr) {
    console.warn("mise install warning:", result.stderr);
  }
}

function isAppInstalled(cask: string, appDirs: string[]): boolean {
  const normalizedCask = cask.toLowerCase().replace(/[^a-z0-9]/g, "");
  for (const dir of appDirs) {
    if (!existsSync(dir)) continue;
    const apps = readdirSync(dir);
    for (const app of apps) {
      if (!app.endsWith(".app")) continue;
      const normalizedApp = app.replace(/\.app$/, "").toLowerCase().replace(/[^a-z0-9]/g, "");
      if (normalizedApp === normalizedCask || normalizedApp.includes(normalizedCask) || normalizedCask.includes(normalizedApp)) {
        return true;
      }
    }
  }
  return false;
}

function syncMacOS(macosConfig?: ProfileConfig["macos"]): void {
  if (!macosConfig) return;

  const brewPrefixResult = runCommand(["brew", "--prefix"], { ignoreErrors: true });
  const brewPrefix = brewPrefixResult.success ? brewPrefixResult.stdout.trim() : "/opt/homebrew";
  const cellarDir = join(brewPrefix, "Cellar");
  const caskroomDir = join(brewPrefix, "Caskroom");
  const appDirs = ["/Applications", join(HOME, "Applications")];

  // Check formulas
  const missingFormulas: string[] = [];
  if (macosConfig.formulas) {
    for (const formula of macosConfig.formulas) {
      const formulaName = basename(formula);
      const formulaCellar = join(cellarDir, formulaName);
      const formulaOpt = join(brewPrefix, "opt", formulaName);
      if (!existsSync(formulaCellar) && !existsSync(formulaOpt)) {
        missingFormulas.push(formula);
      }
    }
  }

  // Check casks
  const missingCasks: string[] = [];
  if (macosConfig.casks) {
    for (const cask of macosConfig.casks) {
      const caskDir = join(caskroomDir, cask);
      if (existsSync(caskDir)) continue;
      if (isAppInstalled(cask, appDirs)) continue;
      missingCasks.push(cask);
    }
  }

  // Install missing formulas
  for (const formula of missingFormulas) {
    console.log(`Installing missing macOS formula: ${formula}`);
    installOrReport(["brew", "install", formula]);
  }

  // Install missing casks
  for (const cask of missingCasks) {
    console.log(`Installing missing macOS cask: ${cask}`);
    installOrReport(["brew", "install", "--cask", cask]);
  }
}

function syncLinux(linuxConfig?: ProfileConfig["linux"]): void {
  if (!linuxConfig) return;

  const hasApt = runCommand(["which", "apt-get"], { ignoreErrors: true }).success;
  const hasDnf = runCommand(["which", "dnf"], { ignoreErrors: true }).success;
  const hasPacman = runCommand(["which", "pacman"], { ignoreErrors: true }).success;
  const hasFlatpak = runCommand(["which", "flatpak"], { ignoreErrors: true }).success;

  if (linuxConfig.packages && linuxConfig.packages.length > 0) {
    console.log(`Linux packages defined: ${linuxConfig.packages.join(", ")}`);
    if (hasApt) {
      console.log("To install with apt-get, run: sudo apt-get update && sudo apt-get install -y " + linuxConfig.packages.join(" "));
    } else if (hasDnf) {
      console.log("To install with dnf, run: sudo dnf install -y " + linuxConfig.packages.join(" "));
    } else if (hasPacman) {
      console.log("To install with pacman, run: sudo pacman -Sy --noconfirm " + linuxConfig.packages.join(" "));
    }
  }

  if (linuxConfig.flatpak && linuxConfig.flatpak.length > 0 && hasFlatpak) {
    const installedFlatpaks = runCommand(["flatpak", "list", "--app", "--columns=application"], { ignoreErrors: true }).stdout;
    for (const app of linuxConfig.flatpak) {
      if (!installedFlatpaks.includes(app)) {
        console.log(`Installing Flatpak app: ${app}`);
        runCommand(["flatpak", "install", "-y", "flathub", app]);
      }
    }
  }
}

function syncWindows(windowsConfig?: ProfileConfig["windows"]): void {
  if (!windowsConfig || !windowsConfig.winget || windowsConfig.winget.length === 0) return;

  const hasWinget = runCommand(["where", "winget"], { ignoreErrors: true }).success;
  if (hasWinget) {
    for (const pkg of windowsConfig.winget) {
      console.log(`Installing Windows package via winget: ${pkg}`);
      const result = runCommand(["winget", "install", "-e", "--id", pkg, "--source", "winget", "--silent", "--accept-package-agreements", "--accept-source-agreements"]);
      if (!result.success) console.warn(`winget ${pkg}: ${result.stdout.trim().split("\n").pop()}`);
    }
  } else {
    console.log(`Windows packages defined: ${windowsConfig.winget.join(", ")}`);
  }
}

export function main(): void {
  const currentOS = getPlatform();
  const config = loadConfig();

  // 1. Sync cross-platform tools through mise directly
  syncMise();

  // 2. Route platform-specific package manager
  switch (currentOS) {
    case "macos":
      syncMacOS(config.macos);
      break;
    case "linux":
      syncLinux(config.linux);
      break;
    case "windows":
      syncWindows(config.windows);
      break;
    default:
      console.warn(`Unrecognized platform: ${platform()}`);
  }
}

if (import.meta.main) {
  main();
}
