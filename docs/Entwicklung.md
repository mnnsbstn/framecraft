# FrameCraft

Eine eigenständige, native macOS-App für Bildschirmvideos, inspiriert vom Arbeitsablauf von Screen Studio. Eigene SwiftUI-Oberfläche und eigene Aufnahme-/Rendering-Implementierung; keine übernommenen Screen-Studio-Assets oder Programmteile.

**Status: Version 0.3.0 ist auf diesem Mac gebaut und gestartet.** 17 automatisierte Tests bestehen. Die verbesserten Kamerafahrten wurden mit dem gespeicherten Live-Klicktest exportiert und geprüft. Die Aufnahmefunktion wurde zuletzt mit Version 0.2 praktisch abgenommen. Die neue Cursor-Demo wurde exportiert; eine echte Fensteraufnahme mit manuellem Zoom wurde bereits mit Version 0.1 erfolgreich geprüft. Die Bildschirmfreigabe wurde erfolgreich erneuert. Eine echte Fensteraufnahme mit Mausbewegungen und Klicks ist ebenfalls geprüft: 10 Klicks, 6 automatische Zooms, 590 Mauspositionen, Full-HD-Export und erneutes Öffnen des Projekts erfolgreich.

## Sofort benutzen

Öffne `dist/FrameCraft.app` per Doppelklick. Die App bleibt in diesem Projektordner auch für spätere Sessions verfügbar. Der Quellcode und das Build-Skript liegen daneben; ein laufender Codex-Chat ist zum Benutzen nicht nötig.

1. **Aufnehmen** wählen, Bildschirm oder Fenster auswählen und Aufnahme starten. Alternativ ein Video importieren oder **Demo ausprobieren** verwenden.
2. Aufnahme beenden. In der Zeitleiste zu einer Stelle springen und **Zoom hinzufügen** wählen. Unter **Zoom & Schnitt** Stärke, Fokus, Zoomdauer sowie Anfang/Ende einstellen.
3. Unter **Gestaltung** Format, Verlauf, Abstand und Ecken anpassen.
4. Mit **⌘S** das editierbare Projekt sichern. Mit **Video exportieren** eine MP4-Datei erzeugen.
5. Später über **Projekt öffnen** den gesamten `.framecraft`-Ordner auswählen. Er enthält Originalvideo und Einstellungen und muss zusammenbleiben.

Die Bildschirmfreigabe für Version 0.2 wurde durch Entfernen des alten FrameCraft-Eintrags und Hinzufügen der aktuellen App erfolgreich erneuert. Andere App-Freigaben wurden nicht geändert. Falls macOS nach einem Neubau erneut fragt: unter **Systemeinstellungen → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme** FrameCraft freigeben und neu starten. Mikrofonzugriff wird nur bei aktivierter Mikrofonaufnahme benötigt.

Der aktuelle Live-Test liegt als `FrameCraft-Klicktest.mp4` und editierbares `FrameCraft-Klicktest.framecraft` daneben. Weitere Beispiele: `FrameCraft-Demo.mp4` (Hochformat) und `FrameCraft-Aufnahmetest.mp4` (echte Fensteraufnahme), jeweils mit editierbarem `.framecraft`-Projekt.

## Bauen und starten

Voraussetzungen: macOS 15 oder neuer, eingerichtetes Xcode mit Swift-Compiler. Es gibt keine Drittanbieter-Paketabhängigkeiten.

Im Projektordner:

```sh
./script/build_and_run.sh --test
./script/build_and_run.sh --verify
```

Der Run-Button dieses Codex-Chats startet ebenfalls das Build-Skript. Es erstellt `dist/FrameCraft.app`, signiert lokal und öffnet das App-Bundle. Das ist keine Developer-ID-Signatur oder Notarisierung für eine öffentliche Verteilung. Wenn FrameCraft bereits läuft, fordert das Skript zum geordneten Schließen auf, damit keine laufende Aufnahme verloren geht.

Weitere Optionen: `--build` baut ohne Start, `--logs` öffnet die App mit Loganzeige, `--debug` startet den Debugger.

## Funktionen

- Bildschirm- oder Fensteraufnahme über ScreenCaptureKit, Systemton und optional Mikrofon.
- Aufnahme beenden im Fenster oder über die Menüleiste. Die eigene App wird aus Bildschirmaufnahmen ausgeschlossen.
- MP4-/MOV-Import und eine selbst erzeugte sechssekündige Demo zum Testen ohne Bildschirmfreigabe.
- Nichtdestruktiver Anfangs-/Endschnitt, Abspielen und Scrubbing.
- Manuelle Zoomintervalle mit Stärke, Start/Ende und Fokuspunkt. Neue Aufnahmen erzeugen automatisch Zooms aus Mausklicks. Nahe Wiederholungsklicks verlängern denselben Zoom; entfernte Ziele bekommen eigene Zooms mit einer durchgehenden Kamerafahrt. Neuere Ziele lösen ältere ab, ohne später zu ihnen zurückzuspringen. Manuelle Zooms bleiben beim Neuberechnen erhalten.
- Separate Mausspur für neue Aufnahmen: ein eigener Pfeilcursor, einstellbare Glättung (0–250 ms), Größe, Sichtbarkeit und Klickmarkierungen. Identisch in Vorschau und Export.
- Vier eigene Farbverläufe, Abstand, Eckenradius und fester Schatten; 16:9, 9:16 und 1:1.
- Gemeinsame Core-Image-Komposition für Vorschau und MP4-Export, 30 fps, Fortschritt und Abbruch.
- Projektordner mit Originalvideo und JSON-Bearbeitungseinstellungen; Speichern und erneutes Öffnen.

Aufnahmedateien werden nach ausdrücklichem Start in `~/Movies/FrameCraft` gespeichert. Die neue App fordert ihre Bildschirm-/Mikrofonfreigabe selbst an. Der praktische Aufnahmetest verwendete ausschließlich ein eigenes TextEdit-Testfenster ohne Systemton und Mikrofon. Mausdaten werden ausschließlich während laufender Aufnahmen erfasst und auf die Aufnahmequelle begrenzt. Es werden keine Tastatureingaben erfasst. Sichere das `.framecraft`-Projekt, damit die separate Mausspur erhalten bleibt; die reine Original-MP4 enthält bei neuen Aufnahmen keinen eingebrannten Cursor.

Die erste Version enthält keine Bereichsaufnahme, Webcam-Komposition, wechselnde Cursorformen (z. B. Textcursor), Mehrclip-Schnitte, Untertitel, GIF, Cloud-Sharing oder freie Exportqualitätsauswahl. Zoomintervalle werden über Regler bearbeitet; Ziehen ihrer Kanten in der Zeitleiste ist noch nicht implementiert. Es ist keine vollständige Screen-Studio-Nachbildung.

## Sanfte Kamerafahrten (Version 0.3)

Schnelle Klickfolgen werden als zeitliche Folge von Kamerazielen abgespielt. Die Fahrt wird über 600 ms geglättet; ein neuer Klick übernimmt die laufende Bewegung ohne Sprung in Position oder Geschwindigkeit. Pausen von bis zu 300 ms zwischen Zoomintervallen bleiben innerhalb derselben Aufnahmefahrt. Manuelle Zooms haben weiterhin Vorrang. Die Berechnung ist für Vorschau und Export identisch und auch beim Springen in der Zeitleiste reproduzierbar.

Die Verbesserung gilt sofort auch für vorhandene Projekte. Öffne zum Beispiel `FrameCraft-Klicktest.framecraft` und exportiere neu. `FrameCraft-Sanfte-Zooms.mp4` ist der neue Export; `FrameCraft-Klicktest.mp4` bleibt als Vergleich mit Version 0.2 erhalten. Sehr kurze Zoomintervalle werden sanft ein- und ausgeblendet; ihr Auslauf kann bis zu 600 ms nach dem letzten Zielwechsel dauern.

Vier neue Tests prüfen ausbleibende Rücksprünge, kontinuierliche Bewegung bei schnellen Zielwechseln, gültige Bildausschnitte, kurze Pausen, manuelle Priorität, Zeitleistensprünge und sehr kurze Zooms. Mit den bisherigen 13 Tests sind es 17 bestandene Tests.

## Klick-Zooms und Cursor verwenden

Bei **neuen Aufnahmen** werden Zooms nach dem Stoppen automatisch gesetzt. Unter **Zoom & Schnitt → Zooms aus Klicks erzeugen** lassen sie sich erneut berechnen. Ein bearbeiteter Zoom wird manuell und bleibt erhalten.

Unter **Gestaltung → Cursor** kannst du den Cursor ein-/ausblenden, die Glättung und Größe verändern und Klickmarkierungen abschalten. 120 ms ist die Vorgabe. Die Glättung wird an Klickzeitpunkten zum aufgezeichneten Trefferpunkt zurückgeführt. Außerhalb der Aufnahmequelle und bei längeren Datenlücken wird der Cursor ausgeblendet. Die eigene App wird nicht als Klickziel aufgezeichnet.

Alte Projekte und importierte Videos erhalten keine erfundenen Mausdaten: Ein bereits eingebrannter Cursor kann nicht nachträglich entfernt oder geglättet werden. Die neue **Demo ausprobieren**-Funktion enthält eine separate Mausspur zum direkten Testen. `FrameCraft-Cursor-Demo.mp4` und das zugehörige Projekt liegen im Ausgabeordner.

## Verifiziert am 23. Oktober 2026

- Release-Build mit Apple Swift 6.4, App-Start und strenge Prüfung der lokalen Ad-hoc-Signatur erfolgreich.
- Ursprüngliche sieben Tests bestanden: Zoomrampen, automatische Zoomauswahl, Projektdaten-Rundlauf, Quer-/Hochformatexport, Schutz von Original und vorhandenen Zieldateien sowie Exportabbruch.
- Automatisierte Videoexporttests: Schnitt von Sekunde 1 bis 4 ergibt 3 Sekunden; Ausgabegrößen 1920 × 1080 und 1080 × 1920; Videobilder decodierbar.
- Oberfläche: Demo laden, trimmen, Zoom wählen, Fokus verändern, Hintergrund/Format ändern, speichern, exportieren und Projekt wieder öffnen geprüft.
- Hochformat-Demo: 4,8 Sekunden, 1080 × 1920, sichtbarer Verlauf und Zoom.
- Reale Fensteraufnahme: 11,885 Sekunden, manuell gesetzter Zoom, Export 1920 × 1080. Beide Exportbilder zusätzlich decodiert und visuell geprüft; keine Tonspuren wie beabsichtigt.
- Gespeichertes Demoprojekt erneut geöffnet: Titel, Hochformat, Schnitt 0,6–5,4 Sekunden und zwei Zooms erhalten; Wiedergabe startet.

Zusätzlich bestehen sechs neue Tests für messbare Glättung, exakte Klickpositionen, ausgeblendete Intervalle/Datenlücken, alte Projekte, Mausspur-Speicherung, Klickgruppierung sowie sichtbare Cursorpixel im Export (insgesamt 13 Tests). Systemton, Mikrofon und vollständige Displayaufnahme sind weiterhin nicht praktisch abgenommen. Im früheren Fenster-Test gab es keine Klickdaten; manuelle Zooms funktionierten. Der abschließende Live-Test mit echter Maus/Trackpad ist bestanden: 10,925 Sekunden Fensteraufnahme, 10 Klicks, 6 automatische Zooms mit 1,8× und 590 Mauspositionen (373 innerhalb des sichtbaren Testfensters). Die sechs Zoomintervalle lassen sich aus den gespeicherten Klicks identisch neu erzeugen. Die geglättete Spur trifft alle zehn gespeicherten Klickpositionen exakt. Export: 1920 × 1080, 30 fps, 10,925 Sekunden, keine Tonspur; Bilder vor dem Zoom und an mehreren Klickstellen decodiert, Cursor und Zoomwirkung visuell geprüft. Das Projekt wurde erneut geöffnet; alle zehn Klicks und sechs Zooms sind erhalten. Die vorherigen fernbedienten Tests ohne globale Mausbewegungen sind damit als Testmethoden-Grenze eingeordnet. Die neue Demo wurde mit Cursor und automatischen Zooms exportiert (6 s, 1920 × 1080); Glättung/Größe wurden über die Oberfläche geändert und nach erneutem Öffnen korrekt wiederhergestellt (145 ms, 1,4×). Webcam, wechselnde Cursorformen, Mehrclip-Schnitt und weitere oben genannte Funktionen sind nicht enthalten. Einige verwendete AVFoundation-Aufrufe erzeugen Deprecation-Warnungen; Build und Tests bestehen auf diesem Mac.

## Referenzuntersuchung mit REA

Screen Studio war in den geprüften Programmordnern, Downloads und per Spotlight nicht auffindbar. Stattdessen wurde das auf der offiziellen Downloadseite verlinkte Apple-Silicon-Paket `4.1.0-5005` heruntergeladen und ausschließlich lesend untersucht.

REA inventarisierte das DMG mit 4.260 Inhaltsknoten. Es erkannte neun Widersprüche zwischen internen ASAR-Prüfsummen und den beobachteten Dateien. Die anschließende Paketinventur nutzte ausdrücklich `record-and-continue`; diese Inhalte bleiben als nicht vertrauenswürdig markiert. Auch die lokale strenge macOS-Signaturprüfung meldete eine ungültige Signatur. Die Diskimage-Prüfsumme selbst war gültig; das bestätigt keine gültige App-Signatur. Die Referenz-App wurde nicht ausgeführt oder installiert, das Diskimage wieder ausgeworfen.

Die Paketstruktur zeigt eine Electron-Hülle (`app.asar`, `dist-electron/index.js`) mit nativen Hilfsprogrammen. Daraus lassen sich keine ausgeführten Algorithmen oder exakte Zoomparameter ableiten. Die Funktionsvorgaben stammen zusätzlich aus den offiziellen Guides; FrameCraft verwendet dafür eigene Algorithmen und Apples APIs.

Siehe `docs/REA-Befunde.json`, `docs/Analyse.md` und `docs/Build-Status.txt` für Quellen, Belege und Grenzen.

## Entwicklung in Linear

[FrameCraft-Projekt](https://linear.app/mnnsbstn/project/framecraft-00c6db8009c8) · [Entwicklungsjournal und Roadmap](https://linear.app/mnnsbstn/document/framecraft-entwicklungsjournal-prufnachweise-und-roadmap-33f00559e3ba)

Bisherige Arbeit, offene Abnahmen und Erweiterungsvorschläge sind dort als Tickets dokumentiert. Auch neu hinzukommende Features, Fehlerbehebungen und technische Änderungen werden während weiterer Arbeit nachgeführt. `AGENTS.md` hält diese Nutzeranforderung für spätere Sessions fest; `docs/Linear.md` enthält den initialen Abgleich. Keine automatische Hintergrund-Synchronisation.
