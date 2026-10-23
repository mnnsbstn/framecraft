# REA: Einrichtung und spätere Nutzung

Stand: 23. Oktober 2026, macOS auf Apple Silicon.

REA 6.4.0 ist dauerhaft für diesen macOS-Benutzer und Codex eingerichtet. Die vorhandene Installation wurde geprüft und weiterverwendet. Ergänzt wurden die passenden Arbeitsanweisungen und ein Terminal-Startbefehl. Die bestehende Codex-Konfiguration wurde nicht verändert.

## Wiederverwenden

In einem späteren Codex-Chat beispielsweise schreiben:

> Nutze REA, um das Archiv unter /absoluter/Pfad/zur/Datei.zip zu untersuchen. Zeige die enthaltenen Dateien und die Belege.

Die Werkzeuge sind in dieser Sitzung bereits verbunden. Die neu installierten Arbeitsanweisungen können ab dem nächsten Turn verfügbar sein; falls sie nicht erscheinen, Codex neu starten. Diese Einrichtung gilt lokal in Codex auf diesem Mac, nicht automatisch für die ChatGPT-Weboberfläche oder andere Computer.

Im Terminal funktioniert der vollständige Pfad unabhängig von der Shell-Konfiguration:

```sh
~/.local/bin/rea --version
~/.local/bin/rea --help
~/.local/bin/rea doctor --client codex --skill --json
~/.local/bin/rea mcp doctor --json
```

Wenn `~/.local/bin` im Suchpfad der Shell liegt, reicht `rea`. Es wurde kein Shell-Startprofil verändert.

## Was geprüft wurde

| Prüfung | Ergebnis |
| --- | --- |
| CLI startet | Version 6.4.0 |
| Codex-Registrierung, Laufzeit und Skill | `healthy: true`, Skill-Identität stimmt überein |
| MCP-Start und Identität | Erfolgreich, Version 6.4.0 |
| Werkzeugkatalog | 170 von 170 Werkzeugen und 6 von 6 Prompts |
| MCP-Anfrage | `binary_session` erfolgreich |
| Echte statische Archivprüfung | Selbst erstelltes ZIP mit vier bekannten Dateien erfolgreich untersucht; fünf Graphknoten einschließlich Archivwurzel, vier Kanten |
| Installierte Skill-Dateien | Alle sieben Dateien stimmen mit dem geprüften Paket überein |
| JavaScript-Test | Nach Xcode-Einrichtung bestanden: eigene Testanwendung statisch analysiert, eine JS-Datei, keine Parsefehler |
| Zusätzlicher Plist-Test | Nicht bestanden: nativer `file`-Aufruf meldet `io`; nicht als funktionsfähig bestätigt |

Das Testarchiv wurde anschließend geschlossen. Es wurde keine fremde Anwendung gestartet.

## JavaScript/Electron nach Xcode-Einrichtung

Der Nutzer hat Xcode eingerichtet. Der Swift-Compiler funktioniert nun, und REAs statische JavaScript-Analyse wurde am 23. Oktober 2026 erfolgreich mit einer eigenen kleinen Testanwendung ausgeführt. Zwei Dateien wurden erfasst, eine JavaScript-Datei geparst, keine Parsefehler. Die semantische Analyse weist weiterhin zwei Unbekannte aus; dies ist kein Nachweis vollständiger dynamischer Verhaltensanalyse. Beleg: `REA-JavaScript-Test.json`.

```sh
~/.local/bin/rea analyze-javascript-application "/absoluter/Pfad/zur/App" --json
```

Für native Dekompilierung fehlt außerdem ein eingerichteter Anbieter wie Ghidra, Hopper oder IDA. Diese Zusatzprogramme wurden nicht installiert. Daher ist REA verbunden und teilweise praktisch getestet, aber nicht für sämtliche Analysearten einsatzbereit. Ein allgemeines `doctor` kann wegen fehlender Zusatzprogramme weiterhin `environment_healthy: false` melden.

## Dauerhafte Speicherorte

- REA-Paket: `~/.codex/mcp/rea/node_modules/rea-agents`
- Festgelegte Version: `~/.codex/mcp/rea/package.json`, `rea-agents: 6.4.0`
- Abhängigkeitsauflösung: `~/.codex/mcp/rea/pnpm-lock.yaml`
- MCP-Registrierung: Abschnitt `[mcp_servers.rea]` in `~/.codex/config.toml`
- Arbeitsanweisungen: `~/.agents/skills/reverse-engineer-anything`
- Startbefehl: `~/.local/bin/rea`
- Node-Laufzeit: `~/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node`, geprüft mit Version 24.19.0

Das Paket und die Registrierung liegen außerhalb dieses Chats. Sie bleiben bei neuen Sessions erhalten. Die verwendete Node-Laufzeit wird von Codex verwaltet. Wenn sie durch eine Bereinigung oder Änderung der App entfernt wird, müssen Laufzeitpfad, Startbefehl und MCP-Registrierung repariert werden. Es wurde keine separate systemweite Node-Installation vorgenommen.

## Quellen und Sicherheitsprüfung

Die offiziellen Quellen sind das [Repository morluto/rea](https://github.com/morluto/rea), die [Projektwebsite](https://rea.tools) und das [npm-Paket rea-agents](https://www.npmjs.com/package/rea-agents). Die [offizielle Installationsanleitung](https://github.com/morluto/rea/blob/main/docs/installation.md) beschreibt Setup, MCP, Arbeitsanweisungen und Prüfungen. Hinweise auf `main` können neuer als die installierte Version sein.

Das Archiv von `rea-agents@6.4.0` wurde über HTTPS direkt von der npm-Registry geladen und gegen deren SHA-512-Integritätswert geprüft. Alle 1.161 enthaltenen Paketdateien stimmen bytegenau mit der vorhandenen Installation überein. Der Einstiegscode, der relevante Setup-Pfad und die Routine zum Installieren der Arbeitsanweisungen wurden vor deren Ausführung gelesen. Kein heruntergeladenes Shell-Installationsskript wurde ausgeführt. Dies ist eine Herkunfts- und Integritätsprüfung sowie eine gezielte Codeprüfung, kein vollständiges Sicherheitsaudit aller Abhängigkeiten.

Die Registry meldete bei der Prüfung 6.7.0 als neuesten Stand. Die bestehende Version 6.4.0 wurde bewusst beibehalten und nicht automatisch aktualisiert. Laufzeitvoraussetzungen und Funktionen neuerer Versionen müssen vor einem Update erneut geprüft werden.

## Wartung und Entfernung

Für ein Update in Codex schreiben: „Prüfe die neue offizielle REA-Version und aktualisiere die bestehende lokale Installation einschließlich passender Arbeitsanweisungen. Sichere die vorhandene Einrichtung und verifiziere den Server.“ Das ist eine lokale pnpm-Installation; `rea update` ist laut Anleitung für globale Installationen gedacht und hier nicht der richtige Standardweg.

Zur Entfernung zuerst den REA-Eintrag aus der Codex-Konfiguration entfernen, danach den REA-Skill, den Startbefehl und den Paketordner löschen. Die gemeinsam verwendete Codex-Node-Laufzeit behalten. Vor Konfigurationsänderungen eine Sicherung anlegen; die übrigen Codex-Einstellungen erhalten.

Prüfbelege liegen neben dieser Anleitung: `REA-Paketpruefung.json`, `REA-Verbindungstest.json`, `REA-Pruefstatus.json` und `REA-Archivtest.json`.
