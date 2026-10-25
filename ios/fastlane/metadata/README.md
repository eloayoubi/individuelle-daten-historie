# App-Store-Texte (fastlane deliver)

Texte für App Store Connect, je Sprache ein Ordner. Hochladen mit `cd ios && fastlane metadata`
(Texte und Screenshots, ohne Binary, ohne Einreichung zur Prüfung).

## Vor dem ersten Hochladen ersetzen

Die URLs sind Platzhalter (`https://example.com/…`). Solange irgendwo noch `example.com` steht,
bricht `fastlane metadata` ab.

| Datei | Inhalt |
|---|---|
| `de-DE/privacy_url.txt`, `en-US/privacy_url.txt` | Datenschutzerklärung (Pflicht, öffentlich erreichbar) |
| `de-DE/support_url.txt`, `en-US/support_url.txt` | Support-Seite (Pflicht, z. B. Kontaktseite oder FAQ) |
| `de-DE/description.txt`, `en-US/description.txt` | die beiden Links am Ende: Datenschutz und Nutzungsbedingungen – wegen des Abos Pflicht (Richtlinie 3.1.2). Ohne eigene Nutzungsbedingungen geht Apples Standard-EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/` |

Außerdem fehlen bewusst die Kontaktdaten für das App-Review-Team. Entweder in App Store Connect
eintragen oder hier anlegen: `review_information/first_name.txt`, `last_name.txt`,
`phone_number.txt`, `email_address.txt`.

## Was wohin gehört

| Datei | App Store Connect | Grenze |
|---|---|---|
| `name.txt` | Name | 30 Zeichen |
| `subtitle.txt` | Untertitel | 30 Zeichen |
| `keywords.txt` | Keywords, mit Komma ohne Leerzeichen | 100 Zeichen |
| `promotional_text.txt` | Werbetext, jederzeit änderbar ohne neue Version | 170 Zeichen |
| `description.txt` | Beschreibung | 4000 Zeichen |
| `release_notes.txt` | Neuerungen – bei der allerersten Version überspringt deliver sie (Apple erlaubt das Feld dort nicht) | 4000 Zeichen |
| `privacy_url.txt`, `support_url.txt` | Datenschutz-URL, Support-URL | – |
| `copyright.txt` | Copyright (für alle Sprachen) | – |
| `review_information/notes.txt` | Hinweise für das Review-Team: kein Login nötig, anonymes Konto | 4000 Zeichen |

Die Screenshots liegen in `ios/fastlane/screenshots/<sprache>/` (1320 × 2868 px, iPhone 6,9"; die
Reihenfolge im Store folgt dem Dateinamen). Neu erzeugen:

```sh
flutter test tool/screenshots/store_screenshots_test.dart --update-goldens
```

Hier nicht hinterlegt, also in App Store Connect zu setzen: Kategorie (Vorschlag: Finanzen, zweite:
Dienstprogramme – alternativ hier `primary_category.txt` mit `FINANCE` und `secondary_category.txt` mit
`UTILITIES` anlegen), Altersfreigabe, Datenschutzangaben („App Privacy“), Preis und das Abo
„Kostenkurve Cloud“ (Produkt `…plus.monthly`, 2 € im Monat).
