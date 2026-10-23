# FrameCraft

Eigene native macOS-App für Bildschirmaufnahme, automatische Klick-Zooms, geglättete Cursorbewegung und MP4-Export. Inspiriert vom Arbeitsablauf von Screen Studio; eigene Oberfläche, eigene Implementierung und eigene Testmedien.

**Stand: 0.3.0 · macOS 15+ · 17 Tests bestanden.** Entwicklung auf Apple Silicon mit Swift 6.4. Aufnahme auf diesem Mac in Version 0.2 praktisch geprüft; Version 0.3 mit derselben Aufnahme exportiert. Keine vollständige Screen-Studio-Nachbildung.

## Starten

- [Lokale App 0.3.0 für Apple Silicon herunterladen](artifacts/FrameCraft-0.3.0-macos-arm64.zip), entpacken und FrameCraft.app öffnen. Der Build ist lokal ad hoc signiert, nicht Developer-ID-signiert oder öffentlich notarisiert.
- Alternativ mit eingerichtetem Xcode aus dem Quellprojekt bauen:

```sh
git clone https://github.com/mnnsbstn/framecraft.git
cd framecraft
./script/build_and_run.sh --test
./script/build_and_run.sh --verify
```

Die App entsteht unter `dist/FrameCraft.app`. Das Skript fordert zum geordneten Schließen einer bereits laufenden App auf, damit keine Aufnahme verloren geht. Weitere Optionen: `--build`, `--logs`, `--debug`.

Für eine neue Aufnahme FrameCraft unter macOS → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme freigeben. Mikrofon nur bei aktivierter Mikrofonaufnahme. Nach lokalem Neubau kann macOS eine erneute Freigabe verlangen; der aktuelle 0.3-Build wurde nach Neubau noch nicht mit einer neuen Aufnahme geprüft.

## Benutzen

1. **Aufnehmen**: Fenster oder Bildschirm wählen; alternativ Video importieren oder Demo laden.
2. Aufnahme stoppen: Klick-Zooms entstehen automatisch. Unter **Zoom & Schnitt** Fokus, Stärke und Zeiten bearbeiten.
3. Unter **Gestaltung** Format, Hintergrund, Rahmen und Cursor einstellen.
4. Mit **⌘S** ein `.framecraft`-Projekt speichern; **Video exportieren** erstellt eine MP4.
5. Zum Weiterarbeiten den gesamten Projektordner über **Projekt öffnen** auswählen. Originalvideo und JSON müssen zusammenbleiben.

## Funktionen

- Fenster-/Displayaufnahme, Systemton und optionales Mikrofon; Stop auch in der Menüleiste.
- Automatische Zooms aus Klicks; neue Ziele lösen alte ab, Kameraübergänge über 600 ms, kurze Pausen ohne Zwischen-Auszoomen.
- Separate Mausspur: Glättung 0–250 ms, Größe, Sichtbarkeit und Klickmarkierungen. Keine Tastaturaufzeichnung.
- Nichtdestruktiver Schnitt, manuelle Zooms, Wiedergabe/Scrubbing, drei Seitenverhältnisse, vier Verläufe, Rahmen und Schatten.
- Gemeinsame Vorschau-/Exportpipeline, MP4 mit 30 fps, Fortschritt/Abbruch und Schutz vor Überschreiben.
- Editierbare Projekte und Kompatibilität mit älteren Projekten ohne Mausspur.

## Beispiele und Nachweise

- [Sanfte Zooms – aktueller Export](examples/FrameCraft-Sanfte-Zooms.mp4)
- [Klicktest – Export aus Version 0.2](examples/FrameCraft-Klicktest.mp4)
- [Editierbares Klicktest-Projekt](examples/FrameCraft-Klicktest.framecraft)
- [Cursor-Demo](examples/FrameCraft-Cursor-Demo.mp4) und [Demoprojekt](examples/FrameCraft-Cursor-Demo.framecraft)
- Weitere eigene Testmedien und Projekte liegen unter [examples](examples).

Live-Klicktest: 10,925 Sekunden, 10 Klicks, 590 Mauspositionen, sechs automatische Zooms. Export Full HD/30 fps ohne Ton; Klickpunkte nach Glättung exakt, Projekt erneut geöffnet. Version 0.3: 17 Tests bestanden, Build/Start/Signatur geprüft und neue Kamerafahrt exportiert. Details: [Prüfstatus](docs/Build-Status.txt), [Testprotokoll](docs/verification/tests-0.3.0.txt), [Analyse](docs/Analyse.md), [Entwicklung und Bedienung](docs/Entwicklung.md), [Changelog](CHANGELOG.md).

## Planung und Dokumentation

[Linear-Projekt](https://linear.app/mnnsbstn/project/framecraft-00c6db8009c8) · [Entwicklungsjournal](https://linear.app/mnnsbstn/document/framecraft-entwicklungsjournal-prufnachweise-und-roadmap-33f00559e3ba)

Alle bestehenden und künftigen Arbeiten einschließlich neuer, bislang ungeplanter Features werden in Linear dokumentiert. [AGENTS.md](AGENTS.md) hält die Arbeitsweise fest. [docs/Linear.md](docs/Linear.md) und [docs/linear](docs/linear) enthalten lesbare und maschinenlesbare Momentaufnahmen; Linear bleibt der aktuelle Planungsstand. Keine automatische Hintergrund-Synchronisation.

## REA und Grenzen

REA wurde dauerhaft lokal eingerichtet und zur lesenden Referenzuntersuchung verwendet. [Einrichtung/Wiederverwendung](docs/rea/REA-Nutzung.md), [Prüfbelege](docs/rea) und [Referenzbefund](docs/REA-Befunde.json). Herkunft/Integrität wurden geprüft; das ist kein vollständiges Sicherheitsaudit. Die Referenz-App wurde wegen Prüfsummen-/Signaturproblemen nicht ausgeführt und ist nicht Bestandteil dieses Repositories.

Systemton, Mikrofon und vollständige Displayaufnahme sind noch nicht praktisch abgenommen. Aktuell fester Pfeilcursor; eingebrannte Cursor importierter Videos sind nicht glättbar. Bereichsaufnahme, Webcam, Mehrclip-Schnitt, Untertitel, GIF, Cloud-Sharing, freie Exportqualität und ziehbare Zoomkanten stehen im Ideenbacklog. Sehr kurze Zoomintervalle können einen sanften Auslauf über ihr Ende hinaus haben.

## Repository-Inhalt

Quellen, Tests, lokale Build-Anweisungen, Dokumentation, REA-Belege, Linear-Snapshot, eigene Beispielprojekte/-videos und App-Archiv. Rechnerbezogene Pfade in veröffentlichten Textbelegen wurden neutralisiert. Build-Caches, Zugangsdaten und fremde Binärpakete wurden nicht übernommen. [SHA-256-Dateiliste](docs/verification/SHA256SUMS.txt) dokumentiert den veröffentlichten Stand ohne sich selbst.
