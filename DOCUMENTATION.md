# Projekt-Dokumentation: Webradio

## Ziel und Umfang
Dieses Projekt ist eine schlanke iOS-App, die eine lokal gebundelte Web-UI
fuer Senderauswahl und Wiedergabe in einem WKWebView anzeigt.
Die Web-UI ist die Quelle fuer Senderdaten, Layout und Logos.

## Architekturueberblick
- iOS-Shell: `Webradio/ContentView.swift` laedt die Web-UI und steuert den WKWebView.
- Web-UI: `Webradio/WebContent/index.html` enthaelt Senderkarten, Styles und Playerlogik.
- Browser-Vorschau: `index.html` im Projekt-Root dient als schnelle Vorschau.
- Assets: `Webradio/Assets.xcassets` enthaelt App-Icon und Farben.

## Entwicklung und Run
1. Xcode-Projekt `Webradio.xcodeproj` oeffnen.
2. Simulator oder Geraet waehlen.
3. Run starten.

Tipp fuer UI-Iterationen: `index.html` im Browser oeffnen (schneller als App-Run).

## Sender pflegen
Sender werden als Karten in `Webradio/WebContent/index.html` gepflegt.
Wichtige Attribute:
- `data-stream`: Direkt-URL des Audio-Streams.
- `data-name`: Anzeigename fuer UI und Status.
- Logo: `<img src="...">` in der `.logo`-Box.

Qualitaetssicherung:
- Stream-URLs vor dem Eintragen testen (z. B. `curl -I <url>`).
- Logos lokal in `Webradio/WebContent/logos/` ablegen und relative Pfade nutzen.

## Logo-Standard und Pflege
Logo-Format:
- PNG, 48x48 px, transparenter Hintergrund.
- Zentriert (nicht gecroppt), damit runde Logos keine Kanten verlieren.

Ort der Dateien:
- App: `Webradio/WebContent/logos/`
- Browser-Vorschau: `logos/` (Root)

Pflege-Regeln:
- Beste Quelle: offizielles Senderlogo (Website, Pressebereich, Media Kit).
- Wenn kein Logo verfuegbar: offizielles Apple-Touch-Icon/Favicon verwenden.
- Ausnahmen nach Absprache (z. B. bestimmte Sender nicht aendern).

## App-Icon aktualisieren
- Die Icon-Dateien liegen in `Webradio/Assets.xcassets/AppIcon.appiconset/`.
- Nach Austausch in Xcode pruefen, ob alle Groessen korrekt referenziert sind.

## Projektabschluss (aktueller Stand)
Status: vorerst abgeschlossen.
- Nur Wartung/Updates bei Bedarf.
- Neue Sender koennen jederzeit ergaenzt werden.

## Git-Workflow (lokal)
Empfohlener Ablauf fuer Aenderungen:
```bash
git status -sb
# Aenderungen pruefen

git add -A
# Aenderungen aufnehmen

git commit -m "Update stations and UI"
# Commit erstellen
```

Optional: Tag fuer Abschlussstand setzen:
```bash
git tag -a v1.0 -m "Projektstand v1.0"
```

## GitHub-Setup (falls noch nicht vorhanden)
1. Repository auf GitHub anlegen (z. B. `webradio`).
2. Remote setzen und pushen:
```bash
git remote add origin git@github.com:<user>/webradio.git

git branch -M main

git push -u origin main --tags
```

## GitHub-Projektabschluss
Empfehlungen fuer einen sauberen Abschluss:
- GitHub-Release fuer `v1.0` erstellen.
- Repository-Description pflegen und Topics setzen.
- Optional: Repo archivieren, wenn keine Updates geplant sind.

## Wartungshinweise
- Wenn Streams nicht mehr funktionieren, neue URLs suchen und ersetzen.
- Bei Layout-Aenderungen zuerst `index.html` im Browser testen.
- Bei Problemen mit der Web-UI sicherstellen, dass `Webradio/WebContent/`
  im App-Bundle enthalten ist.
