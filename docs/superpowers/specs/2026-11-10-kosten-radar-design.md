# Kosten-Radar – Design

Stand: 10.11.2026 · umgesetzt auf `feature/kosten-radar`

## Warum

Kostenkurve zeigt bisher, was man fragt: Verlauf, Jahresvergleich, Prognose. Die Extrameile ist, dass die App **von selbst** sagt, wo Geld auf dem Spiel steht – bevor es weg ist. Niemand öffnet eine Auswertung, um zu merken, dass ein Abo 4 € teurer wurde oder dass in drei Wochen eine Kündigungsfrist endet. Das Radar tut es für ihn, mit einem Betrag in Euro und dem nächsten Schritt.

Leitsatz: **Kostenkurve findet Geld für dich – gerechnet auf deinem Gerät.**

## Use Cases

| # | Moment des Nutzers | Was das Radar zeigt | Nächster Schritt |
|---|---|---|---|
| 1 | „Hätte ich das gewusst, hätte ich gekündigt.“ | **Frist läuft ab:** Stichtag eines Vertrags in ≤ 45 Tagen, dazu was der Vertrag in den nächsten 12 Monaten kostet | Kündigungsschreiben als Vorlage, teilen oder kopieren |
| 2 | Preiserhöhung per Brief, schnell vergessen | **Preis gestiegen:** Arbeitspreis, Abo, Miete, Beitrag – eingetragen in den letzten 90 Tagen oder im Voraus – als Mehrkosten im Jahr | Verlauf öffnen |
| 3 | Böse Überraschung in der Jahresabrechnung | **Nachzahlung droht / Guthaben in Sicht:** Abschläge des Jahres gegen die gerechneten Kosten, mit passendem Abschlag | Verlauf öffnen, Abschlag anpassen |
| 4 | Verbrauch steigt unbemerkt | **Verbrauch gestiegen:** letzte 90 gemessene Tage gegen dieselben 90 Tage im Vorjahr (≥ 10 %), in Euro zum aktuellen Preis | Verlauf öffnen |

Jeder Fund erklärt in einem Satz, wie er gerechnet ist. „Ausblenden“ merkt sich den Fund je Gerät; ändert sich die Lage (neuer Preis, neuer Stichtag, anderer Abschlag), erscheint er wieder.

## Nicht-Ziele

- Keine Angebote, keine Affiliate-Links, keine Vergleichswerte anderer Haushalte (Abschnitt 9 des Implementierungsplans, eigene Einwilligung nötig).
- Kein automatischer Versand der Kündigung. Die App erstellt nur Text; verschickt wird über das Teilen-Sheet des Systems.
- Keine Rechtsberatung: Das Schreiben kündigt „zum nächstmöglichen Zeitpunkt“ und nennt keine Frist, die die App nicht kennt.

## Regeln (`features/radar/data/radar.dart`)

- **Frist:** Feld mit Zeitverhalten Stichtag, fällig in 0–45 Tagen, an einem Vertrag – Tracker mit wiederkehrendem Betrag oder Arbeitspreis und ohne reinen Zähler (das Auto mit Kilometerstand und Hauptuntersuchung ist kein Vertrag). Betrag: Kosten der nächsten 12 Monate; unter 1 € kein Fund.
- **Preis:** je Feld mit wiederkehrendem Betrag oder Arbeitspreis (keine Teilbeträge, keine Formeln, keine Abschläge). Die nächste eingetragene Änderung nach heute, sonst die letzte der vergangenen 90 Tage – nur wenn sie um ≥ 1 % steigt. Mehrkosten im Jahr: wiederkehrend Differenz je Monat × 12, Arbeitspreis Differenz × erwarteter Verbrauch der nächsten 365 Tage. Unter 5 € kein Fund.
- **Verbrauch:** nur aus Zählerständen (nicht aus Rechnungen, die verteilen gleichmäßig), wenn der letzte bekannte Tag höchstens 45 Tage zurückliegt, der Verlauf 455 Tage davor beginnt und an den Rändern beider Zeiträume ein Stand höchstens 45 Tage entfernt liegt – sonst wäre es nur ein Jahresschnitt. Mehrkosten = Mehrverbrauch × aktueller Arbeitspreis, unter 5 € kein Fund. Ausblenden gilt fürs Quartal.
- **Plausibilität:** Nicht endliche Werte, Beträge über 10 Mio. € und negative Ausgangspreise ergeben keinen Fund. Scheitert das Radar an unerwarteten Daten, bleibt es leer; die Übersicht lädt trotzdem.
- **Abschlag:** wie der Abschlags-Check der Auswertung fürs laufende Jahr; Fund ab 25 € und 5 % der Kosten. Versorgungszähler nur mit bekanntem Verbrauch.
- Tracker, deren Kosten in einer anderen Kategorie stecken, melden nur Fristen – ihre Kosten sind rechnerisch.
- Reihenfolge: Fristen nach Nähe, dann alles andere nach Betrag.

## Sicherheit und Datenschutz

- Das Radar rechnet nur auf dem Gerät aus den ohnehin geladenen Kategorien: kein neuer Netzaufruf, keine neue Tabelle, keine neue Abhängigkeit, nichts in Logs.
- Das Kündigungsschreiben entsteht lokal und verlässt die App nur, wenn der Nutzer „Teilen“ oder „Kopieren“ wählt. Es enthält den Namen des Trackers und dessen Text-Details (z. B. Anbieter, Vertragsnummer) – sichtbar im Sheet, bevor geteilt wird. Name und Anschrift sind Platzhalter, die App kennt sie nicht. Steuerzeichen, Zeilenumbrüche, Richtungs- und unsichtbare Zeichen aus diesen Angaben werden zu Leerzeichen, jede Angabe endet nach 200 Zeichen, höchstens 10 Details (in geteilten Kategorien stammen sie auch von anderen).
- Ausgeblendete Funde liegen als Liste von Kennungen (Ids, Datum und ein gerundeter Preis oder Abschlag, keine Namen) in `radar_dismissed.json` im App-Support-Ordner, höchstens 200.
- In geteilten Kategorien sehen alle Mitglieder dieselben Funde (sie sehen auch dieselben Daten); Rechte ändern sich nicht.

## Weitere Moonshot-Kandidaten (nicht in diesem Stand)

1. **Zählerstand per Foto** (Texterkennung auf dem Gerät) – Erfassen in 3 Sekunden.
2. **Abrechnung fotografieren, Felder füllen sich** (KI-Import, nur mit Einwilligung, Edge Function).
3. **Jahresrückblick zum Teilen** („Dein Jahr in Kosten“, wahlweise nur Prozente) – macht die App sichtbar.
4. **Radar als Mitteilung und Widget** – der Fund kommt zum Nutzer, nicht umgekehrt.
