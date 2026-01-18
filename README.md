# Webradio

Eine schlanke iOS-App mit eingebettetem Web-UI fuer die Senderauswahl.
Die Senderdaten und das Layout liegen im HTML und werden von der App geladen.

## Struktur
- `Webradio/WebContent/index.html`: Haupt-UI fuer die App (Senderlisten, Styles, Player).
- `Webradio/WebContent/logos/`: Lokale Logos (optional).
- `index.html`: Lokale Vorschau der Web-UI im Browser.

## Sender pflegen
Sender werden in `Webradio/WebContent/index.html` als Karten gepflegt:
- `data-stream`: Direkte Stream-URL.
- `data-name`: Anzeigename (wird auch im "Jetzt spielt"-Status genutzt).
- Logo: `<img src="...">` in der `.logo`-Box.

Tipp: Streams testen (z. B. per `curl -I`), damit die URLs wirklich erreichbar sind.

## Entwicklung
1. Xcode-Projekt `Webradio.xcodeproj` oeffnen.
2. App starten (Simulator oder Geraet).
3. Fuer schnelles UI-Testen `index.html` im Browser oeffnen.

## Hinweise
- Der Ordner-Header pro Folder ist auf zwei Zeilen reduziert (Titel + Kurzbeschreibung).
- Nicht funktionierende Sender wurden entfernt; neue Streams koennen jederzeit hinzugefuegt werden.
