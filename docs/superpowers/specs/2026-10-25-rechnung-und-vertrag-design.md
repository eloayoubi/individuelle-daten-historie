# Rechnung mit Zeitraum und Vertrag mit Preisverlauf – Design

Stand 25.10.2026. Betrifft **Versorgungszähler**: Tracker mit einem Feld der Rolle `meterReading`
*und* einem Feld der Rolle `unitPrice` (Strom, Heizung/Gas, Wasser und eigene Tracker dieser Art).
*(Meine Wahl.)* Zähler ohne Arbeitspreis – vor allem das Auto (km-Stand, Tanken, Versicherung) –
bleiben unverändert: kein Umschalter, keine Rechnung, kein Abschnitt „Vertrag“.

## Warum

Der Nutzer liest seinen Zähler nicht selbst ab. Seine Zahlen kommen von der Rechnung, z. B. „01.04.–30.09.:
508 kWh“. Heute kann die App Verbrauch nur aus zwei Zählerständen rechnen – mit Rechnungsdaten kommt man
nicht weiter.

Außerdem fragt das Formular bei jedem Eintrag Arbeitspreis, Grundpreis und Abschlag mit ab. Das wirkt,
als müsse man sie jedes Mal eintragen. Sie gehören aber zum Vertrag: einmal festlegen, bei einer
Änderung mit „gilt ab“ nachtragen, alte Werte bleiben als Verlauf sichtbar.

Intern gibt es diesen Verlauf schon: Preise (`unitPrice`, `recurringCost`, `instalment`) gelten ab dem
Datum ihres Eintrags bis zur nächsten Änderung (`CostEngine._valueAt`). Es fehlt die Oberfläche dafür.

## Ziele

1. **Rechnung eintragen:** Zeitraum von–bis und Verbrauch in diesem Zeitraum. Die App verteilt den
   Verbrauch gleichmäßig auf die Tage des Zeitraums. Danach funktionieren Verlauf, Jahresvergleich,
   Prognose und Abschlags-Check wie bei Zählerständen.
2. **Vertrag:** Arbeitspreis, Grundpreis und Abschlag stehen beim Zähler in einem Abschnitt „Vertrag“
   (zusammen mit Anbieter und Vertragsende). Das Formular für Rechnung und Zählerstand fragt sie nicht
   mehr ab.
3. **Preisverlauf:** Je Preisfeld eine Liste aller Werte mit „gilt ab“. Änderungen nachtragen,
   korrigieren, löschen. Eine Preisänderung mit Datum in der Zukunft fließt wie heute in die Prognose.
4. **Zählerstände bleiben** als zweite Möglichkeit für alle, die selbst ablesen. Rechnungen und Stände
   dürfen im selben Zähler gemischt vorkommen.

## Nicht-Ziele

- Rechnungen einlesen (Foto, PDF, Texterkennung).
- Rechnungsbetrag, Nachzahlung oder Guthaben von der Rechnung erfassen. Die App rechnet die Kosten
  selbst aus Verbrauch × Preis.
- Mehrere Tarifzonen (HT/NT), Staffelpreise, Preisbremsen.
- Vertrag schon beim Anlegen der Kategorie abfragen.
- Tracker ohne Zählerfeld (Miete, Abos, Versicherung) ändern: Dort *sind* die Einträge der Preisverlauf.
  Ihr Formular bleibt, wie es ist.

## Anti-Ziele (wäre ein Fehlschlag, auch wenn es technisch läuft)

- Man muss bei jeder Rechnung wieder Preise eintragen.
- Tracker ohne Arbeitspreis (Auto, Miete, Abos …) verhalten sich anders als vorher.

## Abwärtskompatibilität: keine

Die App geht erst im Dezember 2026 live. Vorhandene Testdaten, alte TestFlight-Versionen und alte
Eintragsformen (z. B. Zählerstand und Preise in einem Eintrag) werden nicht berücksichtigt. Demo-Daten
werden an das neue Modell angepasst.

## Was festgelegt ist

### Speicherung: ohne Migration

Eine Rechnung ist ein normaler `Entry` mit `periodStart`/`periodEnd` und einem Wert im Zählerfeld
(Rolle `meterReading`). **Hat ein Eintrag eines Versorgungszählers einen Zeitraum, ist der Wert im
Zählerfeld der Verbrauch in diesem Zeitraum, kein Zählerstand.** Bei allen anderen Trackern bleibt
ein Wert im Zählerfeld immer ein Stand, auch mit Zeitraum (Auto: km-Stand mit Tank-Abrechnung).

- `Entry.date` einer Rechnung = `periodEnd`. *(Meine Wahl.)*
- Zeitraum, Werte und Notiz laufen schon heute durch `save_entry`, `TrackingCodec`, lokale Datei,
  Warteschlange, Export und Cloud-Umzug. Datenbank und Codec bleiben unverändert – nicht aus
  Rücksicht auf Altdaten, sondern weil das vorhandene Modell reicht. *(Meine Wahl.)*
- Bei Versorgungszählern trägt ein Eintrag genau eins: eine Rechnung, einen Zählerstand oder eine
  Preisänderung. Details (Anbieter, Vertragsende) liegen wie heute in eigenen Detail-Einträgen.
- Getter wie `Tracker.isUtilityMeter` und `Tracker.isBill(e)` (Versorgungszähler + Zeitraum + Wert
  im Zählerfeld) machen die Regel im Code sichtbar. Alle Stellen, die heute Zählerstände lesen,
  müssen Rechnungen ausschließen bzw. getrennt behandeln: `CostEngine._prepareReadings`, `Formulas.variablesByEntry`,
  `EntryFormState.previous/meterDelta/meterBelow`, `TrackerHistory.metricsFor`,
  `ReminderPlanner.plan`, `HomeOverview` (Ablese-Erinnerung).
- **Einheit:** Bei Rechnungen wird der Verbrauch in der *Verbrauchseinheit* (`usageUnit`, beim Gas kWh)
  eingegeben und gespeichert, der `factor` gilt dafür nicht. Gasrechnungen nennen die kWh, und danach
  richtet sich der Preis. *(Meine Wahl.)* Bei Strom und Wasser ist die Verbrauchseinheit gleich der
  Zählereinheit.

### Rechnen (`CostEngine`)

Der Verbrauch wird aus Abschnitten mit festem Tagesverbrauch gerechnet:

- **Rechnung:** Abschnitt `[periodStart, periodEnd]` (beide Tage eingeschlossen), Tagesverbrauch =
  Verbrauch / Anzahl Tage.
- **Zählerstände:** wie heute, Abschnitt zwischen zwei Ständen, Zählerwechsel und fallende Stände
  werden wie Lücken gefüllt. Zählerwechsel an einem Tag: der Stand ohne Markierung ist der Endstand
  des alten Zählers, der markierte der Anfangsstand des neuen.
- **Vorrang:** An einem Tag, den eine Rechnung abdeckt, gilt die Rechnung, nicht ein Abschnitt aus
  Zählerständen. *(Meine Wahl – die Rechnung ist die abgerechnete Zahl.)* Überlappen sich zwei
  Rechnungen, gilt die mit dem späteren `periodEnd`. *(Meine Wahl.)* Deckt eine Rechnung nur einen Teil
  der Tage zwischen zwei Ständen, verteilt sich der Rest des gemessenen Verbrauchs (Differenz minus
  Rechnungsverbrauch in diesem Abschnitt, mindestens 0) gleichmäßig auf die übrigen Tage – so stimmt die
  Summe zwischen den Ständen.
- **Lücken** zwischen dem ersten und dem letzten bekannten Tag (z. B. ein fehlender Monat zwischen zwei
  Rechnungen) bekommen den Tagesverbrauch des nächstgelegenen Abschnitts: die erste Hälfte den davor,
  die zweite den danach.
- **Vor dem ersten** bekannten Tag zählt nichts. **Nach dem letzten** gilt die heutige Logik: derselbe
  Tag im Vorjahr × Trend, ohne Vorjahr der Durchschnitt der letzten 365 bekannten Tage.
- `hasMeter` ist wahr ab einer Rechnung oder zwei Zählerständen. `lastReading` wird zum letzten
  bekannten Tag (Ende der letzten Rechnung bzw. letzter Stand).
- Trend, Kosten (`_partsOn`), `paid`, `uncertainty` bleiben unverändert und arbeiten auf den neuen
  Abschnitten.
- **Formeln:** Für einen Rechnungs-Eintrag ist `verbrauch` der Rechnungswert, `tage`/`monate` die Länge
  des Zeitraums. Ein Rechnungswert ist nie „letzter Zählerstand“ für folgende Einträge.

### Formular „Neuer Eintrag“ bei Versorgungszählern

- Oben ein Umschalter **Rechnung | Zählerstand**. Voreinstellung: die Art des letzten Eintrags, ohne
  Einträge **Rechnung**. *(Meine Wahl.)* Beim Bearbeiten fest auf der Art des Eintrags.
- **Rechnung:** Zeitraum von, bis; Verbrauch (mit Verbrauchseinheit); dazu eigene Einmalkosten-Felder,
  falls vorhanden (verteilt auf den Zeitraum wie heute); Notiz; Belege (nur Cloud, wie heute). Vorbelegung: „von“ = Tag nach dem Ende der letzten Rechnung, ohne Rechnung sechs Monate vor
  heute; „bis“ = heute. *(Meine Wahl.)* Hinweis unter dem Verbrauch: Durchschnitt je Monat im
  Zeitraum, z. B. „≈ 85 kWh im Monat“. *(Meine Wahl.)* Bis vor von → Fehler wie heute beim
  Abrechnungszeitraum. Überschneidet sich der Zeitraum mit einer anderen Rechnung → Warnhinweis, kein
  Fehler.
- **Zählerstand:** Datum, Zählerstand, „Neuer Zähler ab diesem Stand“, übrige Felder mit Verlauf
  außer Preisen (z. B. eigene Momentwerte), Notiz, Belege. **Kein** Schalter für einen
  Abrechnungszeitraum – sonst würde aus dem Stand eine Rechnung.
- Preisfelder (`isRate`) erscheinen in diesem Formular nicht mehr.
- Alle anderen Tracker (Auto, Miete, Abos …) behalten ihr Formular unverändert, einschließlich „Gilt
  ab“ und Abrechnungszeitraum.

### Zählerseite (`TrackerPage`)

- **Abschnitt „Vertrag“** ersetzt bei Zählern „Details“ und die Preis-Zeilen in „Aktuelle Werte“:
  - Zeilen für jedes Preisfeld (Arbeitspreis, Grundpreis, Abschlag …): aktueller Wert, darunter „seit
    …“ und eine schon eingetragene künftige Änderung (wie heute in „Aktuelle Werte“). Ohne Wert:
    „Eintragen“ in Akzentfarbe.
  - Danach die Details (Anbieter, Vertragsende …) wie heute in `TrackerDetailsGroup`.
  - Darunter eine Aktion **„Preise ändern“**: öffnet das Eintragsformular im Vertragsmodus – Titel
    z. B. „Vertrag ändern“, Datum heißt „Gilt ab“, nur die Preisfelder, leere Felder bleiben
    unverändert. So lässt sich ein Anbieterwechsel (alle Preise am selben Tag) in einem Schritt
    eintragen.
- **Antippen einer Preis-Zeile** zeigt den Verlauf dieses Felds: alle Werte, neueste zuerst, mit „ab
  TT.MM.JJJJ“; künftige Werte markiert. Antippen eines Verlaufseintrags öffnet die ganze
  Preisänderung dieses Tages im Vertragsmodus (alle Preisfelder, die der Eintrag trägt).
- **Vertragsmodus bearbeitet eine Preisänderung als Ganzes** (sie trägt nur Preise):
  - Feld leeren beim Bearbeiten = dieser Preis wird aus der Änderung entfernt. Beim Anlegen heißt ein
    leeres Feld „unverändert“.
  - „Löschen“ löscht die ganze Preisänderung; die Rückfrage nennt Datum und betroffene Preise.
  - „Gilt ab“ ändern verschiebt die Preisänderung.
- **Liste „Einträge“:** Rechnungen und Zählerstände. Reine Preis-Einträge erscheinen dort nicht mehr –
  sie stehen im Vertrag. Rechnungen zeigen den Zeitraum und den Verbrauch, z. B. „01.04.–30.09.2026 ·
  508 kWh“.
- Hat der Zähler Verbrauch, aber noch keinen Arbeitspreis, zeigt die Seite einen Hinweis, dass Kosten
  erst mit Preisen im Vertrag gerechnet werden. *(Meine Wahl.)*

### Erinnerungen

Die Ablese-Erinnerung (Startseite `HomeOverview`, Mitteilung `ReminderPlanner`) gilt nur für Zähler,
deren letzter Eintrag mit Zählerfeld ein Zählerstand ist. Kommt der letzte Verbrauch aus einer
Rechnung, gibt es keine Ablese-Erinnerung. *(Meine Wahl; eine Erinnerung „Rechnung fällig“ ist ein
Nicht-Ziel.)*

### Texte

Deutsch und Englisch in `app_de.arb`/`app_en.arb`. Begriffe: „Rechnung“, „Zählerstand“, „Vertrag“,
„Preise ändern“, „Gilt ab“, „Zeitraum“, „Verbrauch“.

## Dem Bauenden überlassen

- Aufbau der Abschnitts-Berechnung in `CostEngine` (z. B. sortierte Abschnittsliste mit Binärsuche
  statt der heutigen Stand-Liste), solange die bestehenden Tests unverändert grün bleiben.
- Ob der Preisverlauf eine eigene Seite oder ein Sheet ist – im Stil der vorhandenen Seiten
  (`AppHeader`, `AppListGroup`, `CupertinoPageRoute`).
- Wie der Vertragsmodus ins Formular kommt (Parameter in `EntryFormArgs`, eigener Cubit-Zustand …).
- Demo-Daten (`mock_categories_repository.dart`): gemischte Einträge in Stände und Preisänderungen
  aufteilen; eine Rechnung ergänzen, wenn es hilft.

## Tests

- `CostEngine`: Rechnung allein; zwei Rechnungen mit Lücke; Rechnung und Zählerstände gemischt
  (Vorrang); überlappende Rechnungen; Gas mit Faktor (Rechnung ohne, Stände mit Faktor); Prognose nach
  der letzten Rechnung; Kosten mit Preisänderung mitten im Rechnungszeitraum. Alle bestehenden Tests
  unverändert grün.
- `Formulas`: `verbrauch`/`tage` bei Rechnungen; ein Stand nach einer Rechnung rechnet gegen den
  vorherigen Stand, nicht gegen den Rechnungswert.
- Formular-Cubit: Umschalter, Vorbelegung, Zeitraum ungültig, Rechnung und Zählerstand speichern keine
  Preise, Vertragsmodus speichert nur Preise mit „gilt ab“.
- Auto-Tracker (km-Stand + Tanken mit Zeitraum): rechnet und zeigt exakt wie vorher.
- `TrackerHistory`, `HomeOverview`, `ReminderPlanner`: Kennzahlen und Erinnerungen mit Rechnungen.
- Codec- und Umzugs-Tests: Rechnungs-Eintrag übersteht Hin- und Rückweg.
