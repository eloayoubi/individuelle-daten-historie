# Kostenkurve – Implementierungsplan

Stand: 22.10.2026 · Meilensteine 0 bis 3 sind umgesetzt (Grundgerüst; Kategorien, Vorlagen, Feld-Editor; Erfassen, Verlauf, Erinnerungen, offline; Auswertung, Formeln, Prognose mit Spanne, Abschlags-Check), siehe README.

## 1. Idee und Problem

Wie hoch waren die Wasserkosten laut der letzten Nebenkostenabrechnung? Wie viele Kilowattstunden habe ich dieses Jahr verbraucht, wie viele letztes Jahr? Heute heißt das: Ordner holen, Dokumente durchblättern – und beim nächsten Mal ist es wieder vergessen.

**Kostenkurve** wird die persönliche Datenhistorie für alles, was regelmäßig Geld kostet oder gezählt wird:

- **Frei gestaltbar:** Nutzer legen Kategorien an (Strom, Miete, Auto …), darin Tracker (z. B. „Hauptzähler“) mit eigenen Feldern (Text, Zahl, Betrag, Prozent, Datum, Ja/Nein, Auswahl, Formel).
- **Mit Startvorlagen:** acht Standardkategorien aus der Analyse unten nehmen die Arbeit ab und bleiben voll anpassbar.
- **Verlauf und Auswertung:** Einträge mit Datum ergeben Graphen, Jahresvergleiche, Kosten je Kategorie und eine **Prognose fürs nächste Jahr**.
- **Gemeinsam:** einzelne Kategorien mit dem Partner teilen (z. B. Haushalt und Auto).
- **Später als Geschäftsmodell:** passende Angebote, wenn Daten es nahelegen (Arbeitspreis hoch, Vertrag läuft aus).

## 2. Name und App Store

| | Deutsch | Englisch |
|---|---|---|
| App-Name (Home-Bildschirm) | **Kostenkurve** | Kostenkurve |
| Store-Titel (≤ 30) | Kostenkurve – Zählerstände | Kostenkurve – Meter & Bills |
| Untertitel (≤ 30) | Strom, Wasser & Miete im Blick | Track utilities, rent & costs |
| Keywords (≤ 100) | `nebenkosten,stromverbrauch,haushaltsbuch,fixkosten,verträge,gas,heizung,wasserzähler,prognose,abo` | `utility,meter reading,electricity,bills,budget,expenses,rent,gas,water,forecast` |

**Warum dieser Name konvertiert:** kurz (11 Zeichen, auf dem Home-Bildschirm ungekürzt), sofort verständlich (Kosten + Verlauf), positiv und eigenständig – im App Store ohne gleichnamigen Treffer. Der Titel trägt das wichtigste Such-Keyword („Zählerstände“), der Untertitel die drei häufigsten Anwendungsfälle. Die Kurve ist zugleich das Markenbild (Prognose-Karte auf der Übersicht, App-Icon).

**Vor dem Launch:** Markenrecherche beim DPMA/EUIPO (Klasse 9 und 36) und Domain sichern.

**Für die Conversion zählen außerdem:** ein App-Icon mit der Kurve statt des Flutter-Standards, die ersten drei Screenshots (Prognose, Verlauf eines Zählers, Teilen mit dem Partner) und eine kurze Bewertungsbitte nach dem dritten erfolgreichen Eintrag.

## 3. Analyse: Wofür geben Haushalte in Deutschland Geld aus?

Konsumausgaben privater Haushalte 2024, Durchschnitt je Haushalt und Monat: **3.257 €** (Destatis, Laufende Wirtschaftsrechnungen).

| Bereich | €/Monat | Anteil | Für Kostenkurve |
|---|---:|---:|---|
| Wohnen, Energie, Instandhaltung | 1.181 | 36,3 % | ★★★ Kern: Miete, Nebenkosten, Strom, Heizung, Wasser |
| Nahrungsmittel, Getränke, Tabak | 457 | 14,0 % | ✗ Einzelkäufe = Haushaltsbuch |
| Verkehr | 448 | 13,8 % | ★★ Auto (Tanken, Versicherung, Steuer, Werkstatt), Deutschlandticket |
| Freizeit, Sport, Kultur | 309 | 9,5 % | ★ Abos, Mitgliedschaften |
| Gastronomie, Beherbergung | 215 | 6,6 % | ✗ |
| Innenausstattung, Haushaltsgeräte | 148 | 4,5 % | ✗ |
| Information und Kommunikation | 140 | 4,3 % | ★★ Internet, Mobilfunk, Rundfunkbeitrag |
| Bekleidung, Schuhe | 114 | 3,5 % | ✗ |
| Gesundheit | 110 | 3,4 % | ★ Zusatzbeiträge, Zuzahlungen |
| Andere Waren und Dienstleistungen | 107 | 3,3 % | – |
| Bildung | 23 | 0,7 % | – |
| Versicherungs- und Finanzdienstleistungen | 6 | 0,2 % | ★★ Versicherungsbeiträge zählt Destatis größtenteils nicht als Konsum – real ein großer Fixkostenblock |

**Folgerung:** Kostenkurve konzentriert sich auf **Fixkosten, Verbräuche und Verträge**, also auf Werte, die man selten anfasst, aber immer wieder braucht. Einzelkäufe (Lebensmittel, Restaurant) sind das Revier von Haushaltsbüchern und Banking-Apps wie Finanzguru, die mit Kontodaten arbeiten. Der Vorteil von Kostenkurve: exakte Verbrauchs- und Tarifdaten (Zählerstand, Arbeitspreis, Vertragsende) ohne Bank-Login – genau die Daten, die für Wechselangebote zählen. Eigene Kategorien bleiben für alles andere offen.

## 4. Standardvorlagen (Start-Kategorien)

Jede Vorlage legt eine Kategorie mit einem Tracker und diesen Feldern an. Danach ist alles änderbar: umbenennen, löschen, eigene Felder, weitere Tracker.

| Vorlage | Tracker | Felder (Feldtyp · Zeitverhalten · Einheit) |
|---|---|---|
| **Strom** | Hauptzähler | Zählerstand (Zahl · Zählerstand · kWh), Arbeitspreis (Betrag · Preis gilt ab · €/kWh), Grundpreis (Betrag · wiederkehrend · €/Monat), Abschlag (Betrag · Stammdatum · €/Monat), Anbieter, Tarif (Text), Vertragsende (Datum · Stichtag), Kündigungsfrist (Auswahl: 2 Wochen / 1 / 3 Monate) |
| **Heizung** | Gas, Fernwärme, Heizöl oder Pellets | Gas: Zählerstand m³ mit Umrechnung in kWh (Brennwert × Zustandszahl), Arbeitspreis €/kWh, Grundpreis. Heizöl/Pellets: Lieferung (einmaliger Betrag), Menge (l bzw. kg), Füllstand (Momentwert) |
| **Wasser** | Kalt- und Warmwasser | Zählerstand (m³), Preis Wasser + Abwasser (€/m³), Schalter „in den Nebenkosten enthalten“ (siehe 6.4) |
| **Miete & Nebenkosten** | Wohnung | Kaltmiete und NK-Vorauszahlung (wiederkehrend, gilt ab), Nebenkostenabrechnung (einmaliger Betrag mit Abrechnungszeitraum, negativ = Guthaben), Positionen der Abrechnung (Wasser, Heizung, Müll, Grundsteuer, Hausmeister, Versicherung – je Betrag), Staffel/Index (Prozent) |
| **Auto & Mobilität** | Fahrzeug | Kilometerstand (Zählerstand · km), Tanken/Laden (einmaliger Betrag + Menge l/kWh → Verbrauch je 100 km), Kfz-Versicherung und Kfz-Steuer (wiederkehrend · jährlich), Werkstatt (einmalig), Hauptuntersuchung (Stichtag); Deutschlandticket als eigener Tracker |
| **Internet, Mobilfunk & Rundfunk** | je Vertrag | Monatspreis (wiederkehrend), Datenvolumen (Zahl · GB), Mindestlaufzeit bis (Stichtag), Rundfunkbeitrag (vierteljährlich) |
| **Versicherungen** | je Police | Beitrag (wiederkehrend, Intervall frei), Selbstbeteiligung (Betrag), Versicherungsnummer (Stammdatum), Hauptfälligkeit (Stichtag) |
| **Abos & Mitgliedschaften** | je Abo | Preis (wiederkehrend), Intervall, Kündbar bis (Stichtag), Geteilt/Familie (Ja/Nein) |

Später als Vorlagen: PV-Anlage und Wallbox (Erzeugung, Einspeisung, Bezug), Kredite (Restschuld, Zinssatz %), Krankenkasse (Zusatzbeitrag %), Gehalt (Brutto/Netto-Verlauf), Haustier, Kinderbetreuung.

## 5. Datenmodell

```
Kategorie (Strom)  ── geteilt mit ──▶ Mitglieder (owner / editor / viewer)
  └─ Tracker (Hauptzähler)
       ├─ Felder: Zählerstand · Arbeitspreis · Grundpreis · Vertragsende · Anbieter …
       └─ Einträge (Datum, optional Zeitraum, Notiz, Zählerwechsel)
            └─ Werte je Feld (typisiert), Belege (Plus)
```

### 5.1 Feldtyp und Zeitverhalten

Der **Feldtyp** sagt, wie ein Wert eingegeben und angezeigt wird. Das **Zeitverhalten** sagt, wie er über die Zeit rechnet. Erst diese zweite Angabe macht Graphen und Kosten richtig, deshalb ist sie Teil jedes Feldes (Datenbank: `fields.role`, App: `FieldRole`).

| Zeitverhalten | Beispiel | Auswertung |
|---|---|---|
| Stammdatum | Zählernummer, Anbieter | kein Verlauf, zeigt den letzten Wert |
| Momentwert | Füllstand Öltank, Kontostand | Linie durch die Messpunkte |
| Zählerstand | Strom kWh, Wasser m³, km | Verbrauch = Differenz, linear auf Tage verteilt |
| Preis je Einheit (gilt ab) | Arbeitspreis 32,9 ct/kWh | gilt bis zur nächsten Änderung; × Verbrauch = Kosten |
| Wiederkehrender Betrag (gilt ab) | Miete, Grundpreis, Abo, Versicherung (Intervall 1/3/12 Monate) | auf Tage verteilt, gilt bis zur Änderung |
| Einmaliger Betrag | Tanken, Nachzahlung, Werkstatt | zählt am Tag des Eintrags, negativ = Guthaben |
| Stichtag | Vertragsende, HU, Kündigungsfrist | Erinnerung, kein Verlauf |

Die Datenbank erzwingt passende Kombinationen (ein Zählerstand ist immer eine Zahl, ein Stichtag immer ein Datum).

### 5.2 Einträge

- **Details statt Einträge:** Stammdaten und Stichtage (Anbieter, Vertragsnummer, Vertragsende) gehören nicht ins Eintragsformular. Man setzt sie direkt in der Kategorie oder im Verlauf; gespeichert werden sie als Eintrag, der nur Details trägt (`Tracker.isDetailEntry`), und erscheinen nicht in der Liste der Einträge. So laufen sie offline durch dieselbe Warteschlange, ohne eigene Tabelle.
- **Teil-Einträge:** Ein Eintrag trägt nur die Felder, die sich ändern. Der neue Zählerstand braucht keinen erneuten Arbeitspreis, eine Preiserhöhung keinen Zählerstand.
- **Im Voraus:** Eine angekündigte Erhöhung („ab 1.3. 920 € Miete“) wird mit künftigem Datum eingetragen und fließt sofort in die Prognose ein.
- **Zeitraum:** Abrechnungen haben einen Zeitraum von–bis (`period_start`/`period_end`).
- **Zählerwechsel:** Ein Eintrag mit `meter_change` startet einen neuen Zähler; den Verbrauch der Lücke schätzt die App aus dem Nachbarzeitraum.
- **Speicherung:** typisierte Werte je Feld (`entry_values`: Zahl, Text, Datum oder Ja/Nein). So lassen sich Verläufe direkt per SQL abfragen, ohne JSON zu parsen.

### 5.3 Schema-Änderungen durch Nutzer

- **Umbenennen** ist jederzeit möglich, weil alles über die Id läuft.
- **Typ ändern** geht nur in verträglicher Richtung (Zahl → Betrag ja, Text → Zahl nur mit Prüfung aller Werte).
- **Löschen** archiviert das Feld (`archived_at`); die Historie bleibt, Formeln, die es benutzen, werden markiert.

## 6. Berechnungen (`core/utils/cost_engine.dart`)

Die App rechnet auf dem Gerät, aus den Rohdaten. So nutzen Mock und Supabase denselben Code, Formeln und Prognose funktionieren offline, und der Server speichert nur Fakten.

### 6.1 Verbrauch und Kosten

Die Rechnung läuft Tag für Tag:

1. **Verbrauch:** Zwischen zwei Zählerständen wird linear verteilt. So ergibt sich auch ein sauberes Kalenderjahr, obwohl selten am 1. Januar abgelesen wird.
2. **Arbeitspreis:** Der Verbrauch des Tages wird mit dem Preis multipliziert, der an diesem Tag gilt.
3. **Wiederkehrende Beträge:** Sie werden anteilig auf die Tage des Monats verteilt.
4. **Einmalige Beträge:** Sie zählen an ihrem Tag.

Damit gelten auch Preiswechsel mitten im Monat taggenau.

### 6.2 Prognose fürs nächste Jahr (umgesetzt, wird in M3 ausgebaut)

| Quelle | Methode |
|---|---|
| Zählerstände | gleicher Tag im Vorjahr – die Saison bleibt erhalten, Heizung steigt im Winter. Ohne Vorjahr gilt der Durchschnitt der letzten 365 Tage. |
| Preise und wiederkehrende Beträge | der Wert, der dann gilt, also auch im Voraus eingetragene Erhöhungen |
| Einmalige Beträge | Tagesdurchschnitt der letzten 365 Tage (Tanken, Nachzahlungen) |

Die Übersicht vergleicht die Prognose mit dem laufenden Jahr (Ist bis heute + Hochrechnung bis Dezember).

**Ausbau in M3:**

- Trend über mehrere Jahre (z. B. −6 % Stromverbrauch pro Jahr).
- Spanne statt Punktwert („19.800–20.600 €“).
- „Was wäre wenn“: anderer Arbeitspreis, anderer Abschlag.
- Abschlags-Check: Reichen meine Abschläge, oder droht eine Nachzahlung?

### 6.3 Formeln (zum Start, Meilenstein 3)

Ein Feld vom Typ **Formel** rechnet aus anderen Feldern. Beispiele:

```
verbrauch * arbeitspreis + grundpreis * monate     → Kosten im Zeitraum
tanken_liter / gefahrene_km * 100                  → l/100 km
kaltmiete * (1 + staffel / 100)                    → Miete nach Staffel
```

- **Bezüge:** auf Felder desselben Trackers über einen Kurznamen (vom Feldnamen abgeleitet, änderbar).
- **Eingebaute Größen:** `verbrauch`, `tage`, `monate` (des Zeitraums seit dem vorigen Eintrag), `jahr`.
- **Funktionen:** `min`, `max`, `runden(x, n)`, `wenn(bedingung, a, b)`, `summe(feld, zeitraum)`, `schnitt(feld, zeitraum)`.
- **Auswertung:**
  - Formeln **pro Eintrag** (z. B. l/100 km beim Tanken) entstehen beim Anzeigen.
  - Formeln **pro Zeitraum** (z. B. Kosten eines Monats) entstehen in der Auswertung.
  - Ergebnisse werden nicht gespeichert, nur der Ausdruck (`fields.formula`).
- **Umsetzung:** ein kleiner eigener Parser in Dart (Pratt-Parser, ~300 Zeilen). Kein `eval`, keine Schleifen, Tiefe begrenzt.
- **Fehler:** Die Fehlermeldung zeigt die Stelle im Ausdruck. Ein Formel-Editor schlägt Feldnamen vor und zeigt eine Live-Vorschau mit dem letzten Eintrag.
- **Rolle in der Kostenrechnung:** Eine Formel darf das Zeitverhalten Betrag oder Preis haben und fließt dann in Kosten und Prognose ein.

### 6.4 Doppelt gezählte Kosten vermeiden

Mieter zahlen Wasser und oft die Heizung über die Nebenkosten. Wer zusätzlich die Zähler erfasst, hätte diese Kosten doppelt. Lösung: Ein Tracker kann „in Kategorie X enthalten“ sein. Er zeigt dann Verbrauch und rechnerische Kosten, die Summen zählen ihn aber nicht. Die Beispieldaten zeigen den einfachsten Fall: Wasser nur mit Verbrauch.

## 7. Teilen mit dem Partner

Geteilt wird **je Kategorie**: Haushalt und Auto mit dem Partner, das eigene Handy nicht.

| | |
|---|---|
| Rollen | **owner** (alles, teilt, löscht) · **editor** (Einträge, Tracker, Felder) · **viewer** (nur lesen) |
| Einladen | „Teilen“ an der Kategorie → Rolle wählen → Code, Link oder QR (10 Zeichen, 7 Tage gültig, einmalig) → Partner öffnet den Link oder tippt den Code ein |
| Anzeige | geteilte Kategorien erscheinen bei beiden in der Übersicht, mit dem Hinweis „Geteilt mit Anna“; Einträge zeigen, wer sie erfasst hat |
| Verlassen/Entfernen | jedes Mitglied kann gehen, der owner kann entfernen und Rollen ändern |
| Live | Realtime auf `entries` der geteilten Kategorien: Trägt der Partner den Zählerstand ein, aktualisiert sich die Übersicht sofort |
| Konflikte | ein Eintrag = eine Zeile, zuletzt Gespeichertes gewinnt; gleichzeitiges Bearbeiten desselben Eintrags ist selten |

**Voraussetzung: Konto sichern.** Anonyme Konten hängen am Gerät. Vor dem ersten Teilen (und als Hinweis nach einigen Einträgen) bittet die App, das Konto mit **Apple, Google oder E-Mail** zu sichern. Dafür verknüpft `linkIdentity` bzw. `updateUser` das vorhandene anonyme Konto: Daten und Id bleiben gleich, nichts wird kopiert.

**Später, wenn gewünscht:**

- „Haushalt“ als Bündel: alle Kategorien auf einmal teilen.
- Kosten aufteilen (50/50 oder nach Anteil) mit „wer schuldet wem“.

Backend ist fertig: `category_members`, `category_invites`, `create_category_invite`, `accept_category_invite`, RLS je Rolle, Smoke-Test.

## 8. Lokal oder Cloud (Abo)

Kostenkurve ist **kostenlos, solange die Daten auf dem Gerät bleiben**. Wer von mehreren Geräten zugreifen, gesichert sein oder teilen will, legt ein Konto an und bucht **Kostenkurve Cloud für 2 € im Monat**. Die Wahl steht beim ersten Start im Mittelpunkt und lässt sich jederzeit in den Einstellungen ändern.

| | Lokal – kostenlos, ohne Konto | Cloud – 2 € im Monat, mit Konto |
|---|---|---|
| Kategorien, Felder, Einträge, Formeln, Verlauf, Auswertung, Prognose, Erinnerungen, Export | ✓ | ✓ |
| Speicherort | nur dieses Gerät (`local_data.json` in der App-Sandbox) | Supabase in Frankfurt, Cache auf dem Gerät, offline erfassen |
| Auf allen Geräten, gesichert bei Verlust des Handys | – | ✓ |
| Kategorie mit dem Partner teilen | – | ✓ (das Abo des Eigentümers reicht für den Haushalt) |
| Belege (Fotos, PDFs, 5 GB) | – | ✓ |

### 8.1 Ablauf

1. **Start-Bildschirm** (erster Start oder nach dem Update, solange kein Speicherort gewählt ist): zwei Karten „Auf diesem Gerät – kostenlos, ohne Konto“ und „In der Cloud – auf allen Geräten, 2 € im Monat“, darunter „Ich habe schon ein Konto“.
2. **Lokal** → Onboarding (Vorlagen, Erinnerungen) → App.
3. **Cloud** → **Registrieren** (Mit Apple oder E-Mail + 6-stelliger Code, kein Passwort; Hinweis auf Nutzungsbedingungen und Datenschutz) → **Paywall**: „Lokal · kostenlos“ neben „Cloud · 2 €/Monat“ mit Store-Preis, „Cloud abonnieren“ oder „Kostenlos lokal nutzen“. Erst wenn der Server den Kauf bestätigt, wechselt die App in die Cloud und lädt vorhandene lokale Daten hoch.
4. **Anmelden** (Apple oder E-Mail-Code) → Abo aktiv: Cloud. Kein Abo: Paywall.
5. **Wechseln in den Einstellungen:** „Cloud aktivieren“ (Registrieren/Anmelden → Paywall → Hochladen) oder „Auf dieses Gerät holen“ (kopiert alles aus der Cloud aufs Gerät; Belege bleiben in der Cloud).
6. **Abo beendet:** Die Cloud-Daten bleiben lesbar (Export, Umzug aufs Gerät), ändern sperrt der Server. Die App zeigt „Cloud pausiert“: Abo erneuern, aufs Gerät holen oder abmelden. Ohne Netz sperrt die App nicht – nur eine Antwort des Servers zählt.
7. **Bestandskonten aus der Testphase** (anonym in der Cloud) sehen beim Update den Start-Bildschirm. „Lokal“ kopiert ihre Daten aufs Gerät und löscht das anonyme Konto; „Cloud“ verknüpft Apple bzw. E-Mail mit dem vorhandenen Konto, die Daten bleiben.

### 8.2 Technik

- **Speicherort:** `StorageMode` (`local`, `cloud`, nicht gewählt) in `storage_mode.json`, `StorageCubit` über dem `MaterialApp`, `StartGate` vor dem Onboarding (Start-Bildschirm, „Cloud pausiert“ oder App).
- **Daten:** `CategoriesRepository` ist ein `StorageCategoriesRepository`, das je nach Speicherort an `LocalCategoriesRepository` (Datei; dieselbe Logik wie der Mock über `MemoryCategoriesRepository`) oder an die Cloud-Kette (`OfflineCategoriesRepository` → `SupabaseCategoriesRepository`) weitergibt. Ein Wechsel meldet `changes`, alle Ansichten laden neu.
- **Umzug** (`StorageTransfer`): **hoch** legt jede Kategorie per `create_category` an, ordnet Tracker und Felder über ihre Reihenfolge zu, sendet Einträge mit ihren Geräte-Ids per `save_entry` und setzt danach „enthalten in“ und Archiv. Ein Journal merkt sich jede angelegte Kategorie – bricht der Umzug ab, macht der nächste Versuch dort weiter, ohne doppelt anzulegen. **Runter** kopiert alle sichtbaren Kategorien als eigene aufs Gerät.
- **Konto:** keine neuen anonymen Konten. Registrieren = `signInWithOtp(shouldCreateUser: true)` bzw. Apple (`signInWithIdToken`), Anmelden = `shouldCreateUser: false`. Ein noch angemeldetes anonymes Bestandskonto wird verknüpft (`linkIdentityWithIdToken`, `updateUser(email)`).
- **Abo:** Kostenkurve Cloud ist das bisherige Plus-Produkt `de.eloayoubi.kostenkurve.plus.monthly` (Ids bleiben, Prüfung über `verify-purchase` wie bisher). In App Store Connect: Anzeigename „Kostenkurve Cloud“, Preis 2 € im Monat; das Jahresabo bietet die App nicht mehr an.
- **Server** (`…_cloud_access.sql`): `has_cloud(category)` = Aufrufer oder Eigentümer der Kategorie hat ein laufendes Abo. `can_edit_category` verlangt das zusätzlich – damit gelten alle Schreib-Policies (Kategorien, Tracker, Felder, Einträge, Werte, Belege) und `save_entry`/`create_category` nur mit Cloud. Neue Kategorien und Einladungen brauchen das eigene Abo, Beitreten das des Eigentümers. Lesen, Löschen und Verlassen bleiben ohne Abo möglich (DSGVO Art. 17 und 20).
- **Kauf** wie bisher: `in_app_purchase` (StoreKit 2), `applicationUserName` = Nutzer-Id wird zum `appAccountToken`; `verify-purchase` prüft die signierte Transaktion gegen Apples Root-Zertifikat und schreibt `entitlements` über `apply_plus_transaction` (nur Service-Role); Verlängerung, Kündigung und Erstattung kommen über `app-store-notifications`.
- **Pflichtangaben** auf der Paywall: Preis und Laufzeit aus dem Store, automatische Verlängerung und Kündigung, Links zu Nutzungsbedingungen, Datenschutz und Apples EULA, „Käufe wiederherstellen“ (App-Store-Richtlinie 3.1.2). Konto löschen bleibt in der App (5.1.1(v)).

### 8.3 Sicherheit (OWASP Top 10, 2021)

| Risiko | Maßnahme |
|---|---|
| A01 Broken Access Control | Bezahlte Cloud wird **im Server** durchgesetzt (RLS über `can_edit_category`/`has_cloud`), nicht nur in der App; `entitlements` schreibt nur die Service-Role nach geprüftem Kauf; jede Tabelle mit RLS; der Speicherort auf dem Gerät öffnet keine Rechte. |
| A02 Cryptographic Failures | Nur HTTPS; Sitzung (Refresh-Token) im iOS-Schlüsselbund bzw. Android Keystore (`flutter_secure_storage`, nur dieses Gerät, nach dem ersten Entsperren) statt in NSUserDefaults; lokale Daten in der App-Sandbox mit iOS-Datenschutz; keine Schlüssel im Repo. |
| A03 Injection | Kein SQL aus der App: PostgREST und RPCs mit Parametern; Eingaben geprüft (E-Mail-Format und ≤ 254 Zeichen, Code genau 6 Ziffern). |
| A04 Insecure Design | Kauf erst nach Serverbestätigung wirksam; Abo-Ende sperrt nur Schreiben, Daten bleiben exportierbar; Umzug wiederholbar ohne Doppelungen; offline keine Aussperrung. |
| A05 Security Misconfiguration | Anonyme Anmeldung aus; Codes 10 Minuten gültig; Rate-Limits für Mails und Code-Prüfungen; `verify_jwt` an allen Funktionen außer `health` und den Apple-Benachrichtigungen (die prüfen Apples Signatur). |
| A06 Vulnerable Components | Versionen in `pubspec.lock`, `flutter pub outdated` vor jedem Release; nur verbreitete, gepflegte Pakete. |
| A07 Identification and Authentication Failures | Kein Passwort (kein Credential Stuffing, keine schwachen Passwörter): Apple mit Nonce oder Einmal-Code; Supabase begrenzt Code-Versuche; Anmelden verrät nicht, ob es eine E-Mail gibt (gleiche Antwort für bekannte und unbekannte Adressen); neuer Code erst nach 60 s; Refresh-Token-Rotation; Abmelden löscht Sitzung und Cache. |
| A08 Software and Data Integrity Failures | StoreKit-Transaktionen und App-Store-Benachrichtigungen werden gegen Apples Zertifikatskette geprüft; die App schreibt nie selbst ein Abo. |
| A09 Logging and Monitoring Failures | Keine Tokens, Codes oder E-Mail-Adressen in Logs; Edge Functions loggen nur Fehlercodes; Anmeldungen protokolliert Supabase Auth. |
| A10 Server-Side Request Forgery | Der Server ruft nur feste Apple-Adressen auf, keine URLs aus Eingaben. |

## 9. Geschäftsmodell später: passende Angebote

- **Auslöser:**
  - Der Arbeitspreis liegt über dem Durchschnitt.
  - Ein Vertrag endet in < 3 Monaten.
  - Die Preiserhöhung des Versorgers ist eingetragen.
  - Der Verbrauch stieg stark.
- **Angebot:** Vergleich über einen Partner (Affiliate über Vergleichsportale bzw. deren Partnerprogramme) mit vorausgefülltem Verbrauch und PLZ. Vergütet wird pro Wechsel.
- **Regeln:**
  - Angebote sind deutlich als Werbung gekennzeichnet (UWG).
  - Nur mit **eigener, freiwilliger Einwilligung** für personalisierte Angebote (DSGVO Art. 6 Abs. 1 a), jederzeit widerrufbar.
  - Ohne Einwilligung verlassen keine Daten das Konto.
  - Bei Versicherungen nur als Tippgeber, sonst ist eine Erlaubnis nach § 34d GewO nötig – vor dem Start rechtlich prüfen lassen.
- **Daten:**
  - Vergleichswerte entstehen nur aggregiert und anonym („Haushalte mit 2 Personen verbrauchen …“).
  - Alternativ dienen öffentliche Werte als Vergleich (Stromspiegel, BDEW-Durchschnittspreise).

## 10. Architektur, Betrieb, Datenschutz

- **App:** Flutter, Feature-Ordner mit Cubit/Data/View, Mock- und Supabase-Repositories (siehe README).
- **Offline-Erfassung (M2):**
  - Zähler hängen oft im Keller ohne Netz. Einträge gehen deshalb zuerst in eine lokale Warteschlange (SQLite über `drift` oder eine Datei) und werden synchronisiert, sobald Netz da ist.
  - Lesen kommt aus einem lokalen Cache. Die Kosten-Engine rechnet ohnehin auf dem Gerät.
- **Backend:** Supabase in der EU (Region Frankfurt), RLS auf jeder Tabelle, RPCs für Teilen, Edge Functions für Käufe und KI.
- **DSGVO:**
  - Datenschutzerklärung und Verzeichnis der Verarbeitung.
  - Datenexport (CSV/JSON, Art. 20) und Konto löschen in der App (Art. 17, App-Store-Pflicht 5.1.1(v)).
  - Keine Werbe-SDKs, Crash-Reporting nur ohne personenbezogene Daten.
- **Sicherheit:** Keine Schlüssel im Repo (`.env.local`, `ios/fastlane/.env`). Kaufprüfung nur serverseitig. Belege im privaten Bucket, Zugriff nur über signierte URLs.
- **Qualität:**
  - Jede Rechnung mit Unit-Tests.
  - Jede Seite im Smoke-Test in Hell und Dunkel.
  - Jede Tabelle mit einem SQL-Testfall in `supabase/tests/`.

## 11. Meilensteine

Jeder Meilenstein endet mit grünem `flutter analyze && flutter test` bzw. `test_local.sh`, Merge nach `main` und – auf Wunsch – einem TestFlight-Build.

| # | Inhalt | Fertig, wenn |
|---|---|---|
| **M0** ✅ | Grundgerüst: Flutter (iOS + Android), Stack, Theme hell/dunkel, Fonts, L10n DE/EN, DI, Basis-Widgets, Shell, Übersicht mit Prognose aus Mock-Daten, Kosten-Engine, Supabase-Schema (RLS, Teilen, Belege), Fastlane, Workflows, Doku | erledigt (dieser Stand) |
| **M1** ✅ | **Kategorien & Vorlagen:** Kategorien-Tab (Liste, anlegen, sortieren je Person, archivieren/wiederherstellen), 8 Vorlagen mit abwählbaren Feldern, Tracker anlegen/umbenennen/archivieren, **Feld-Editor** (Typ, Zeitverhalten, Einheit mit Vorschlägen, Umrechnung, Intervall, Auswahlwerte; Typwechsel nur passend zu gespeicherten Werten), Symbol- und Farbwahl; Supabase: `create_category` (alles in einer Transaktion), `reorder_categories`, Schutz-Trigger, SQL-Tests | erledigt. Offen für später: Felder umsortieren, archivierte Tracker wiederherstellen |
| **M2** ✅ | **Erfassen & Verlauf:** Eingabe-Formular aus den Feldern (Zahlentastatur mit Komma und Tausenderpunkt, iOS-Datumsrad, letzter Wert und Verbrauch seitdem als Hilfe, Hinweis auf Zählerwechsel), Schnellerfassung aus der Übersicht, Verlauf je Tracker (12 Monate Kosten oder Verbrauch mit Vorjahr, Jahresvergleich, Prognose, aktuelle Werte, Einträge), Bearbeiten/Löschen, Erinnerungen als lokale Benachrichtigung (Ablesen nach 30 Tagen, Stichtage 30/7/1 Tag vorher), **Offline**: Cache zum Lesen, Warteschlange mit Geräte-Ids und Upsert `save_entry` | erledigt. Nachgezogen in M4–M6: Abrechnungszeitraum im Formular, Cache und Warteschlange je Konto |
| **M3** ✅ | **Auswertung, Prognose & Formeln:**<br>• Auswertungs-Tab mit Jahr-Auswahl: Kosten je Monat gestapelt nach Kategorie (Hochrechnung blasser), Jahresvergleich, Verbrauch je Zähler.<br>• **Formel-Feld:** eigener Parser (`+ − × ÷ ^`, Vergleiche, `min`/`max`/`runden`/`wenn`/`abs`/`wurzel`, Dezimalkomma). Editor mit Fehlerstelle, Live-Vorschau mit dem letzten Eintrag und Namen zum Antippen. Formeln zählen nach ihrem Zeitverhalten in Kosten und Prognose.<br>• **Prognose** mit Trend der Zähler (±20/25 %) und Spanne: Zähler ±5–10 %, feste Beträge ±1 %, Einmaliges ±25 %. Die Aufteilung nach Herkunft wird erklärt.<br>• **Abschlags-Check:** neues Zeitverhalten „Abschlag“, ergibt Guthaben oder Nachzahlung und einen passenden Abschlag.<br>• **„Kosten enthalten in“** je Tracker. | erledigt. Nachgezogen: Formeln über Zeiträume (`summe(feld; tage)`, `schnitt(feld; tage)`), „Was wäre wenn“ in der Auswertung |
| **M4** ✅ | **Konto & Teilen:**<br>• Konto sichern mit Apple oder E-Mail-Code (6 Ziffern, ohne Passwort), mit bestehendem Konto anmelden, Name für geteilte Kategorien, abmelden.<br>• Kategorie teilen: Einladung mit Rolle (Bearbeiten / Nur ansehen) als Code, Link (`de.eloayoubi.kostenkurve://invite?code=…`) und QR, 7 Tage gültig, einmal einlösbar; Mitglieder verwalten, verlassen.<br>• Realtime: Änderungen des Partners erscheinen sofort (Supabase Realtime, 500 ms gebündelt), „von Anna“ am Eintrag.<br>• Cache und Warteschlange je Konto, Kontowechsel lädt alles neu. | erledigt. Bewusst weggelassen: Google-Anmeldung (braucht Google-Cloud-Projekt), Universal Links (brauchen eine Domain) – beides später möglich |
| **M5** ✅ | **Plus & Belege:**<br>• Abo-Seite (Monat/Jahr, Ersparnis, Wiederherstellen, Pflicht-Links), StoreKit 2 über `in_app_purchase`, Prüfung der signierten Transaktion in `verify-purchase` gegen Apples Root-Zertifikat, Verlängerung/Kündigung über `app-store-notifications`.<br>• Belege: Kamera, Fotos (auf 2048 px / JPEG 80 % verkleinert), PDF; Vorschau, Ansicht mit Zoom, Teilen/Sichern, Löschen; Speicheranzeige (5 GB) in den Einstellungen. | erledigt. Android-Kauf folgt (Google Play Billing); ein im App Store gekauftes Plus gilt auch auf Android |
| **M6** ✅ | **Launch:**<br>• App-Icon, Splash (hell/dunkel), Onboarding (Willkommen → Vorlagen → Erinnerungen).<br>• Datenexport (CSV + JSON), Konto löschen (inkl. Belege und Widerruf des Apple-Tokens), Datenschutz, Nutzungsbedingungen, Impressum in der App.<br>• Store-Texte DE/EN, Screenshots (6,9″), Fastlane-Lane `metadata`, Bewertungsbitte nach dem 3. Eintrag, Android-Release-Signatur über `key.properties`.<br>• Nur iPhone (läuft auf dem iPad im Kompatibilitätsmodus), nur Hochformat. | Code fertig. Offen: Supabase-Projekt verbinden und TestFlight (siehe [SETUP.md](SETUP.md)), Platzhalter in Rechtstexten und Store-URLs, Play Console |
| **M7** | **Lokal oder Cloud:** Start-Bildschirm mit der Wahl, Registrieren und Anmelden (Apple, E-Mail-Code), Paywall „lokal kostenlos – Cloud 2 €/Monat“, lokaler Speicher, Umzug hoch und runter, „Cloud pausiert“, Speicherort in den Einstellungen; Server-Durchsetzung über RLS, Sitzung im Schlüsselbund (Abschnitt 8) | Code fertig. Offen: Migration einspielen, `config push` (anonyme Anmeldung aus, Code-Gültigkeit), Abo in App Store Connect auf 2 € und „Kostenkurve Cloud“ |
| Danach | KI-Import von Abrechnungen (Edge Function + Claude, nur mit Einwilligung), Zählerstand per Foto (OCR auf dem Gerät), Home-Screen-Widgets, Vergleichswerte, Angebote (Abschnitt 9), Kosten aufteilen | – |

## 12. Offene Entscheidungen

1. ~~**Kauf-Technik**~~ entschieden: `in_app_purchase` + eigene Prüfung wie MyBoo (keine Gebühr, kein Drittanbieter). Android-Kauf später über Google Play Billing.
2. ~~**Abo-Preis**~~ entschieden: Kostenkurve Cloud 2 € im Monat, lokal kostenlos (Abschnitt 8) – Preis in App Store Connect setzen.
3. **Name final** nach Markenrecherche.
4. **Supabase-Projekt** anlegen (Region Frankfurt) – danach Projekt-Ref in `.env.local` und als GitHub-Secrets.
5. ~~**Offline-Speicher**~~ entschieden: Datei-Cache und -Warteschlange je Konto (`FileJsonStore`); `drift` erst, wenn Auswertungen lokal Abfragen brauchen.

## Quellen

- [Destatis – Konsumausgaben privater Haushalte (Laufende Wirtschaftsrechnungen 2024)](https://www.destatis.de/DE/Themen/Gesellschaft-Umwelt/Einkommen-Konsum-Lebensbedingungen/Konsumausgaben-Lebenshaltungskosten/Tabellen/privater-konsum-d-lwr.html)
- [Lebensmittel Praxis – Konsumausgaben 2024](https://lebensmittelpraxis.de/handel-aktuell/49585-konsumausgaben-2024-deutsche-haushalte-geben-mehr-geld-fuer-freizeit-aus.html)
