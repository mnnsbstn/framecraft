# FrameCraft in Linear

Projekt: [FrameCraft](https://linear.app/mnnsbstn/project/framecraft-00c6db8009c8)

Journal: [Entwicklung, Prüfnachweise und Roadmap](https://linear.app/mnnsbstn/document/framecraft-entwicklungsjournal-prufnachweise-und-roadmap-33f00559e3ba)

Initialer Abgleich am 23. Oktober 2026: 24 Tickets, davon 11 Done und 13 Backlog; fünf Meilensteine. Diese lokale Datei ist eine Momentaufnahme. Den aktuellen Stand vor weiterer Arbeit aus Linear lesen.

# FrameCraft – Entwicklungsjournal und weitere Schritte

## Ziel und aktueller Stand
Eigenständige macOS-App für Bildschirmaufnahme, automatische Klick-Zooms, geglättete Cursorbewegung und Videoexport. Nutzerfokus: Aufnahme, Zoom und Export. Screen Studio ist Funktionsreferenz; keine fremden Assets oder Programmteile übernommen.

Stand 23. Oktober 2026: Version 0.3.0 lokal gebaut und gestartet; 17 automatisierte Tests bestanden. Die App bleibt auf diesem Mac unabhängig vom Chat nutzbar. Mindestversion macOS 15, SwiftPM/SwiftUI mit Apple-Frameworks, keine Drittanbieter-Paketabhängigkeiten.

## Entwicklung und Nachweise

### Grundlage und Version 0.1
REA 6.4.0 dauerhaft eingerichtet: Herkunft und gezielte Installationspfade geprüft; npm-SHA-512 und 1.161 Dateien verglichen. CLI/MCP, 170 Tools und 6 Prompts, Archiv- und statische JavaScript-Analyse geprüft. Offizielle Quellen: [Repository](https://github.com/morluto/rea), [Website](https://rea.tools), [npm](https://www.npmjs.com/package/rea-agents). Fehlender nativer Dekompilierungsanbieter und fehlgeschlagener Plist-/file-Test bleiben dokumentierte Grenzen.

Screen-Studio-Paket 4.1.0-5005 nur lesend untersucht: 4.260 Knoten, neun ASAR-Widersprüche, ungültige strenge App-Signatur. Die Referenz-App wurde nicht ausgeführt oder installiert. Xcode-Ersteinrichtung und Lizenz erfolgten durch den Nutzer.

Eigene native App: ScreenCaptureKit-Aufnahme, Fenster/Display-Auswahl, Start/Stop, Menüleiste, Fehlerbehandlung; Systemton/Mikrofon implementiert. Editor mit MP4/MOV-Import, Demo, Wiedergabe, Scrubbing, Schnitt, manuellen Zooms, Fokus/Stärke, drei Formaten, vier Verläufen, Abstand/Ecken/Schatten. Gemeinsame Vorschau-/Exportpipeline, MP4 mit 30 fps, Fortschritt/Abbruch und Überschreibschutz. Projektordner mit Original und JSON; erneutes Öffnen geprüft. Tonloser echter Fenstertest 11,885 Sekunden und Hochformat-Demo exportiert.

### Version 0.2 – Klicks und Cursor
Mausbewegungen und Klicks nur während Aufnahme und bezogen auf die ausgewählte Quelle erfasst; keine Tastatureingaben. Cursor separat vom Originalvideo gerendert, Glättung 0–250 ms, Größe/Sichtbarkeit und Klickmarkierung einstellbar. Exakte Klickpunkte trotz Glättung; Datenlücken und unsichtbare Bereiche berücksichtigt. Nahe Klicks gruppieren Zoomintervalle; manuelle Anpassungen bleiben beim Neuberechnen erhalten.

Nach Neubau musste ausschließlich der FrameCraft-Eintrag in macOS erneuert werden; vom Nutzer autorisiert, Touch ID/Passwort durch den Nutzer. Fernbediente UI-Klicks lieferten keine globale Mausbewegung. Daher echter Nutzer-Maustest: 10,925 Sekunden, 10 Klicks, 590 Mauspositionen (373 sichtbar), sechs automatische 1,8×-Zooms. Export 1920×1080, 30 fps, kein Audio; Frames geprüft, Klickpositionen exakt, gespeichertes Projekt erneut geöffnet. 13 Tests bestanden.

### Version 0.3 – Sanfte Kamera
Neue zeitliche Zielabfolge verhindert Rücksprünge zu älteren überlappenden Zooms. Über 600 ms geglättete Ausschnittbreite und Mittelpunkt; neue Ziele erhalten kontinuierliche Bewegung. Lücken bis 300 ms verbinden Zoomfahrten, manuelle Zooms haben Vorrang. Zustandsfreie Abfrage für reproduzierbare Vorschau, Zeitleistensprünge und Export.

Vier neue Kameratests, zusammen 17 bestanden. Release-Build, Start und strenge lokale Ad-hoc-Signaturprüfung erfolgreich. Dasselbe Live-Projekt erneut über die Oberfläche geladen und mit neuen Kamerafahrten exportiert: 10,925 Sekunden, Full HD, 30 fps, kein Ton. Mehrere Frames decodiert und visuell geprüft. Sehr kurze Zoomintervalle können einen sanften Auslauf über ihr nominelles Ende hinaus haben.

## Grenzen und nächste Schritte
- Aufnahmefreigabe nach Neubau auf 0.3 noch nicht erneut geprüft; Update-/Signierungsablauf absichern.
- Systemton, Mikrofon und vollständige Displayaufnahme sind implementiert, aber noch nicht praktisch abgenommen.
- Mehrmonitor-/Retina-Koordinaten, längere Aufnahmen, Ressourcenverbrauch und Fehlerfälle gezielt prüfen.
- Aktuell fester Pfeilcursor; importierte Videos mit eingebranntem Cursor lassen sich nicht nachträglich glätten.
- Keine Bereichsaufnahme, Webcam, Mehrclip-Schnitte, Untertitel, GIF, Cloud-Sharing oder freie Exportqualitätswahl; Zoomkanten noch nicht direkt ziehbar.
- Zusätzliche Funktionen sind Vorschläge im Backlog. Termine und Umsetzung sind nicht automatisch zugesagt.

## Ticketverzeichnis
- [SBSTN-71: REA dauerhaft einrichten und Herkunft prüfen](https://linear.app/mnnsbstn/issue/SBSTN-71/rea-dauerhaft-einrichten-und-herkunft-prufen) — Done
- [SBSTN-72: Screen-Studio-Referenz mit REA lesend untersuchen](https://linear.app/mnnsbstn/issue/SBSTN-72/screen-studio-referenz-mit-rea-lesend-untersuchen) — Done
- [SBSTN-73: Native App, lokale Build-Umgebung und Wiederverwendung aufsetzen](https://linear.app/mnnsbstn/issue/SBSTN-73/native-app-lokale-build-umgebung-und-wiederverwendung-aufsetzen) — Done
- [SBSTN-74: Bildschirm- und Fensteraufnahme implementieren](https://linear.app/mnnsbstn/issue/SBSTN-74/bildschirm-und-fensteraufnahme-implementieren) — Done
- [SBSTN-75: Editor mit Import, Vorschau, Schnitt und Gestaltung bauen](https://linear.app/mnnsbstn/issue/SBSTN-75/editor-mit-import-vorschau-schnitt-und-gestaltung-bauen) — Done
- [SBSTN-76: Gemeinsame Vorschau-/Exportpipeline und MP4-Export absichern](https://linear.app/mnnsbstn/issue/SBSTN-76/gemeinsame-vorschau-exportpipeline-und-mp4-export-absichern) — Done
- [SBSTN-77: Editierbare Projekte speichern und wieder öffnen](https://linear.app/mnnsbstn/issue/SBSTN-77/editierbare-projekte-speichern-und-wieder-offnen) — Done
- [SBSTN-78: Automatische Zooms aus aufgezeichneten Mausklicks erzeugen](https://linear.app/mnnsbstn/issue/SBSTN-78/automatische-zooms-aus-aufgezeichneten-mausklicks-erzeugen) — Done
- [SBSTN-79: Separate Mausspur, Glättung und Klickmarkierungen ergänzen](https://linear.app/mnnsbstn/issue/SBSTN-79/separate-mausspur-glattung-und-klickmarkierungen-erganzen) — Done
- [SBSTN-80: Bildschirmfreigabe erneuern und echten Klicktest abnehmen](https://linear.app/mnnsbstn/issue/SBSTN-80/bildschirmfreigabe-erneuern-und-echten-klicktest-abnehmen) — Done
- [SBSTN-81: Sanfte Kamerafahrten bei schnellen Klickfolgen implementieren](https://linear.app/mnnsbstn/issue/SBSTN-81/sanfte-kamerafahrten-bei-schnellen-klickfolgen-implementieren) — Done
- [SBSTN-82: Bildschirmfreigabe bei App-Updates zuverlässig erhalten](https://linear.app/mnnsbstn/issue/SBSTN-82/bildschirmfreigabe-bei-app-updates-zuverlassig-erhalten) — Backlog
- [SBSTN-83: Systemton und Mikrofon praktisch testen](https://linear.app/mnnsbstn/issue/SBSTN-83/systemton-und-mikrofon-praktisch-testen) — Backlog
- [SBSTN-84: Display- und Mehrmonitoraufnahme samt Mauskoordinaten abnehmen](https://linear.app/mnnsbstn/issue/SBSTN-84/display-und-mehrmonitoraufnahme-samt-mauskoordinaten-abnehmen) — Backlog
- [SBSTN-85: Lange Aufnahmen und Fehlerfälle auf Stabilität prüfen](https://linear.app/mnnsbstn/issue/SBSTN-85/lange-aufnahmen-und-fehlerfalle-auf-stabilitat-prufen) — Backlog
- [SBSTN-86: Zoomintervalle direkt in der Zeitleiste bearbeiten](https://linear.app/mnnsbstn/issue/SBSTN-86/zoomintervalle-direkt-in-der-zeitleiste-bearbeiten) — Backlog
- [SBSTN-87: Exportoptionen für Qualität, Auflösung und GIF ergänzen](https://linear.app/mnnsbstn/issue/SBSTN-87/exportoptionen-fur-qualitat-auflosung-und-gif-erganzen) — Backlog
- [SBSTN-88: Bereichsaufnahme ergänzen](https://linear.app/mnnsbstn/issue/SBSTN-88/bereichsaufnahme-erganzen) — Backlog
- [SBSTN-89: Wechselnde Cursorformen unterstützen](https://linear.app/mnnsbstn/issue/SBSTN-89/wechselnde-cursorformen-unterstutzen) — Backlog
- [SBSTN-90: Webcam-Komposition ergänzen](https://linear.app/mnnsbstn/issue/SBSTN-90/webcam-komposition-erganzen) — Backlog
- [SBSTN-91: Mehrclip-Schnitt und innere Schnitte ergänzen](https://linear.app/mnnsbstn/issue/SBSTN-91/mehrclip-schnitt-und-innere-schnitte-erganzen) — Backlog
- [SBSTN-92: Untertitel ergänzen](https://linear.app/mnnsbstn/issue/SBSTN-92/untertitel-erganzen) — Backlog
- [SBSTN-93: Cloud-Sharing als optionale Erweiterung bewerten](https://linear.app/mnnsbstn/issue/SBSTN-93/cloud-sharing-als-optionale-erweiterung-bewerten) — Backlog
- [SBSTN-94: Optionale REA-Analysearten vervollständigen](https://linear.app/mnnsbstn/issue/SBSTN-94/optionale-rea-analysearten-vervollstandigen) — Backlog

## Wiederverwenden und lokale Belege
Lokales Projekt im Codex-Arbeitsordner unter `outputs/FrameCraft`. Start per `dist/FrameCraft.app`; Aufbau/Tests über `script/build_and_run.sh`. Lokale Ad-hoc-Signatur, keine öffentliche Notarisierung.

Wichtige Dateien im Ausgabeordner:
- `FrameCraft-App.zip`, `FrameCraft-Quellprojekt.zip`
- `FrameCraft-Klicktest.framecraft` (Original, Klicks, Cursor, sechs Zooms)
- `FrameCraft-Klicktest.mp4` (Version 0.2) und `FrameCraft-Sanfte-Zooms.mp4` (Version 0.3)
- `FrameCraft-Cursor-Demo.mp4/.framecraft`, frühere Demo-/Aufnahmetest-Dateien
- `FrameCraft/README.md`, `FrameCraft/docs/Build-Status.txt`, `FrameCraft/docs/Analyse.md`
- `REA-Nutzung.md` und REA-Prüfbelege

Diese Angaben bezeichnen lokale Dateien, keine in Linear hochgeladenen Anhänge.

## Verbindliche laufende Dokumentation
Vom Nutzer ausdrücklich gewünscht: Auch bislang nicht vorgesehene Features und sonstige neue Schritte hier sauber dokumentieren.

1. Vor jeder neuen FrameCraft-Arbeit im Projekt nach passendem Ticket suchen; vorhandenes aktualisieren oder neues anlegen. Auch Fehlerbehebungen, technische Umbauten, Recherchen und Tests berücksichtigen.
2. Ziel, Anlass, Umfang und überprüfbare Abnahmekriterien eintragen. Neue Ideen klar von beauftragter Umsetzung trennen.
3. Bei Arbeitsbeginn auf In Progress setzen; bei Änderungen Entscheidungen und wesentliche Grenzen nachtragen.
4. Nach Umsetzung tatsächliches Ergebnis, Version, relevante Tests, Artefakte und verbleibende Risiken dokumentieren. Erst bei erfüllten Abnahmekriterien Done; sonst offene Arbeit explizit festhalten.
5. Dieses Journal und Projektzusammenfassung bei relevanten Releases/Solländerungen aktualisieren; unbekannte Zukunftsschritte bei Auftreten ergänzen, keine Vollständigkeit über noch unbekannte Anforderungen behaupten.
6. Zugang zu Linear vorübergehend nicht verfügbar: Fortschritt lokal dokumentieren und bei wieder verfügbarem Zugang nachtragen. Keine erfolgte Synchronisation behaupten, bevor sie verifiziert ist.

Die Regel wird zusätzlich im lokalen Projekt hinterlegt. Es gibt keine automatische Hintergrundüberwachung; Pflege erfolgt während der jeweiligen weiteren Arbeit.
