Class {
	#name : 'TsfFileRotationTaskTest',
	#superclass : 'TsfFileRotatorTest',
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
TsfFileRotationTaskTest >> testExecuteHappyPath [
	| logFile task backups |

	"Arrange"
	logFile := self createFile: 'server.log' content: (String new: 100 withAll: $X).

	task := TsfFileRotator new .

    task configureWithFiles: { logFile }
         rotationPolicy: (TsfFileSizeLimitPolicy new limit: 50) "Limit (50) < Größe (100) -> Rotate"
         archiveStrategy: TsfZipArchiveStrategy new
         retentionPolicy: (TsfCountRetentionPolicy new maxCount: 5).

	"Act"
	task execute.
    
	"Assert"
	"1. Original-Datei muss weg sein (oder leer, hier weg weil 'renameTo:')"
	self deny: logFile exists.
    
	"2. Es muss genau ein ZIP Backup geben"
	backups := testDir childrenMatching: 'server.log.*.zip'.
	self assert: backups size equals: 1.
    
	"3. Lock Datei muss weg sein"
	self deny: (testDir / 'server.log.LOCK') exists.
	
]

{ #category : 'tests' }
TsfFileRotationTaskTest >> testOvercomesStaleLock [
    | logFile task lockFile |

    "Arrange"
    logFile := self createFile: 'stale.log' content: (String new: 100 withAll: $X).
    
    "Wir erzeugen manuell ein Lock-File (Zeitstempel = Jetzt)"
    lockFile := testDir / 'stale.log.LOCK'.
    lockFile ensureCreateFile.

    "1. Mocking: Wir leiten vom TASK ab, da dort die Logik (currentSystemTime) liegt"
    task := TsfFileRotator newAnonymousSubclass new.

    "2. Time Travel: Wir patchen die Zeit im Task."
    "Der Task glaubt jetzt, wir sind 2 Stunden in der Zukunft."
    "Dadurch wirkt das gerade erstellte LockFile wie 2 Stunden alt (> 60s Stale Limit)."
    task class compile: 'currentSystemTime ^ DateAndTime now + 2 hours'.

    "3. Konfiguration direkt am Task (ohne Builder)"
    task configureWithFiles: { logFile }
         rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10) "10 < 100 -> Rotate needed"
         archiveStrategy: nil
         retentionPolicy: nil.

    "Act"
    task execute.

    "Assert"
    "Trotz existierendem Lock muss rotiert worden sein, weil das Lock als 'stale' erkannt und gelöscht wurde"
    
    "Original ist weg (rotiert)"
    self deny: logFile exists.
    
    "Backup ist da"
    self assert: (testDir childrenMatching: 'stale.log.*') notEmpty.
    
    "Lock-File wurde sauber abgeräumt"
    self deny: lockFile exists.
]

{ #category : 'tests' }
TsfFileRotationTaskTest >> testRetryFailsAfterAttempts [
    | logFile task lockFile start end duration |

    "1. Log File mit GENUG Inhalt (> 10 Bytes), damit shouldRotate: anspringt"
    logFile := self createFile: 'busy.log' content: (String new: 200 withAll: $X).
    logFile := logFile asAbsolute. 

    "2. Lock File blockiert den Zugriff"
    lockFile := logFile parent / 'busy.log.LOCK'.
    lockFile writeStreamDo: [ :s | s nextPutAll: 'I AM LOCKING THIS' ].

    "3. Task Setup (Plain Object)"
    task := TsfFileRotator new.
    task configureWithFiles: { logFile }
         rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10)
         archiveStrategy: nil
         retentionPolicy: nil.

    "4. Act & Measure"
    start := DateAndTime now.
    task execute. "Ruft direkt die Business-Logik auf, inkl. Delays"
    end := DateAndTime now.

    duration := end - start.

    "5. Assert"
    "Datei existiert noch (weil Rotation gescheitert)"
    self assert: logFile exists.
    
    "Dauer muss > 30ms sein (3x 10ms Wait im Loop)"
    self assert: duration asMilliSeconds >= 30.
]

{ #category : 'tests' }
TsfFileRotationTaskTest >> testSkipsLockedFile [
	| logFile task lockFile |

	"Arrange"
	logFile := self createFile: 'blocked.log' content: (String new: 100 withAll: $X).

	"Wir erstellen manuell eine frische LOCK Datei"
	lockFile := testDir / 'blocked.log.LOCK'.
	lockFile writeStreamDo: [ :s | s nextPutAll: 'BLOCKED' ].

	task := TsfFileRotator new .
	task configureWithFiles: { logFile }
         rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10) "10 < 100 -> Rotate needed"
         archiveStrategy: nil
         retentionPolicy: nil.

	"Assert"
	"Die Rotation darf NICHT passiert sein, weil gelockt"
	self assert: logFile exists.
	self assert: lockFile exists. "Lock darf nicht gelöscht werden"
	self assert: (testDir childrenMatching: 'blocked.log.*.bak') isEmpty.
	
]
