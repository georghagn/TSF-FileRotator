
Hier ist die komplette Projekt-Zusammenfassung ("Project Snapshot") für den **TSF-FileRotator**.

# Project Snapshot: TSF-FileRotator

**Datum:** 26. November 2025
**Status:** Design & Core-Implementierung abgeschlossen
**Kontext:** Plugin für die TSF-Suite (Smalltalk)
**Ziel:** Robuste Rotation und Archivierung von Dateien in heterogenen Umgebungen (Pharo/Go).

-----

## 1. Das Kernkonzept

Der **TSF-FileRotator** ist ein spezialisierter `TsfTask` (aus `TSF-Scheduler`), der Dateigrößen oder -alter überwacht und bei Bedarf rotiert.
Er ist **inhaltlich agnostisch** (nicht nur für Logs) und **prozess-neutral** (funktioniert auch, wenn ein externer Go-Service die Datei schreibt).

### Die "Big Four" Design-Entscheidungen

1.  **Generic Naming:** Umbenennung von `LogRotator` zu `FileRotator` für universelle Einsatzzwecke (CSV-Exporte, Dumps, Logs).
2.  **Hybrid Locking:** Nutzung von `.LOCK`-Dateien auf dem Filesystem statt In-Memory Mutexes, um Synchronisation zwischen Pharo und externen Prozessen (Go) zu gewährleisten.
3.  **Pfad-Stabilität:** Der Task speichert intern `Paths` statt `FileReferences`, da die `renameTo:`-Operation in Pharo die Referenz mutiert (d.h. sie zeigt danach auf das Backup).
4.  **Strategy Pattern:** Extreme Modularisierung der Logik (Wann? Wie speichern? Was behalten?).

-----

## 2. Architektur & Klassenstruktur

### Der Worker

  * **`TsfFileRotationTask`**: Der eigentliche Task.
      * Hält eine Liste von `monitoredPaths`.
      * Orchestriert den Ablauf: Check -\> Lock -\> Rotate -\> Archive -\> Retention.
      * Implementiert die **Locking-Logik** (Retry & Self-Healing).

### Die Strategien (Pluggable Logic)

1.  **Rotation Policy** (Wann wird agiert?)
      * `TsfFileSizeLimitPolicy` (z.B. \> 10 MB)
      * *(Geplant: `TsfTimeRotationPolicy`)*
2.  **Archive Strategy** (Was passiert nach dem Rename?)
      * `TsfZipArchiveStrategy` (Erzeugt `.zip`, löscht `.bak`)
      * `TsfNoCompressionStrategy` (Behält `.bak`)
3.  **Retention Policy** (Aufräumen)
      * `TsfCountRetentionPolicy` (Behält die N neuesten Backups, löscht den Rest)

-----

## 3. Der Workflow (Der "Happy Path")

Ein Durchlauf (`schedule` per TsfScheduler oder `executeAction` Standalone) für eine Datei `app.log`:

1.  **Policy Check:** Ist `app.log` \> Limit? -\> Falls JA:
2.  **Acquire Lock:**
      * Versuche `app.log.LOCK` zu erstellen.
      * **Retry-Logik:** 3 Versuche à 10ms Abstand (fängt kurze Writes von Go ab).
      * **Self-Healing:** Ist der existierende Lock älter als 60s? -\> Löschen & Übernehmen.
3.  **Rename:**
      * `app.log` -\> `app.log.2025-11-26_10-00.bak`.
      * Der externe Logger (Go) muss robust sein (Re-Open oder einfaches Weiter-Schreiben auf Inode).
4.  **Archive:**
      * Packe `.bak` in `.zip`.
      * Lösche `.bak`.
5.  **Retention:**
      * Suche alle Dateien, die auf `app.log.*` matchen.
      * Sortiere nach Zeit, lösche alles über `keepCount`.
6.  **Release Lock:** Lösche `app.log.LOCK`.

-----

## 4. Wichtige Implementierungs-Details

### Locking (Code-Ausschnitt Logik)

```smalltalk
TsfFileRotationTask >> acquireLock: aLockFile retries: anInteger
    anInteger timesRepeat: [ 
        (self acquireLock: aLockFile) ifTrue: [ ^ true ].
        (Delay forMilliseconds: 10) wait.
    ].
    ^ false
```

### Zeit-Abstraktion (Testbarkeit)

Um "Stale Locks" zu testen, nutzen wir keine `Delay wait`, sondern "Time Travel".

  * Methode: `currentSystemTime` (Default: `DateAndTime now`).
  * Im Test: Überschreiben der Methode via `newAnonymousSubclass`, um Zeitversatz zu simulieren.

### Pharo-Specifcs

  * **Timestamp:** Helper `asFileNameString:` nutzt `DateAndTime printYMDOn:` und `printHMSWithDashesOn:` für sicheres "YYYY-MM-DD\_HH-MM-SS" Format.
  * **Baselines:** Abhängigkeiten sauber definiert (`TSF-Scheduler`, `TSF-FileRotator-Core`, etc.).

-----

## 5. Konfiguration (Snippet)

```smalltalk
TsfFileRotationTask new 
    initializeWithFiles: { FileSystem workingDirectory / 'server.log' }
    rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10 * 1024 * 1024)
    archiveStrategy: (TsfZipArchiveStrategy new)
    retentionPolicy: (TsfCountRetentionPolicy new maxCount: 5).
```

-----

## 6. Offene Punkte / Next Steps

  * [ ] Integration in das laufende `TSF-Scheduler` Image.
  * [ ] Performance-Test unter Last (Go schreibt, Pharo rotiert).
  * [ ] Evtl. Erweiterung um `TsfTimeRotationPolicy` (z.B. "Täglich um Mitternacht").

-----

**Ende des Snapshots.** Damit hast du eine solide Basis, um das Projekt später wieder aufzugreifen oder zu erweitern. Es war mir eine Freude, das mit dir zu entwerfen\!
