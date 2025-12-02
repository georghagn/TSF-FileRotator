
|<sub>🇬🇧 [English translation →](README.en.md)</sub>|
|----:|
|    |

|[![Pharo Version](https://img.shields.io/badge/Pharo-12.0%2B-blue.svg)](https://pharo.org)|[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE) [![Dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen.svg)](#)|
|----|----|
|![TSF-FileRotator Logo](logo-rotator.png)| ***TSF-FileRotator***<br>Ein robuster, prozessunabhängiger Datei-Rotator für Pharo Smalltalk. Teil der **TSF (Tiny Smalltalk Framework)**-Suite|

<sup>***TSF*** steht für ***Tiny Smalltalk Framework*** — eine Sammlung von minimalistischen Tools für robuste Anwendungen.</sup>


## Überblick

Der **TSF-FileRotator** ist ein Plugin für die TSF-Suite. Er überwacht Dateien (z.B. Logs), rotiert sie basierend auf konfigurierbaren Policies (Größe, Alter) und archiviert sie.
Er wurde speziell für heterogene Umgebungen entwickelt (z.B. **Go-Logger & Pharo-Rotator**) und nutzt dateibasierte Locks, um Konflikte sicher zu vermeiden.

## Features

  * **Prozess-Agnostisch:** Rotiert Dateien, die von anderen Prozessen (Go, Python, OS) geschrieben werden.
  * **Robustes Locking:**
      * Nutzt `.LOCK` Dateien zur Synchronisation.
      * *Stale-Lock-Protection:* Bereinigt verwaiste Locks nach Crashes automatisch.
      * *Retry-Logik:* Wartet bei kurzen Schreibzugriffen (Spin-Lock mit Backoff).
  * **Modulare Architektur:**
      * **RotationPolicy:** Wann wird rotiert? (z.B. `TsfFileSizeLimitPolicy`).
      * **ArchiveStrategy:** Wie wird gespeichert? (z.B. `TsfZipArchiveStrategy` oder `TsfNoCompressionStrategy`).
      * **RetentionPolicy:** Wie viele Backups werden behalten? (z.B. `TsfCountRetentionPolicy`).
  * **Design:**
      * Implementiert als **POJO** (Plain Object), das von `Object` erbt.
      * Keine direkte Abhängigkeit zum Scheduler in der Kernlogik.
  * **Dual Use:** \* **Standalone:** Manuelles Triggern via `TsfFileRotator >> execute`.
      * **Scheduled:** Periodische Ausführung via TSF-Scheduler (Generic Task Adapter).

## Installation

```smalltalk
Metacello new
    baseline: 'TsfFileRotator';
    repository: 'github://georghagn/TSF-FileRotator:main';
    load.
```

## Verwendung

Der Rotator ist ein eigenständiges Objekt, das über den generischen `TsfTask` im Scheduler registriert wird.

Beispiel: Log-Rotation mit Zip-Komprimierung und Aufräum-Logik (Retention).

```smalltalk
| logFile rotator task |

"1. Die zu überwachende Datei"
logFile := FileSystem workingDirectory / 'server.log'.

"2. Den Rotator (Worker) konfigurieren"
rotator := TsfFileRotator new.
rotator configureWithFiles: { logFile }
    rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10 * 1024 * 1024) "10 MB"
    archiveStrategy: (TsfZipArchiveStrategy new)      "Als .zip speichern"
    retentionPolicy: (TsfCountRetentionPolicy new maxCount: 5). "Max 5 Backups"

"3. Als Task verpacken und dem Scheduler übergeben"
task := TsfTask 
    named: 'ServerLogRotation' 
    receiver: rotator 
    selector: #execute 
    frequency: 5 minutes.

"4. Einplanen"
TsfCron current addPeriodicTask: task.
```

## Funktionsweise

  * **Check:** Der Rotator prüft (via `execute`), ob `server.log` das Limit (z.B. 10MB) überschreitet.
  * **Lock:** Er versucht, `server.log.LOCK` zu erstellen.
    Falls vorhanden: Er wartet kurz (Retries). Wenn immer noch gelockt, bricht er für diesen Zyklus ab.
    Falls Lock "veraltet" (\> 60s): Er löscht den Lock (Self-Healing).
  * **Rotate:** `server.log` wird umbenannt zu `server.log.2023-11-24_10-00-00`.
    *Hinweis:* Der externe Logger (Go/Pharo) muss so konfiguriert sein, dass er beim nächsten Schreibversuch automatisch eine neue Datei öffnet (Standardverhalten vieler Logger auf Linux/Mac).
  * **Archive:** Die umbenannte Datei wird zu `.zip` komprimiert und das Original gelöscht.
  * **Retention:** Alte Backups (älter als die letzten 5) werden gelöscht.
  * **Unlock:** Die `.LOCK` Datei wird entfernt.

## Abhängigkeiten

<sup>(nicht in Pharo Standard Image/Library enthalten)</sup>

  * TSF-Scheduler (für die periodische Ausführung)

## Entwicklungsprozess & Credits

Ein besonderer Dank gilt meinem KI-Sparringspartner für die intensiven und wertvollen Diskussionen während der Entwurfsphase. Die Fähigkeit der KI, verschiedene Architekturansätze (wie *Composition over Inheritance* und *Mocking via Anonymous Subclasses*) schnell zu skizzieren und Vor- und Nachteile abzuwägen, hat die Entwicklung von `TSF-FileRotator` erheblich beschleunigt und die Robustheit des Endergebnisses verbessert.

## License

MIT

## Kontakt

Bei Fragen oder Interesse an diesem Projekt erreichen Sie mich unter:  
📧 *dev.georgh [at] hconsult.biz*

<sup>*(Bitte keine Anfragen an die privaten GitHub-Account-Adressen)*</sup>
