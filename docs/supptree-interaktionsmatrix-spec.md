# SuppTree - Interaktionsmatrix & Ampelsystem
## Technische Spezifikation fuer den Schichtkalender

---

## 1. Ueberblick

SuppTree ist ein B2B/B2C-Supplement-Marktplatz fuer den DACH-Raum. Der Schichtkalender ist ein Kern-Feature: Nutzer geben Schichtrhythmus und Supplements ein, das System berechnet optimale Einnahmezeiten.

Zwei Bereiche:

1. Supplement-Supplement Interaktionen = Automatische Einplanung im Kalender
2. Medikament-Supplement Warnungen = Informationssystem mit Nutzer-Entscheidung

### Rechtlicher Kontext (KRITISCH)

SuppTree ist KEIN Medizinprodukt und keine DiGA.

ERLAUBT:
- Supplements untereinander zeitlich optimieren und automatisch einplanen (Supplements = Lebensmittel)
- Bei Medikament-Supplement-Konflikten allgemeine Sicherheitsinfos anzeigen (wie Beipackzettel)
- Nutzer SELBST entscheiden lassen ob/wann er Supplement trotzdem einnimmt

VERBOTEN:
- Automatisch Supplements um Medikamenteneinnahmen herum planen
- Personalisierte medizinische Empfehlungen geben
- Begriffe "Diagnose", "Therapie", "Behandlung" verwenden

---

## 2. Datenstruktur

### 2.1 supplements.json

```json
{
  "id": "supp_001",
  "name": "Magnesium (Bisglycinat)",
  "wirkstoff_id": "wirkstoff_magnesium",
  "kategorie": "Mineral",
  "optimale_tageszeit": "abends",
  "tageszeit_grund": "Unterstuetzt Entspannung und Schlafqualitaet",
  "einnahme_hinweis": "Am besten zu einer Mahlzeit einnehmen",
  "fettloeslich": false
}
```

### 2.2 wirkstoffe.json

```json
{
  "id": "wirkstoff_magnesium",
  "name": "Magnesium",
  "kategorie": "Mineral",
  "beschreibung": "Essentielles Mineral fuer Muskelfunktion und Nervensystem"
}
```

### 2.3 supplement_interactions.json

Steuert automatische Zeitplanung im Kalender.

Felder: interaktions_typ (hemmend/foerdernd/neutral), empfohlener_abstand_minuten (0-480), richtung (bidirektional/a_hemmt_b/b_hemmt_a/a_foerdert_b), schweregrad (niedrig/mittel/hoch)

```json
[
  { "wirkstoff_a": "Eisen", "wirkstoff_b": "Calcium", "interaktions_typ": "hemmend", "empfohlener_abstand_minuten": 120, "richtung": "bidirektional", "schweregrad": "hoch", "beschreibung": "Calcium kann die Eisenaufnahme um bis zu 50% reduzieren." },
  { "wirkstoff_a": "Eisen", "wirkstoff_b": "Vitamin C", "interaktions_typ": "foerdernd", "empfohlener_abstand_minuten": 0, "richtung": "b_foerdert_a", "schweregrad": "niedrig", "beschreibung": "Vitamin C verbessert die Aufnahme von Eisen. Zusammen einnehmen." },
  { "wirkstoff_a": "Zink", "wirkstoff_b": "Kupfer", "interaktions_typ": "hemmend", "empfohlener_abstand_minuten": 120, "richtung": "bidirektional", "schweregrad": "mittel", "beschreibung": "Konkurrieren um gleiche Aufnahmewege." },
  { "wirkstoff_a": "Magnesium", "wirkstoff_b": "Calcium", "interaktions_typ": "hemmend", "empfohlener_abstand_minuten": 120, "richtung": "bidirektional", "schweregrad": "mittel", "beschreibung": "Hohe Calciummengen koennen Magnesiumaufnahme verringern." },
  { "wirkstoff_a": "Vitamin D", "wirkstoff_b": "Vitamin K2", "interaktions_typ": "foerdernd", "empfohlener_abstand_minuten": 0, "richtung": "bidirektional", "schweregrad": "niedrig", "beschreibung": "K2 unterstuetzt korrekte Calciumverwertung durch Vitamin D." },
  { "wirkstoff_a": "Eisen", "wirkstoff_b": "Zink", "interaktions_typ": "hemmend", "empfohlener_abstand_minuten": 120, "richtung": "bidirektional", "schweregrad": "mittel", "beschreibung": "Konkurrieren um gleiche Transportmechanismen." },
  { "wirkstoff_a": "Eisen", "wirkstoff_b": "Magnesium", "interaktions_typ": "hemmend", "empfohlener_abstand_minuten": 120, "richtung": "bidirektional", "schweregrad": "mittel", "beschreibung": "Koennen sich gegenseitig in der Aufnahme behindern." }
]
```

### 2.4 medikament_gruppen.json

Medikamente als Gruppen (NICHT einzeln) = bleibt allgemeine Information.

```json
[
  { "id": "medgrp_001", "name": "Schilddruesenmedikamente (z.B. L-Thyroxin)", "suchbegriffe": ["L-Thyroxin", "Levothyroxin", "Euthyrox", "Thyronajod", "Schilddruese"] },
  { "id": "medgrp_002", "name": "Blutverduenner (z.B. Marcumar, Warfarin)", "suchbegriffe": ["Marcumar", "Warfarin", "Phenprocoumon", "Blutverduenner", "Falithrom"] },
  { "id": "medgrp_003", "name": "Blutdrucksenker / ACE-Hemmer", "suchbegriffe": ["Ramipril", "Enalapril", "Lisinopril", "ACE-Hemmer", "Blutdrucksenker"] },
  { "id": "medgrp_004", "name": "Statine / Cholesterinsenker", "suchbegriffe": ["Simvastatin", "Atorvastatin", "Statin", "Cholesterinsenker"] },
  { "id": "medgrp_005", "name": "Antidepressiva / SSRI", "suchbegriffe": ["Sertralin", "Citalopram", "Fluoxetin", "SSRI", "Antidepressiva"] },
  { "id": "medgrp_006", "name": "Diabetes-Medikamente (z.B. Metformin)", "suchbegriffe": ["Metformin", "Glucophage", "Diabetes", "Blutzucker"] },
  { "id": "medgrp_007", "name": "Antibabypille / Hormonelle Verhuetung", "suchbegriffe": ["Pille", "Verhuetung", "Kontrazeptiva"] },
  { "id": "medgrp_008", "name": "Protonenpumpenhemmer (z.B. Omeprazol)", "suchbegriffe": ["Omeprazol", "Pantoprazol", "PPI", "Magensaeureblocker"] },
  { "id": "medgrp_009", "name": "Antibiotika", "suchbegriffe": ["Antibiotika", "Amoxicillin", "Doxycyclin", "Ciprofloxacin"] },
  { "id": "medgrp_010", "name": "Schmerzmittel / NSAIDs", "suchbegriffe": ["Ibuprofen", "Diclofenac", "Naproxen", "NSAID", "Schmerzmittel"] }
]
```

### 2.5 med_supp_interactions.json (Ampelsystem)

Ampel-Stufen:
- gruen = Kein Konflikt. Supplement normal eingeplant.
- gelb = Abstand empfohlen. Supplement PAUSIERT + Info-Panel. Nutzer plant selbst.
- rot = Kritisch. Supplement GESPERRT. Nur nach Disclaimer-Checkbox einplanbar.

```json
[
  { "medikament_gruppe": "Schilddruesenmedikamente", "wirkstoff": "Calcium", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Calcium kann die Aufnahme von Schilddruesenmedikamenten verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Schilddruesenmedikamente", "wirkstoff": "Eisen", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Eisen kann die Aufnahme von Schilddruesenmedikamenten verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Schilddruesenmedikamente", "wirkstoff": "Magnesium", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Magnesium kann die Aufnahme von Schilddruesenmedikamenten verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Blutverduenner", "wirkstoff": "Vitamin K", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "Vitamin K kann die Wirkung von Blutverduennern abschwaechern. Dies kann medizinisch bedeutsam sein.", "allgemeiner_abstand_info": "Ein zeitlicher Abstand loest diesen Konflikt nicht. Die gleichzeitige Einnahme sollte nur in Absprache mit einem Arzt erfolgen." },
  { "medikament_gruppe": "Blutverduenner", "wirkstoff": "Omega-3", "ampel": "gelb", "abstand_minuten_info": null, "wirkung_beschreibung": "Hohe Dosen Omega-3 koennen die Blutgerinnung zusaetzlich beeinflussen.", "allgemeiner_abstand_info": "Bitte sprich mit deinem Arzt ueber die Dosierung." },
  { "medikament_gruppe": "Blutverduenner", "wirkstoff": "Johanniskraut", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "Johanniskraut kann die Wirkung von Blutverduennern abschwaechern.", "allgemeiner_abstand_info": "Gleichzeitige Einnahme nur in Absprache mit einem Arzt." },
  { "medikament_gruppe": "Antibabypille", "wirkstoff": "Johanniskraut", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "Johanniskraut kann die Wirksamkeit hormoneller Verhuetungsmittel herabsetzen.", "allgemeiner_abstand_info": "Gleichzeitige Einnahme nur in Absprache mit einem Arzt." },
  { "medikament_gruppe": "Statine", "wirkstoff": "Grapefruit-Extrakt", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "Grapefruit kann den Abbau von Statinen hemmen und Nebenwirkungen verstaerken.", "allgemeiner_abstand_info": "Gleichzeitige Einnahme nur in Absprache mit einem Arzt." },
  { "medikament_gruppe": "Diabetes-Medikamente", "wirkstoff": "Vitamin B12", "ampel": "gelb", "abstand_minuten_info": 0, "wirkung_beschreibung": "Metformin kann langfristig die Aufnahme von Vitamin B12 verringern.", "allgemeiner_abstand_info": "Kein zeitlicher Abstand noetig, aber Ruecksprache mit Arzt zur Dosierung empfohlen." },
  { "medikament_gruppe": "Protonenpumpenhemmer", "wirkstoff": "Magnesium", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Langfristige PPI-Einnahme kann den Magnesiumspiegel senken.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Protonenpumpenhemmer", "wirkstoff": "Eisen", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Magensaeureblocker koennen die Eisenaufnahme verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Antibiotika", "wirkstoff": "Calcium", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Calcium kann die Aufnahme bestimmter Antibiotika verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Antibiotika", "wirkstoff": "Magnesium", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Magnesium kann die Aufnahme bestimmter Antibiotika verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Antibiotika", "wirkstoff": "Eisen", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Eisen kann die Aufnahme bestimmter Antibiotika verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Antibiotika", "wirkstoff": "Zink", "ampel": "gelb", "abstand_minuten_info": 120, "wirkung_beschreibung": "Zink kann die Aufnahme bestimmter Antibiotika verringern.", "allgemeiner_abstand_info": "Allgemein wird ein Abstand von mindestens 2 Stunden empfohlen." },
  { "medikament_gruppe": "Antidepressiva / SSRI", "wirkstoff": "Johanniskraut", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "Johanniskraut kann mit SSRI zu einem gefaehrlichen Serotonin-Syndrom fuehren.", "allgemeiner_abstand_info": "Gleichzeitige Einnahme nur in Absprache mit einem Arzt." },
  { "medikament_gruppe": "Antidepressiva / SSRI", "wirkstoff": "5-HTP", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "5-HTP kann mit SSRI zu einem gefaehrlichen Serotonin-Syndrom fuehren.", "allgemeiner_abstand_info": "Gleichzeitige Einnahme nur in Absprache mit einem Arzt." },
  { "medikament_gruppe": "Blutdrucksenker / ACE-Hemmer", "wirkstoff": "Kalium", "ampel": "rot", "abstand_minuten_info": null, "wirkung_beschreibung": "ACE-Hemmer erhoehen den Kaliumspiegel. Zusaetzliches Kalium kann gefaehrlich werden.", "allgemeiner_abstand_info": "Gleichzeitige Einnahme nur in Absprache mit einem Arzt." }
]
```

---

## 3. Nutzer-Datenmodell

### user_profile

```json
{
  "user_id": "user_123",
  "schicht_details": {
    "fruehschicht": { "start": "06:00", "ende": "14:00" },
    "spaetschicht": { "start": "14:00", "ende": "22:00" },
    "nachtschicht": { "start": "22:00", "ende": "06:00" }
  },
  "aktuelle_schicht_woche": "fruehschicht"
}
```

### user_supplements

```json
{
  "supplements": [
    { "supplement_id": "supp_001", "wirkstoff_id": "wirkstoff_magnesium", "dosierung": "400mg", "aktiv": true },
    { "supplement_id": "supp_002", "wirkstoff_id": "wirkstoff_eisen", "dosierung": "14mg", "aktiv": true }
  ]
}
```

### user_medikamente

```json
{
  "medikamente": [
    { "medikament_gruppe_id": "medgrp_001", "freitext_name": "L-Thyroxin", "hinzugefuegt_am": "2025-03-01" }
  ]
}
```

WICHTIG: App fragt NICHT wann Nutzer Medikament nimmt. Nur DASS er es nimmt.

---

## 4. Kalender-Algorithmus

### 4.1 Supplement-Einplanung (automatisch)

```
1. Sortiere Supplements nach optimaler Tageszeit
2. Mappe auf Schichtrhythmus:
   "morgens" = 1h nach Aufstehen
   "zu Mahlzeit" = Fruehstueck/Mittag/Abendessen
   "abends" = 1h vor Schlafengehen
   "nuechtern" = direkt nach Aufstehen
3. Pruefe Supplement-Supplement-Interaktionen:
   hemmend = Mindestabstand einhalten
   foerdernd = zusammen einplanen
4. Optimiere Zeitfenster fuer alle Abstaende
5. Gruppiere foerdernde Kombinationen visuell
```

### 4.2 Medikament-Check (NUR Information)

Bei Medikament-Hinzufuegung: Suche Konflikte in med_supp_interactions. KEINE Zeitanpassung! Nur Ampel-Hinweise.

### 4.3 Ampel-Verhalten

GRUEN: Normal eingeplant. Keine Anzeige.

GELB:
1. Supplement wird PAUSIERT (nicht automatisch eingeplant)
2. Info-Panel wird angezeigt:

```
+------------------------------------------------------+
| HINWEIS: Wechselwirkung erkannt                       |
|                                                       |
| [Supplement-Name] & [Medikamentengruppe]              |
| [wirkung_beschreibung]                                |
| Info: [allgemeiner_abstand_info]                      |
|                                                       |
| Bitte sprich mit deinem Arzt oder Apotheker.          |
|                                                       |
| [Supplement trotzdem einplanen]   [Mehr erfahren]     |
+------------------------------------------------------+
```

3. Bei "trotzdem einplanen":
   - Zeige verfuegbare Zeitslots
   - Zeige Erinnerung mit allgemeiner Abstandsinfo
   - Nutzer waehlt SELBST Zeitslot
   - Gelbe Markierung + Warn-Icon bleibt sichtbar

ROT:
1. Supplement wird GESPERRT
2. Warnung wird angezeigt:

```
+------------------------------------------------------+
| WARNUNG: Kritische Wechselwirkung                     |
|                                                       |
| [Supplement-Name] & [Medikamentengruppe]              |
| [wirkung_beschreibung]                                |
| [allgemeiner_abstand_info]                            |
|                                                       |
| Diese Information dient nur der allgemeinen            |
| Aufklaerung. Bitte nimm dieses Supplement nur          |
| nach Ruecksprache mit deinem Arzt oder Apotheker.     |
|                                                       |
| [Verstanden - trotzdem einplanen]  [Nicht einplanen]  |
+------------------------------------------------------+
```

3. Bei "trotzdem einplanen":
   - Disclaimer-Checkbox MUSS bestaetigt werden:
     "Ich habe die Information zur Kenntnis genommen und werde
      Ruecksprache mit meinem Arzt oder Apotheker halten."
   - Erst nach Bestaetigung: Zeitslot-Auswahl
   - Nutzer waehlt SELBST Zeitslot
   - Rote Markierung + Warn-Icon bleibt sichtbar
   - Disclaimer-Bestaetigung wird mit Timestamp gespeichert

---

## 5. UI-Komponenten

### Medikamenten-Eingabe
- Suchfeld mit Autosuggest aus medikament_gruppen.suchbegriffe
- Liste mit Loeschen-Buttons
- Disclaimer am unteren Rand

### Interaktions-Uebersicht
- Gruppiert nach Ampel (Rot zuerst)
- Status: Gesperrt/Pausiert/Eingeplant
- Details und Einplan-Option

### Kalender-Tagesansicht
- Zeitslots mit Supplement-Zuordnungen
- Foerdernde Kombis gruppiert
- Gelbe/Rote Inline-Hinweise
- Gesperrte Supplements separat am Ende

---

## 6. Disclaimers

### Global (Ersteinrichtung + Einstellungen)
"SuppTree gibt allgemeine Informationen zu Nahrungsergaenzungsmitteln. Diese ersetzen nicht die Beratung durch Arzt, Apotheker oder medizinische Fachpersonen. Hinweise basieren auf allgemein zugaenglichen Informationen ohne Anspruch auf Vollstaendigkeit. SuppTree ist kein Medizinprodukt."

### Medikamenten-Eingabe
"Medikamentenangaben werden nur fuer allgemeine Wechselwirkungsinfos verwendet. Keine Empfehlungen zu Einnahme oder Dosierung von Medikamenten."

### Rot-Disclaimer (Checkbox)
"Ich habe die Information zur Kenntnis genommen, dass eine bekannte Wechselwirkung zwischen [Supplement] und [Medikamentengruppe] besteht. Ich werde Ruecksprache mit meinem Arzt oder Apotheker halten."

---

## 7. Implementierung

### Tech-Stack
Frontend: Capacitor (HTML/CSS/JS) Mobile-First, Backend: Node.js, Daten: JSON-Dateien

### Dateistruktur

```
/src/data/
  supplements.json, wirkstoffe.json, supplement_interactions.json,
  medikament_gruppen.json, med_supp_interactions.json, disclaimers.json
/src/services/
  interaktions-checker.js, medikament-checker.js, kalender-planer.js, schicht-mapper.js
/src/components/
  kalender-tagesansicht.js, ampel-panel.js, medikament-eingabe.js, interaktions-uebersicht.js
/src/models/
  user-profile.js, user-supplements.js, user-medikamente.js
```

### Kalender-Planer

```javascript
// WICHTIG: Plant NUR Supplements. Medikamente = nur Hinweise, KEINE Zeitanpassung!
function erstelleTagesplan(nutzerSupplements, schichtDaten, heutigeSchicht) {
  const zeitfenster = mappeZeitfenster(schichtDaten, heutigeSchicht);
  let zuordnung = nutzerSupplements.map(s => ({
    supplement: s, bevorzugteZeit: zeitfenster[s.optimale_tageszeit], zeitslot: null
  }));
  const konflikte = pruefeSupplementInteraktionen(nutzerSupplements);
  const gruppen = gruppiereKombinationen(zuordnung, konflikte.foerdernde);
  zuordnung = loeseKonflikte(zuordnung, konflikte.hemmende);
  const tagesplan = weiseZeitslotsZu(zuordnung, gruppen);
  tagesplan.hinweise = pruefeMedikamentKonflikte(nutzerSupplements, nutzerMedikamente);
  return tagesplan;
}
```

### Medikament-Checker

```javascript
// Gibt NUR Informationen zurueck - KEINE Zeitanpassungen
function pruefeMedikamentKonflikte(nutzerSupplements, nutzerMedikamente) {
  const ergebnis = [];
  for (const med of nutzerMedikamente) {
    const interaktionen = ladeMedSuppInteraktionen(med.medikament_gruppe_id);
    for (const ia of interaktionen) {
      const betroffen = nutzerSupplements.find(s => s.wirkstoff_id === ia.wirkstoff_id);
      if (betroffen) ergebnis.push({
        supplement: betroffen, medikament_gruppe: med,
        ampel: ia.ampel, wirkung: ia.wirkung_beschreibung,
        abstand_info: ia.allgemeiner_abstand_info, abstand_minuten: ia.abstand_minuten_info
      });
    }
  }
  return ergebnis;
}

function bestimmeKalenderStatus(supplement, medKonflikte) {
  const k = medKonflikte.filter(x => x.supplement.id === supplement.id);
  if (!k.length) return { status: "eingeplant", ampel: "gruen" };
  if (k.some(x => x.ampel === "rot")) return {
    status: "gesperrt", ampel: "rot",
    konflikte: k.filter(x => x.ampel === "rot"), erfordert_disclaimer: true
  };
  if (k.some(x => x.ampel === "gelb")) return {
    status: "pausiert", ampel: "gelb",
    konflikte: k.filter(x => x.ampel === "gelb"), erfordert_disclaimer: false
  };
  return { status: "eingeplant", ampel: "gruen" };
}
```

---

## 8. MUSS-Regeln (rechtlich kritisch!)

1. KEIN automatisches Umplanen basierend auf Medikamenten
2. KEINE Medikamenten-Einnahmezeiten abfragen
3. IMMER allgemeine Formulierungen: "Allgemein wird empfohlen..." NICHT "Du solltest..."
4. IMMER Arzt/Apotheker-Verweis bei jedem Medikament-Hinweis
5. NIEMALS: "Diagnose", "Therapie", "Behandlung", "medizinische Empfehlung"
6. IMMER Disclaimer bei: Ersteinrichtung, Medikamenten-Eingabe, Rot-Freischaltung
7. Rot-Disclaimer: Checkbox + Timestamp speichern

---

## 9. Abgrenzungstabelle

| Aktion | Supplement-Supplement | Medikament-Supplement |
|--------|----------------------|----------------------|
| Automatisch einplanen | JA | NEIN |
| Zeitlich optimieren | JA | NEIN |
| Foerdernde Kombis gruppieren | JA | NEIN |
| Warnhinweis anzeigen | JA (bei Abstand) | JA (Ampelsystem) |
| Supplement sperren | NEIN | JA (bei Rot) |
| Supplement pausieren | NEIN | JA (bei Gelb) |
| Nutzer entscheidet selbst | Bei Zeitslot-Wahl | IMMER |
| Arzt-Verweis | Nicht noetig | IMMER |
| Disclaimer erforderlich | NEIN | JA (bei Rot) |
