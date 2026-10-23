# REA: setup and reuse

As of October 23, 2026, macOS on Apple Silicon.

REA 6.4.0 is configured persistently for this macOS user and Codex. The existing installation was verified and reused. Matching skill instructions and a terminal launcher were added. The existing Codex configuration was not changed.

## Reuse

For example, ask in a future Codex chat:

> Use REA to inspect the archive at /absolute/path/to/file.zip. Show its contents and evidence.

The tools were connected in the setup session. Newly installed skill instructions may become available from the next turn; restart Codex if they do not appear. This setup applies locally to Codex on this Mac, not automatically to ChatGPT on the web or other computers.

The full terminal path works independently of shell configuration:

```sh
~/.local/bin/rea --version
~/.local/bin/rea --help
~/.local/bin/rea doctor --client codex --skill --json
~/.local/bin/rea mcp doctor --json
```

If `~/.local/bin` is on PATH, `rea` is sufficient.

## Verification

| Check | Result |
| --- | --- |
| Scoped setup check | `healthy: true`, matching skill identity |
| MCP startup and identity | Successful, version 6.4.0 |
| Tool catalog | 170 of 170 tools and 6 of 6 prompts |
| MCP request | `binary_session` succeeded |
| Real static archive check | Original ZIP with four known files inspected successfully; five graph nodes including the archive root, four edges |
| Installed skill files | All seven match the verified package |
| JavaScript test | Passed after Xcode setup: original fixture analyzed statically, one JS file, no parse errors |
| Additional plist test | Failed: native `file` probe reports `io`; not confirmed working |

The test archive was closed afterward. No third-party application was launched.

## JavaScript/Electron after Xcode setup

The user completed Xcode setup. The Swift compiler now works, and REA's static JavaScript analysis succeeded on October 23, 2026 using a small original fixture. Two files were inventoried, one JavaScript file parsed, and no parse errors reported. Semantic analysis still reports two unknowns; this is not proof of complete dynamic behavioral analysis. Evidence: `REA-JavaScript-Test.json`.

```sh
~/.local/bin/rea analyze-javascript-application "/absolute/path/to/app" --json
```

Native decompilation also requires a configured provider such as Ghidra, Hopper, or IDA. These additional programs were not installed. REA is connected and partially tested in practice, but not ready for every analysis type. A general `doctor` check may still report `environment_healthy: false` because optional tools are missing.

## Persistent locations

- REA package: `~/.codex/mcp/rea/node_modules/rea-agents`
- Pinned version: `~/.codex/mcp/rea/package.json`, `rea-agents: 6.4.0`
- Dependency resolution: `~/.codex/mcp/rea/pnpm-lock.yaml`
- MCP registration: `[mcp_servers.rea]` in `~/.codex/config.toml`
- Skill instructions: `~/.agents/skills/reverse-engineer-anything`
- Launcher: `~/.local/bin/rea`
- Node runtime: `~/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node`, checked at version 24.19.0

The package and registration live outside this chat and persist across sessions. Codex manages the Node runtime. If cleanup or an app change removes it, repair the runtime path, launcher, and MCP registration. No separate system-wide Node installation was performed.

## Sources and security review

Official sources: [morluto/rea repository](https://github.com/morluto/rea), [project website](https://rea.tools), and [rea-agents npm package](https://www.npmjs.com/package/rea-agents). The [official installation guide](https://github.com/morluto/rea/blob/main/docs/installation.md) covers setup, MCP, skill instructions, and checks. Instructions on `main` may be newer than the installed version.

The `rea-agents@6.4.0` archive was downloaded over HTTPS directly from the npm registry and checked against its SHA-512 integrity value. All 1,161 package files match the existing installation byte for byte. The entry code, relevant setup path, and skill installation routine were read before execution. No downloaded shell installer was run. This is a provenance/integrity check and targeted code review, not a full security audit of all dependencies.

At the time of verification, the registry reported 6.7.0 as the latest release. The existing 6.4.0 installation was intentionally retained rather than automatically upgraded. Runtime requirements and features of newer releases must be checked before updating.

## Maintenance and removal

For an update, ask Codex: “Review the new official REA release and update the existing local installation with matching skill instructions. Back up the setup and verify the server.” This is a local pnpm installation; according to the guide, `rea update` is intended for global installations and is not the default approach here.

To remove REA, first remove its entry from the Codex configuration, then delete the REA skill, launcher, and package directory. Keep the shared Codex Node runtime. Back up configuration before editing and preserve other Codex settings.

Evidence files next to this guide: `REA-Paketpruefung.json`, `REA-Verbindungstest.json`, `REA-Pruefstatus.json`, and `REA-Archivtest.json`.
