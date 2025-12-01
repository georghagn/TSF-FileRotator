
|<sub>🇩🇪 [German translation →](README.de.md)</sub>|
|----:|
|    |

|[![Pharo Version](https://img.shields.io/badge/Pharo-12.0%2B-blue.svg)](https://pharo.org)|[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE) [![Dependencies](https://img.shields.io/badge/dependencies-zero-brightgreen.svg)](#)|
|----|----|
|![TSF-FileRotator Logo](logo-rotator.png)| ***TSF-FileRotator***<br>A robust, process-independent file rotator for Pharo Smalltalk. Part of the **TSF (Tiny Smalltalk Framework)**-Suite|

<sup>***TSF*** stands for ***Tiny Smalltalk Framework*** — a collection of minimalist tools for robust applications.</sup>

## Overview

**TSF-FileRotator** is a plugin for the TSF Suite. It monitors files (e.g., logs), rotates them based on configurable policies (size, age), and archives them.
It was specifically designed for heterogeneous environments (e.g., **Go-Logger & Pharo-Rotator**) and utilizes file-based locks to safely prevent conflicts during rotation.

## Features

  * **Process-Agnostic:** Rotates files that are written by other processes (Go, Python, OS).
  * **Robust Locking:**
      * Uses `.LOCK` files for synchronization.
      * *Stale-Lock-Protection:* Automatically cleans up orphaned locks after system crashes.
      * *Retry-Logic:* Waits during short write bursts (spin-lock with backoff).
  * **Modular Architecture:**
      * **RotationPolicy:** When to rotate? (e.g., `TsfFileSizeLimitPolicy`).
      * **ArchiveStrategy:** How to store? (e.g., `TsfZipArchiveStrategy` or `TsfNoCompressionStrategy`).
      * **RetentionPolicy:** How many backups to keep? (e.g., `TsfCountRetentionPolicy`).
  * **Design:**
      * Implemented as a **POJO** (Plain Old Smalltalk Object) inheriting from `Object`.
      * No direct dependency on the scheduler within the core logic.
  * **Dual Use:**
      * **Standalone:** Manual triggering via `TsfFileRotator >> execute`.
      * **Scheduled:** Periodic execution via TSF-Scheduler (using the Generic Task Adapter).

## Installation

```smalltalk
Metacello new
    baseline: 'TsfFileRotator';
    repository: 'github://georghagn/TSF-FileRotator:main';
    load.
```

## Usage

The Rotator is a standalone object that is registered in the scheduler using the generic `TsfTask`.

Example: Log rotation with Zip compression and cleanup logic (Retention).

```smalltalk
| logFile rotator task |

"1. The file to monitor"
logFile := FileSystem workingDirectory / 'server.log'.

"2. Configure the Rotator (The Worker)"
rotator := TsfFileRotator new.
rotator configureWithFiles: { logFile }
    rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10 * 1024 * 1024) "10 MB"
    archiveStrategy: (TsfZipArchiveStrategy new)      "Store as .zip"
    retentionPolicy: (TsfCountRetentionPolicy new maxCount: 5). "Keep max 5 backups"

"3. Wrap as Task and hand over to Scheduler"
task := TsfTask 
    named: 'ServerLogRotation' 
    receiver: rotator 
    selector: #execute 
    frequency: 5 minutes.

"4. Schedule it"
TsfCron current addPeriodicTask: task.
```

## How it works

  * **Check:** The rotator checks (via `execute`) if `server.log` exceeds the limit (e.g., 10MB).
  * **Lock:** It attempts to create `server.log.LOCK`.
      * If present: It waits briefly (retries). If still locked, it aborts the current cycle.
      * If lock is "stale" (\> 60s): It deletes the lock (Self-Healing).
  * **Rotate:** `server.log` is renamed to `server.log.2023-11-24_10-00-00`.
      * *Note:* The external logger (Go/Pharo) must be configured to automatically open a new file upon the next write attempt (standard behavior for many loggers on Unix/Mac).
  * **Archive:** The renamed file is compressed to `.zip` and the original is deleted.
  * **Retention:** Old backups (older than the last 5) are deleted.
  * **Unlock:** The `.LOCK` file is removed.

## Dependencies

<sup>(not included in the Pharo Standard Image/Library)</sup>

  * TSF-Scheduler (for periodic execution)

## Development Process & Credits

Special thanks to my AI sparring partner for the intense and valuable discussions during the design phase. The AI's ability to quickly sketch out different architectural approaches (such as *Composition over Inheritance* and *Mocking via Anonymous Subclasses*) and weigh their pros and cons significantly accelerated the development of `TSF-FileRotator` and improved the robustness of the final result.

## License

MIT

## Contact

If you have any questions or are interested in this project, you can reach me at:
📧 *dev.georgh [at] hconsult.biz*

<sup>*(Please do not send inquiries to the private GitHub account addresses)*</sup>
