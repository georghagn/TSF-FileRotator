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

	task := TsfFileRotationTask new 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 50) "Limit überschritten"
		archiveStrategy: (TsfZipArchiveStrategy new)
		retentionPolicy: (TsfCountRetentionPolicy new maxCount: 5).

	"Act"
	task executeAction.
    
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

	logFile := self createFile: 'stale.log' content: (String new: 100 withAll: $X).
	lockFile := testDir / 'stale.log.LOCK'.
	lockFile ensureCreateFile.

	"2. Wir erzeugen eine anonyme Subklasse des Tasks on-the-fly"
	task := TsfFileRotationTask newAnonymousSubclass new.

	"3. Wir 'patchen' die Zeit-Methode in dieser Instanz/Klasse.
	Der Task glaubt jetzt, wir sind 2 Stunden in der Zukunft."
	task class compile: 'currentSystemTime ^ DateAndTime now + 2 hours'.

	"Trick: Wir setzen das Datum der Lock-Datei auf vor 2 Stunden"
"	oldTime := DateAndTime now - 2 hours.
	lockFile modificationTime oldTime."

	task 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10)
		archiveStrategy: nil
		retentionPolicy: nil.

	"Act"
	task executeAction.

	"Assert"
	"Trotz Lock muss rotiert worden sein, weil Lock alt war"
	self deny: logFile exists.
	self assert: (testDir childrenMatching: 'stale.log.*') size equals: 1.
	
]

{ #category : 'tests' }
TsfFileRotationTaskTest >> testRetryFailsAfterAttempts [
	| logFile task lockFile start end duration |

	logFile := self createFile: 'busy.log' content: 'data'.
	lockFile := testDir / 'busy.log.LOCK'.
	lockFile ensureCreateFile. "Dauerhafter Lock"

	task := TsfFileRotationTask new 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 1)
		archiveStrategy: nil 
	retentionPolicy: nil.

	start := DateAndTime now.
	task executeAction.
	end := DateAndTime now.

	duration := end - start.

	"Assert: Die Datei ist noch da (Rotation gescheitert)"
	self assert: logFile exists.

	"Assert: Er hat mind. 30ms gewartet (3 * 10ms)"
	"Wir geben etwas Puffer für Ausführungszeit, sagen wir > 20ms"
	self assert: duration asMilliSeconds > 20.
	
]

{ #category : 'tests' }
TsfFileRotationTaskTest >> testSkipsLockedFile [
	| logFile task lockFile |

	"Arrange"
	logFile := self createFile: 'blocked.log' content: (String new: 100 withAll: $X).

	"Wir erstellen manuell eine frische LOCK Datei"
	lockFile := testDir / 'blocked.log.LOCK'.
	lockFile writeStreamDo: [ :s | s nextPutAll: 'BLOCKED' ].

	task := TsfFileRotationTask new 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10)
		archiveStrategy: nil
		retentionPolicy: nil.

	"Act"
	task executeAction.

	"Assert"
	"Die Rotation darf NICHT passiert sein, weil gelockt"
	self assert: logFile exists.
	self assert: lockFile exists. "Lock darf nicht gelöscht werden"
	self assert: (testDir childrenMatching: 'blocked.log.*.bak') isEmpty.
	
]
