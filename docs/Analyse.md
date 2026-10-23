# Referenzanalyse und Implementierungsentscheidungen

Stand: 23. Oktober 2026.

## Beobachtungen aus REA

Untersucht wurde das über https://screen.studio/download verlinkte Paket:

`https://screenstudioassets.com/releases/4.1.0-5005/Screen%20Studio%204.1.0-5005%20Apple%20Silicon.dmg`

SHA-256: `65cd607bbf598767faf3f9498819f423b0efbb9195ec5476b7fa9d05ddbd8b71`.

- Inventur: `ev_500e3a7f3f22305bf542ebaea5071d2dc4904883f23c951792063cfe7e15c4a7`
- Inspektion: `ev_867e753db43741578063dfaeaef46ae6c42eeff0320efb758ffc21152d0767cd`
- 4.260 Inhaltsknoten, neun Integritätswidersprüche. Vollständigkeit bezieht sich auf die abgeschlossene Inventur, nicht auf eine Verhaltensanalyse.
- ASAR-Container mit JavaScript-Einstieg und nativen Hilfsdateien. Der ergänzend direkt gelesene Paketdeskriptor nennt `main: ./dist-electron/index.js` und Version `4.1.0-5005`.
- Strenge lokale Signaturprüfung: `invalid signature (code or signature have been modified)`. Aus diesem Ergebnis wird keine Behauptung über Schadsoftware abgeleitet.
- Die App wurde nicht gestartet, keine Schutzmaßnahmen oder Exportlizenzen umgangen, keine Inhalte der Referenz in die eigene App kopiert.

Der komplette REA-Evidence-Export liegt intern unter `work/screenstudio-reference/rea-evidence.json`; die nutzbare Zusammenfassung einschließlich aller neun Prüfsummenwidersprüche ist in `REA-Befunde.json` enthalten.

## Dokumentierte Verhaltensvorlage

| Frage | Offiziell dokumentiert | Eigene Umsetzung |
| --- | --- | --- |
| Was wird aufgenommen? | Bildschirm, Fenster oder Bereich | Bildschirm/Fenster mit ScreenCaptureKit; Bereich fehlt |
| Wie entstehen Zooms? | Automatisch anhand von Klicks oder manuell | Eigene Klickintervalle und manuelle Intervalle; keine Rückgewinnung des Originalalgorithmus |
| Wie werden Zooms bearbeitet? | Eigene Spur, Dauer/Fokus/Stärke | Eigene Spur zur Auswahl und Regler für Dauer/Fokus/Stärke |
| Wie gestaltet man das Video? | Hintergrund, Padding, Rundungen, Schatten | Vier selbst definierte Verläufe, Abstand/Rundung und fester Schatten |
| Wie schneidet man? | Trimmen, Teilen, Entfernen | Anfangs-/Endtrim; Mehrclip-Schnitt fehlt |
| Wie bleiben Projekte editierbar? | Speichern und erneut öffnen | Eigenes JSON-Format plus Kopie des Originalvideos |
| Wie wird ausgegeben? | MP4/GIF und weitere Exporteinstellungen | Lokaler MP4-Export mit fester 30-fps-Komposition |

Offizielle Quellen:

- [Bildschirmaufnahme](https://screen.studio/guide/recording-entire-display)
- [Fensteraufnahme](https://screen.studio/guide/recording-single-window)
- [Automatische Zooms](https://screen.studio/guide/auto-zoom)
- [Zooms bearbeiten](https://screen.studio/guide/adding-editing-zooms)
- [Manueller Zoom](https://screen.studio/guide/manual-zoom)
- [Hintergrund](https://screen.studio/guide/background)
- [Schnitt](https://screen.studio/guide/trimming)
- [Seitenverhältnis](https://screen.studio/guide/aspect-ratio)
- [Videoimport](https://screen.studio/guide/creating-project-from-existing-video)
- [Projekt speichern](https://screen.studio/guide/saving-your-project)
- [Export](https://screen.studio/guide/exporting-the-video)

## Eigenständige technische Entscheidungen

FrameCraft nutzt SwiftUI mit einer kleinen AVPlayerView-Einbindung, ScreenCaptureKit für Aufnahme, AVFoundation für Medienverwaltung und Export sowie Core Image für dieselbe Vorschau-/Exportkomposition. Es gibt keine Electron- oder FFmpeg-Abhängigkeit.

Ein Zoom ist ein Intervall mit normiertem Fokus und Vergrößerung. Ein-/Ausfahrt verwenden eine eigene Smoothstep-Rampe; überlappende Intervalle mischen ihren Fokus kontinuierlich. Die Klickgenerierung beginnt 0,45 Sekunden vor einem Klick und endet 1,65 Sekunden danach. Räumlich nahe Wiederholungsklicks verlängern den Zoom. Entfernte Klickziele erzeugen eigene Intervalle; manuelle Intervalle haben Vorrang. Dies sind eigene Entwurfswerte, keine aus Screen Studio gewonnenen Parameter.

Projektdateien referenzieren eine lokale Kopie des Originals im gewählten Projektordner. Importprüfungen begrenzen Zeitwerte, Fokuskoordinaten, Zoomstärke und Gestaltung. Export schreibt zunächst eine temporäre Datei und ersetzt weder Original noch bestehende Zieldateien.

Apple-Quellen:

- [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- [SCRecordingOutput](https://developer.apple.com/documentation/screencapturekit/screcordingoutput)
- [AVVideoComposition](https://developer.apple.com/documentation/avfoundation/avvideocomposition)

## Prüfstatus

- Herkunftslink, DMG-CRC und REA-Paketinventur: durchgeführt, Integritätsabweichungen dokumentiert.
- Build-Skript, Swift-Kompilierung, Release-App-Start und strenge lokale Ad-hoc-Signaturprüfung: erfolgreich.
- Sieben automatisierte Tests erfolgreich, darunter echte Quer-/Hochformat-MP4-Exporte mit Schnittprüfung, Originaldateischutz und Abbruch.
- Oberfläche und Vorschau praktisch geprüft; Layout und Anzeige ungespeicherter Änderungen korrigiert.
- Eigene TextEdit-Fensteraufnahme nach Nutzerfreigabe: 11,885 Sekunden, anschließend manueller Zoom und erfolgreicher MP4-Export mit 1920 × 1080.
- Demoprojekt gespeichert und wieder geöffnet: Hochformat, Schnitt, Titel und Zooms erhalten. Hochformat-MP4: 4,8 Sekunden, 1080 × 1920.
- Exportbilder decodiert und visuell geprüft. Mikrofon/Systemton waren absichtlich aus; vollständige Displayaufnahme und echte Klickerfassung sind noch nicht praktisch abgenommen.

Details zur Wiederverwendung und Grenzen stehen in `../README.md`.

## Erweiterung 0.2: Mausspur und Klick-Zooms

ScreenCaptureKit zeichnet neue Quellen mit `showsCursor = false` auf. Ein 60-Hz-Timer erfasst normierte Mauspositionen und Quartz-Klickzähler; AppKit-Monitore ergänzen genaue Klickereignisse. Die Zeitwerte werden nach Aufnahmeende gegen den ersten Video-PTS normalisiert. Fensterrahmen und Überdeckung werden anhand der Quartz-Fensterliste berücksichtigt.

Eine symmetrische zeitliche Gauß-Glättung wird einmal pro Komposition berechnet. In Klicknähe nimmt sie zugunsten der Originalposition ab; Lücken und ausgeblendete Abschnitte werden nicht überbrückt. Die Bildberechnung zeichnet den eigenen Pfeil und einen optionalen Klickimpuls vor derselben Zoomtransformation wie das Video. Die Mausspur und Optionen werden im Projekt gespeichert; alte Projekte ohne Spur bleiben lesbar.

Grenzen: einheitlicher Pfeil statt wechselnder Original-Cursorformen; Fenstergeometrie wird alle 100 ms erneuert, schnelle Fensterbewegungen können deshalb kurz abweichen. Der Timer ist keine harte Echtzeitgarantie. Die Glättung rekonstruiert keine Mausspur aus importierten Videopixeln.

Apple-Dokumentation: [Cursor im Stream](https://developer.apple.com/documentation/screencapturekit/scstreamconfiguration/showscursor), [Quartz-Ereigniszustand](https://developer.apple.com/documentation/coregraphics/cgeventsourcestateid), [Ereignisquelle](https://developer.apple.com/documentation/coregraphics/cgeventsource).


## Live-Abnahme von Klick-Zooms und Cursor (23. Oktober 2026)

Nach Erneuern ausschließlich der FrameCraft-Bildschirmfreigabe wurde eine vom Nutzer mit echter Maus/Trackpad bediente TextEdit-Fensteraufnahme geprüft. `FrameCraft-Klicktest.framecraft` enthält 10 Klicks, 590 Cursor-Samples und 6 automatische 1,8×-Zooms. Die gespeicherten Zoomintervalle sind aus den Klicks identisch reproduzierbar; die mit dem unveränderten App-Modell geglättete Spur trifft alle Klickpunkte exakt. Das Projekt wurde über die Oberfläche erneut geöffnet, die Daten bleiben erhalten.

`FrameCraft-Klicktest.mp4`: 10,925 s, 1920 × 1080, 30 fps, kein Audio. Mehrere Videobilder vor und während der Zooms wurden erfolgreich decodiert; der eigene Cursor und die Vergrößerung sind sichtbar. Die App musste hierfür nicht neu gebaut werden. Die ursprünglichen 13 automatisierten Tests bleiben auf diesem unveränderten Stand bestanden. Die früheren fernbedienten Klicks lieferten keine globalen Mausbewegungen und waren daher kein valider Test der Mausspur.


## Sanfte Kameraübergänge in Version 0.3

Die frühere gewichtete Mischung aller aktiven Zoomregionen konnte alte Ziele erneut wirksam werden lassen. `CameraPath` plant die Zielreihenfolge einmal pro Komposition. Innerhalb zusammenhängender automatischer Zoomgruppen bleibt das neueste Ziel maßgeblich; kurze Lücken bis 300 ms verbinden die Gruppen. Manuelle Zooms werden vor der Glättung als vorrangige Ziele aufgelöst.

Ein kausaler Filter mit 600 ms endlicher Antwort und quintischer Smoothstep-Funktion glättet Änderungen von Ausschnittbreite und Mittelpunkt gemeinsam. Die Überlagerung der Zieländerungen erhält Position, Geschwindigkeit und Beschleunigung beim Retargeting; eine neue Fahrt startet nicht mit Geschwindigkeit null. Die Zielausschnitte sind vorab an die Bildgrenzen angepasst. Der gemeinsame Filter hält auch Zwischenbilder innerhalb der Quelle. Zeitbasierte, zustandsfreie Abfrage mit binärer Suche ermöglicht identische Ergebnisse bei Vorschau, Scrubbing und Export ohne Berechnung aller Regionen pro Frame. Sehr kurze Intervalle können einen sanften Auslauf über ihr nominelles Ende hinaus haben.

Prüfung: 17 Tests bestanden, darunter Rücksprung-Regression bei verschieden langen überlappenden Regionen, 16 Zielwechsel im Abstand von 90 ms, kontinuierliche Position/Geschwindigkeit, gültige Ausschnitte, manuelle Priorität, kurze Pausen und kurze Zoomintervalle. Das unveränderte Live-Klickprojekt wurde über die Oberfläche geladen und als FrameCraft-Sanfte-Zooms.mp4 exportiert (10,925 s, 1920×1080, 30 fps, ohne Ton); mehrere Bilder decodiert und visuell geprüft.
