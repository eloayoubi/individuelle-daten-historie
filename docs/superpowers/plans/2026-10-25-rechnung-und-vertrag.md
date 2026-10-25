# Rechnung mit Zeitraum und Vertrag mit Preisverlauf – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Versorgungszähler (Strom, Gas, Wasser) nehmen Rechnungen (Zeitraum + Verbrauch) an, und Preise stehen in einem Abschnitt „Vertrag“ mit Verlauf statt in jedem Eintrag.

**Architecture:** Kein neues Speicherformat: Eine Rechnung ist ein `Entry` mit Zeitraum und Wert im Zählerfeld eines Versorgungszählers. `CostEngine` rechnet Verbrauch über eine Tagesliste (Stände, darüber Rechnungen, Lücken gefüllt). Das Formular bekommt Modi (Rechnung, Zählerstand, Vertrag), die Zählerseite einen Abschnitt „Vertrag“ und eine Verlaufsseite je Preis.

**Tech Stack:** Flutter/Dart, flutter_bloc (Cubits), Equatable, `flutter gen-l10n` (ARB in `lib/l10n`), flutter_test/bloc_test.

**Spec:** `docs/superpowers/specs/2026-10-25-rechnung-und-vertrag-design.md`

## Global Constraints

- Versorgungszähler = Tracker mit Feld `FieldRole.meterReading` **und** Feld `FieldRole.unitPrice`. Alle anderen Tracker (Auto, Miete, Abos …) verhalten sich exakt wie vorher.
- Rechnung = Eintrag eines Versorgungszählers mit `hasPeriod` und Wert im Zählerfeld; Wert = Verbrauch in `usageUnit`, **ohne** `factor`. `Entry.date` = `periodEnd`.
- Keine Abwärtskompatibilität (Launch Dezember 2026): keine Sonderwege für Einträge mit Stand + Preisen.
- Keine Migration, keine Änderung an `TrackingCodec`, Repositories, `save_entry`.
- Code-Regeln aus `README.md`: keine festen Strings in Widgets (`context.l10n`), Formatierung über `format_x.dart`, Rechenlogik in `core/utils` bzw. `features/*/data` mit Unit-Tests.
- Neue Texte in `lib/l10n/app_de.arb` (mit `@`-Metadaten für Platzhalter) und `lib/l10n/app_en.arb`.
- Prüfen: `flutter analyze && flutter test` vor jedem Commit.

## Review Focus

- Rechnung über einen Jahreswechsel (01.10.2025–31.03.2026): Verbrauch teilt sich tagesgenau auf beide Jahre → Test in Task 2.
- Rechnungszeitraum von nur einem Tag (von = bis): kein Teilen durch 0, ganzer Verbrauch auf diesen Tag → Test in Task 2.
- Zählerstand nach einer Rechnung: Hinweis „+x seit …“ vergleicht mit dem letzten **Stand**, nie mit dem Rechnungswert → Test in Task 4.
- Nur Rechnungen, keine Stände: keine Ablese-Erinnerung (Startseite und Mitteilung) → Tests in Task 3.
- Auto mit km-Stand und Tank-Eintrag mit Zeitraum: rechnet wie vorher (bleibt Stand) → Test in Task 2.

---

### Task 1: Modell – Versorgungszähler, Rechnung, Preisänderung

**Files:**
- Modify: `lib/core/models/tracking.dart` (Klasse `Tracker`)
- Test: `test/core/tracking_test.dart` (neu)

**Interfaces:**
- Produces (alle auf `Tracker`):
  - `FieldDefinition? get meter` → `firstWithRole(FieldRole.meterReading)`
  - `bool get isUtilityMeter` → `meter != null && firstWithRole(FieldRole.unitPrice) != null`
  - `List<FieldDefinition> get rateFields` → `fields.where((f) => f.isRate)`
  - `bool isBill(Entry e)` → `isUtilityMeter && e.hasPeriod && e.values.containsKey(meter!.id)`
  - `bool isReading(Entry e)` → `meter != null && e.values.containsKey(meter!.id) && !isBill(e)`
  - `bool isPriceChange(Entry e)` → `isUtilityMeter && e.values.isNotEmpty && alle Werte gehören zu Feldern mit isRate`
  - `bool get readsFromBills` → der neueste Eintrag mit Wert im Zählerfeld (nach `date`) ist eine Rechnung; `false` ohne solche Einträge

- [ ] **Step 1: Failing tests** in `test/core/tracking_test.dart`, Gruppe `'Versorgungszähler'`:
  - `'Zähler mit Arbeitspreis ist Versorgungszähler, Auto nicht'`: Tracker [meter, unitPrice] → `isUtilityMeter` true; [meter(km), oneOffCost] → false; [unitPrice] → false.
  - `'Rechnung: Zeitraum und Wert im Zählerfeld'`: Entry mit `periodStart 2026-04-01`, `periodEnd 2026-09-30`, `{'stand': 508}` → `isBill` true, `isReading` false; ohne Zeitraum → `isBill` false, `isReading` true; gleicher Eintrag im Auto-Tracker → `isBill` false, `isReading` true.
  - `'Preisänderung trägt nur Preise'`: `{'ap': 0.32, 'gp': 12}` → true; `{'ap': 0.32, 'stand': 100}` → false; `{}` → false.
  - `'readsFromBills folgt dem neuesten Zählereintrag'`: Stand 2026-01-01, Rechnung bis 2026-06-30 → true; zusätzlich Stand 2026-07-15 → false; ohne Zählereinträge → false.
- [ ] **Step 2:** `flutter test test/core/tracking_test.dart` → FAIL (Getter fehlen).
- [ ] **Step 3:** Getter implementieren, Doku-Kommentare auf Deutsch wie im Rest der Datei.
- [ ] **Step 4:** `flutter test test/core/tracking_test.dart` → PASS.
- [ ] **Step 5:** Commit `chore: Modell kennt Versorgungszähler, Rechnungen und Preisänderungen`.

### Task 2: CostEngine – Verbrauch aus Ständen und Rechnungen

**Files:**
- Modify: `lib/core/utils/cost_engine.dart` (`_readings`, `_rates`, `_prepareReadings`, `_segmentRate`, `_rateOn`, `_computeTrend`, `hasMeter`, `lastReading`, Klassendoku)
- Test: `test/core/cost_engine_test.dart` (neue Gruppe `'Rechnungen'`)

**Interfaces:**
- Consumes: `Tracker.meter`, `isBill`, `isReading` (Task 1).
- Produces (öffentliche API unverändert): `hasMeter` = mindestens ein bekannter Tag; `lastReading` = erster Tag **nach** dem letzten bekannten Tag (bei Ständen wie bisher der Tag des letzten Stands, bei Rechnungen `periodEnd + 1`).

Approach: Tagesliste statt Abschnittsliste.

```
_first      = frühester Tag aus erstem Stand und allen periodStart
_daily      = List<double?> von _first bis (exklusiv) max(letzter Stand, periodEnd + 1)
1. Stände (nur isReading, mit factor) wie bisher zu Abschnitten; null-Abschnitte (Zählerwechsel,
   fallender Stand) per _neighbour füllen; Tage [r_i, r_i+1) setzen.
2. Rechnungen nach periodEnd aufsteigend; Tage [start, end] mit value / (end - start + 1) überschreiben
   (später endende gewinnt, Rechnung schlägt Stand).
3. Verbleibende null-Tage (Lücken) = Wert des vorigen Tags.
_segmentRate(d) = _daily[d - _first]; _trailingRate = Schnitt der letzten min(365, Länge) Tage;
_rateOn: vor _first → 0, ab lastReading → bisherige Vorjahres-/Trend-Logik; _computeTrend unverändert
über _segmentRate.
```

- [ ] **Step 1: Failing tests** (Gruppe `'Rechnungen'`, Helper `bill(DateTime from, DateTime to, num value)` → Entry mit Zeitraum, `date: to`, `{'stand': value}`; Tracker-Felder `[meter, price]`):
  - `'verteilt den Verbrauch der Rechnung auf ihre Tage'`: 2026-04-01–2026-09-30 (183 Tage), 508 → `consumption(2026-04-01, 2026-10-01)` ≈ 508; `consumption(2026-04-01, 2026-05-01)` ≈ 508 / 183 × 30; `hasMeter` true; `lastReading` == 2026-10-01.
  - `'teilt eine Rechnung über den Jahreswechsel tagesgenau'`: 2025-10-01–2026-03-31 (182 Tage), 1820 → `consumption(2025-10-01, 2026-01-01)` ≈ 920; `consumption(2026-01-01, 2026-04-01)` ≈ 900.
  - `'Rechnung über einen Tag'`: 2026-05-10–2026-05-10, 12 → `consumption(2026-05-10, 2026-05-11)` == 12.
  - `'füllt die Lücke zwischen zwei Rechnungen mit der vorigen'`: 2026-01-01–2026-01-10 (100) und 2026-01-21–2026-01-30 (200) → `consumption(2026-01-11, 2026-01-21)` ≈ 100.
  - `'Rechnung hat Vorrang vor Zählerständen'`: Stände 2026-01-01: 0, 2026-03-02: 600 (10/Tag) + Rechnung 2026-02-01–2026-02-28: 56 → `consumption(2026-02-01, 2026-03-01)` ≈ 56; `consumption(2026-01-01, 2026-02-01)` ≈ 310.
  - `'bei überlappenden Rechnungen gilt die später endende'`: 2026-01-01–2026-01-31 (310) und 2026-01-16–2026-02-14 (60) → `consumption(2026-01-16, 2026-02-01)` ≈ 32.
  - `'Rechnung beim Gas ohne Umrechnungsfaktor'`: Feld wie Gas-Test (`factor: 10`) + Preis, Rechnung 2026-01-01–2026-01-10, 1000 → `consumption(2026-01-01, 2026-01-11)` ≈ 1000.
  - `'Prognose nach der letzten Rechnung mit dem Schnitt'`: 2026-04-01–2026-09-30, 508, `today` 2026-10-25 → `consumption(2027-01-01, 2027-01-02)` ≈ 508 / 183.
  - `'Preisänderung mitten in der Rechnung'`: Rechnung 2026-01-01–2026-01-10, 100; Preis 0.30 ab 2025-01-01, 0.40 ab 2026-01-06 → `cost(2026-01-01, 2026-01-11)` ≈ 50 × 0.30 + 50 × 0.40 = 35.
  - `'Auto: Stand mit Zeitraum bleibt Stand'`: Felder `[meter(km), oneOffCost 'tank']`, Stände 2026-01-01: 1000, 2026-01-11: 1500 mit Zeitraum 2025-12-01–2025-12-31 und `'tank': 60` → `consumption(2026-01-01, 2026-01-11)` ≈ 500.
- [ ] **Step 2:** `flutter test test/core/cost_engine_test.dart` → neue Tests FAIL, alte PASS.
- [ ] **Step 3:** Umbau wie oben; Klassendoku um „Rechnungen“ ergänzen.
- [ ] **Step 4:** `flutter test test/core/cost_engine_test.dart test/features/insights test/features/home test/features/entries/tracker_history_test.dart` → alles PASS (alte Tests unverändert).
- [ ] **Step 5:** Commit `chore: Kostenrechnung versteht Rechnungen mit Zeitraum`.

### Task 3: Formeln, Kennzahlen, Erinnerungen

**Files:**
- Modify: `lib/core/utils/formulas.dart` (`variablesByEntry`)
- Modify: `lib/features/entries/data/tracker_history.dart` (`metricsFor`, `currentValuesOf`)
- Modify: `lib/features/home/data/home_overview.dart` (Ablese-Erinnerung, ~Zeile 165–173)
- Modify: `lib/features/reminders/data/reminder_planner.dart` (~Zeile 41)
- Test: `test/core/formula_test.dart`, `test/features/entries/tracker_history_test.dart`, `test/features/home/home_overview_test.dart`, `test/features/reminders/reminders_test.dart`

**Interfaces:**
- Consumes: Task 1 (`isBill`, `isReading`, `readsFromBills`, `isUtilityMeter`), Task 2 (`hasMeter`).
- Produces: `TrackerHistory.metricsFor` liefert `consumption`, sobald `readings ≥ 2 || bills ≥ 1`; `cost` zusätzlich mit `unitPrice`-Feld. `currentValuesOf` lässt bei Versorgungszählern Rate-Felder weg (die zeigt „Vertrag“) und nimmt für das Zählerfeld nur Stände.

- [ ] **Step 1: Failing tests:**
  - formula_test `'Rechnung: verbrauch ist der Rechnungswert, tage die Länge des Zeitraums'`: Felder [meter, price, Formel `verbrauch * arbeitspreis`], Rechnung 2026-04-01–2026-09-30, 508, Preis 0.30 → Variablen des Rechnungseintrags: `verbrauch` 508, `tage` 183.
  - formula_test `'Stand nach Rechnung rechnet gegen den vorigen Stand'`: Stand 2026-01-01: 1000, Rechnung 2026-02-01–2026-02-28: 50, Stand 2026-03-01: 1300 → `verbrauch` des letzten Eintrags 300.
  - tracker_history_test `'eine Rechnung reicht für Verbrauch und Kosten'`: [meter, price] mit einer Rechnung → `[cost, consumption]`.
  - tracker_history_test `'Versorgungszähler: aktuelle Werte ohne Preise, Zählerstand ohne Rechnungen'`: `currentValuesOf(tracker('c-strom'), now)` enthält kein Feld mit `isRate`; Tracker nur mit Rechnung → kein Eintrag fürs Zählerfeld.
  - home_overview_test `'keine Ablese-Erinnerung, wenn der Verbrauch aus Rechnungen kommt'`: Kategorie mit Versorgungszähler, nur Rechnung bis vor 60 Tagen → keine `ReminderKind.readMeter`.
  - reminders_test `'keine Ablese-Mitteilung bei Rechnungen'`: dasselbe für `ReminderPlanner.plan` → keine Id `read:<tracker>`.
- [ ] **Step 2:** Tests ausführen → FAIL.
- [ ] **Step 3:** Implementieren:
  - `variablesByEntry`: Rechnungseintrag setzt `verbrauch` = Wert, `tage` = `periodEnd − periodStart + 1`, `monate` = `tage / _daysPerMonth`; ändert weder `lastReading` noch `last[meter.id]`.
  - `HomeOverview`/`ReminderPlanner`: Ablese-Erinnerung nur, wenn `!tracker.readsFromBills`; der Bezugstag ist der letzte **Stand** (`isReading`).
- [ ] **Step 4:** `flutter test` → PASS.
- [ ] **Step 5:** Commit `chore: Formeln, Kennzahlen und Erinnerungen kennen Rechnungen`.

### Task 4: Formular – Rechnung, Zählerstand, Vertrag

**Files:**
- Modify: `lib/features/entries/cubit/entry_form_cubit.dart`, `lib/features/entries/cubit/entry_form_state.dart`, `lib/features/entries/view/entry_form_page.dart`
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`
- Test: `test/features/entries/entry_form_cubit_test.dart`

**Interfaces:**
- Consumes: Task 1.
- Produces:
  - `enum EntryFormMode { standard, bill, reading, contract }` (in `entry_form_state.dart`)
  - `EntryFormArgs({..., bool contract = false})` – öffnet neu im Vertragsmodus
  - `EntryFormState.mode`, `bool get canSwitchMode` (neu + Modus bill/reading), `double? get billPerMonth` (Verbrauch / Tage × 365 / 12), `bool get billOverlaps`
  - `EntryFormCubit.setMode(EntryFormMode mode)` (nur bill ↔ reading)

Regeln:
- Startmodus: kein Versorgungszähler → `standard`; `args.contract` → `contract`; vorhandener Eintrag → `bill`/`reading`/`contract` nach `isBill`/`isPriceChange`/sonst `reading`; neu → Art des neuesten Zählereintrags (`readsFromBills` → `bill`, sonst `reading`), ohne Zählereinträge `bill`.
- `fields`: `standard` wie bisher; `bill` → [meter, alle oneOffCost-Felder]; `reading` → `entryFields` ohne `isRate`; `contract` → `rateFields`.
- Rechnung neu: `periodStart` = Tag nach dem spätesten `periodEnd` einer Rechnung, sonst heute − 6 Monate (`DateTime.utc(y, m - 6, d)`); `periodEnd` = heute. `toEntry().date` = `periodEnd`. `canSave` verlangt Verbrauch. Wechsel zu `reading` löscht den Zeitraum, zurück zu `bill` setzt die Vorbelegung neu.
- `previous(meter)` überspringt Rechnungen (Hinweis „+x seit …“ nur gegen Stände).
- `validFrom` (Datum heißt „Gilt ab“) im Modus `contract` immer; Schalter „Neuer Zähler“ nur in `reading`/`standard`; Abrechnungszeitraum-Schalter nur in `standard`.
- Seite: `AppSegmented<EntryFormMode>` (Rechnung | Zählerstand) über dem Formular, wenn `canSwitchMode`; im Modus `bill` statt Datumszeile eine Gruppe Von/Bis (Footer: ungültig → `entryPeriodInvalid`, Überschneidung → `entryBillOverlap`, sonst `entryBillHint`); Zählerfeld heißt dort `entryBillConsumption`, Einheit `usageUnit`, Hinweis `entryBillPerMonth`. Im Modus `contract`: Overline `contractChange` (neu) bzw. `contractEdit` (bearbeiten), Löschen-Rückfrage `contractDeleteTitle(date)` / `contractDeleteBody(prices)` mit den Feldnamen der Preise, durch „, “ verbunden.

Neue Texte (de / en):

| Key | de | en |
|---|---|---|
| `entryKindBill` | Rechnung | Bill |
| `entryKindReading` | Zählerstand | Meter reading |
| `entryBillConsumption` | Verbrauch | Consumption |
| `entryBillPerMonth` (amount) | ≈ {amount} im Monat | ≈ {amount} per month |
| `entryBillHint` | Zeitraum und Verbrauch stehen auf deiner Rechnung. | Period and consumption are on your bill. |
| `entryBillOverlap` | Überschneidet sich mit einer anderen Rechnung – an diesen Tagen zählt die später endende. | Overlaps another bill – on those days the one ending later counts. |
| `contractChange` | Preise ändern | Change prices |
| `contractEdit` | Preisänderung | Price change |
| `contractDeleteTitle` (date) | Preisänderung vom {date} löschen? | Delete price change from {date}? |
| `contractDeleteBody` (prices) | {prices} verschwinden aus Vertrag, Kosten und Prognose. | {prices} will be removed from contract, costs and forecast. |

- [ ] **Step 1: Failing tests** (bestehende Tests, die Preise im Standardformular erwarten – `'nimmt nur gefüllte Felder in den Eintrag'`, `'Details … gehören nicht ins Formular'`, `'Gilt ab'` – auf `contract`-Modus bzw. neue Feldlisten umstellen):
  - `'Strom startet als Zählerstand, weil zuletzt abgelesen wurde'`: `mode` == reading; `fields` ids == `['f-strom-stand']`.
  - `'ohne Zählereinträge startet die Rechnung mit Vorbelegung'`: Strom-Tracker ohne Einträge, now 2026-10-22 → `mode` bill, `periodStart` 2026-04-22, `periodEnd` 2026-10-22, `canSave` false; `setText(meter, '508')` → `canSave` true, `toEntry()` hat `date` 2026-10-22, Zeitraum gesetzt, `values` `{meter: 508}`.
  - `'nächste Rechnung beginnt nach der letzten'`: Tracker mit Rechnung bis 2026-03-31 → `periodStart` 2026-04-01.
  - `'Verbrauch je Monat und Überschneidung'`: Zeitraum 2026-04-01–2026-09-30, 508 → `billPerMonth` ≈ 508 / 183 × 365 / 12; Tracker mit Rechnung 2026-09-01–2026-12-31 → `billOverlaps` true.
  - `'Zählerstand nach Rechnung vergleicht mit dem letzten Stand'`: Stand 2026-01-01: 1000, Rechnung bis 2026-06-30: 500 → `previous(meter)` == (2026-01-01, 1000).
  - `'Umschalten auf Zählerstand nimmt den Zeitraum weg'`: bill → `setMode(reading)` → `toEntry().hasPeriod` false.
  - `'Vertragsmodus: nur Preise, Gilt ab'`: `EntryFormArgs(contract: true)` → `fields` ids `['f-strom-ap', 'f-strom-gp', 'f-strom-abschlag']`, `validFrom` true; `setText('f-strom-ap', '0,35')` → `toEntry().values` == `{'f-strom-ap': 0.35}`, kein Zeitraum, `meterChange` false.
  - `'Preisänderung bearbeiten: geleertes Feld fällt weg'`: Eintrag `e-strom-p2` öffnen → `mode` contract; `setText('f-strom-gp', '')` → `toEntry().values` ohne `'f-strom-gp'`.
  - `'Auto bleibt im Standardformular'`: `mode` standard, Abrechnungszeitraum-Schalter verfügbar (`hasOneOff` true).
- [ ] **Step 2:** `flutter test test/features/entries/entry_form_cubit_test.dart` → FAIL.
- [ ] **Step 3:** State, Cubit, Seite, ARB-Texte umsetzen; `flutter gen-l10n` läuft über `flutter test`/`flutter analyze` mit (`generate: true`).
- [ ] **Step 4:** `flutter analyze && flutter test` → PASS (inkl. `test/pages_smoke_test.dart`).
- [ ] **Step 5:** Commit `Rechnungen eintragen: Zeitraum und Verbrauch statt Zählerstand`.

### Task 5: Zählerseite – Vertrag und Preisverlauf

**Files:**
- Modify: `lib/features/entries/cubit/tracker_cubit.dart`, `lib/features/entries/cubit/tracker_state.dart`, `lib/features/entries/view/tracker_page.dart`
- Create: `lib/features/entries/view/price_history_page.dart`
- Modify: `lib/features/categories/data/mock_categories_repository.dart` (Strom: Anbieter/Vertragsende aus `e-strom-p1`/`e-strom-p2` in eigene Detail-Einträge `e-strom-d1` (2024-01-01, Anbieter Stadtwerke) und `e-strom-d2` (2025-04-01, Anbieter Ökostrom Plus, Vertragsende 2027-03-31))
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`, `test/pages_smoke_test.dart`
- Test: `test/features/entries/tracker_history_test.dart` (TrackerCubit-Gruppe)

**Interfaces:**
- Consumes: Task 1, Task 3 (`currentValuesOf` ohne Preise), Task 4 (`EntryFormArgs.contract`).
- Produces:
  - `TrackerState.contract` : `List<CurrentValue>` – je Rate-Feld eines Versorgungszählers der aktuelle Wert (leer bei anderen Trackern; fehlende Werte fehlen in der Liste, die Seite zeigt „Eintragen“)
  - `TrackerState.missingPrice` : `bool` – Versorgungszähler mit Verbrauch (`CostEngine.hasMeter`), aber ohne Wert im `unitPrice`-Feld
  - `TrackerState.entries` lässt bei Versorgungszählern `isPriceChange`-Einträge weg
  - `TrackerState.priceHistory(FieldDefinition field)` : `List<Entry>` – Einträge mit Wert für `field`, neueste zuerst
  - `PriceHistoryPage.open(BuildContext context, {required TrackerCubit cubit, required String fieldId})` – liest Kategorie/Tracker aus `cubit.state` (BlocProvider.value), aktualisiert sich mit dem Cubit

Seite:
- Versorgungszähler: `SectionHeader(contractTitle)`; `AppListGroup` mit einer Zeile je `rateFields` (Wert rechts oder `contractSet` in Akzentfarbe, Untertitel wie bisher „seit …“ + `trackerUpcoming`, Antippen → `PriceHistoryPage`, Footer `contractMissingPrice` wenn `missingPrice`); darunter `TrackerDetailsGroup`; darunter `AppButton(contractChange)` (nur `canEdit`) → `EntryFormPage.open(..., contract: true)`. Abschnitt „Details“ entfällt dort; „Aktuelle Werte“ bleibt mit dem, was `currentValuesOf` liefert.
- Einträge-Liste: Rechnung → Titel `entryPeriodRange(from, to)`, Untertitel `entryKindBill` + `entryFieldValue(entryBillConsumption, context.amount(value, usageUnit))`.
- `PriceHistoryPage`: `AppHeader(title: field.name, overline: tracker.name)`; `AppListGroup` mit Zeilen `priceHistoryFrom(date)` + Wert rechts, künftige mit Untertitel `priceHistoryPlanned`; Antippen (nur `canEdit`) → `EntryFormPage.open(entry: e)`; ohne Einträge Text `priceHistoryEmpty`.

Neue Texte (de / en):

| Key | de | en |
|---|---|---|
| `contractTitle` | Vertrag | Contract |
| `contractSet` | Eintragen | Add |
| `contractMissingPrice` | Ohne Arbeitspreis rechnet die App noch keine Kosten. | Without a unit price the app can't calculate costs yet. |
| `priceHistoryFrom` (date) | ab {date} | from {date} |
| `priceHistoryPlanned` | geplant | planned |
| `priceHistoryEmpty` | Noch kein Preis eingetragen. | No price entered yet. |
| `entryPeriodRange` (from, to) | {from} – {to} | {from} – {to} |

`trackerNoEntriesBody` ändern: „Trag den ersten Wert ein – ab einer Rechnung oder dem zweiten Zählerstand entsteht der Verlauf.“ / „Add your first value – a bill or a second meter reading starts the history.“

- [ ] **Step 1: Failing tests** (TrackerCubit mit `MockCategoriesRepository`, `now` 2026-10-22):
  - `'Strom: Vertrag zeigt Arbeitspreis, Grundpreis und Abschlag'`: `state.contract.map((v) => v.field.id)` == `['f-strom-ap', 'f-strom-gp', 'f-strom-abschlag']`; Wert Arbeitspreis 0.329 seit 2025-04-01.
  - `'Preisänderungen stehen nicht in den Einträgen'`: `state.entries` enthält weder `e-strom-p1` noch `e-strom-p2`.
  - `'Preisverlauf neueste zuerst'`: `state.priceHistory(ap).map((e) => e.id)` == `['e-strom-p2', 'e-strom-p1']`.
  - `'Auto: kein Vertrag'`: `c-auto/t-golf` → `contract` leer, `missingPrice` false.
  - `'Rechnung ohne Arbeitspreis: Hinweis'`: Repository mit Versorgungszähler, Rechnung, kein Preiswert → `missingPrice` true.
- [ ] **Step 2:** Tests → FAIL.
- [ ] **Step 3:** Mock-Daten aufteilen, State/Cubit, Seite, `PriceHistoryPage`, Texte; Smoke-Test um `('price history', …)` ergänzen.
- [ ] **Step 4:** `flutter analyze && flutter test` → PASS.
- [ ] **Step 5:** Commit `Vertrag mit Preisverlauf: Arbeitspreis, Grundpreis und Abschlag einmal festlegen`.

### Task 6: Abschluss

- [ ] **Step 1:** `docs/IMPLEMENTIERUNGSPLAN.md`: bei den Strom-/Preis-Zeilen (≈ :59, :89–101) Rechnung mit Zeitraum und Vertrag/Preisverlauf nachtragen, Verweis auf die Spec.
- [ ] **Step 2:** `flutter analyze && flutter test` → PASS.
- [ ] **Step 3:** Commit `docs: Rechnung und Vertrag im Implementierungsplan`; Merge nach `main` laut `CLAUDE.md`.
