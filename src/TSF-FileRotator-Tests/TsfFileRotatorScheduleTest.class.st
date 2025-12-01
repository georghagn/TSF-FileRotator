Class {
	#name : 'TsfFileRotatorScheduleTest',
	#superclass : 'TsfFileRotatorTest',
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
TsfFileRotatorScheduleTest >> setUp [
	super setUp.

	TsfCron current start.
	TsfScheduler current start.
	
]

{ #category : 'running' }
TsfFileRotatorScheduleTest >> tearDown [ 

	TsfCron  reset.
	TsfScheduler  reset.
	
	super tearDown 
]

{ #category : 'tests' }
TsfFileRotatorScheduleTest >> testExecuteHappyPath [
	| logFile task backups rotator  |

	"Arrange"
	logFile := self createFile: 'server.log' content: (String new: 100 withAll: $X).

	rotator := TsfFileRotator new 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 50) "Limit überschritten"
		archiveStrategy: (TsfZipArchiveStrategy new)
		retentionPolicy: (TsfCountRetentionPolicy new maxCount: 5).

	task := TsfTask 
		named: 'TsfFileRotatorTest' 
		receiver: rotator 
		selector: #execute.

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
TsfFileRotatorScheduleTest >> testOvercomesStaleLock [
	| logFile task lockFile rotator |

	logFile := self createFile: 'stale.log' content: (String new: 100 withAll: $X).
	lockFile := testDir / 'stale.log.LOCK'.
	lockFile ensureCreateFile.

	"2. Wir erzeugen eine anonyme Subklasse des Tasks on-the-fly"
	rotator := TsfFileRotator newAnonymousSubclass new.

	"3. Wir 'patchen' die Zeit-Methode in dieser Instanz/Klasse.
	Der Task glaubt jetzt, wir sind 2 Stunden in der Zukunft."
	rotator class compile: 'currentSystemTime ^ DateAndTime now + 2 hours'.

	"Trick: Wir setzen das Datum der Lock-Datei auf vor 2 Stunden"
"	oldTime := DateAndTime now - 2 hours.
	lockFile modificationTime oldTime."

	rotator 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10)
		archiveStrategy: nil
		retentionPolicy: nil.

	task := TsfTask 
		named: 'TsfFileRotatorTest' 
		receiver: rotator 
		selector: #execute.

	task execute.
	
	"Assert"
	"Trotz Lock muss rotiert worden sein, weil Lock alt war"
	self deny: logFile exists.
	self assert: (testDir childrenMatching: 'stale.log.*') size equals: 1.
	
]

{ #category : 'tests' }
TsfFileRotatorScheduleTest >> testRetryFailsAfterAttempts [
	| logFile task lockFile start end duration rotator |

	logFile := self createFile: 'busy.log' content: 'data'.
	lockFile := testDir / 'busy.log.LOCK'.
	lockFile ensureCreateFile. "Dauerhafter Lock"

	rotator := TsfFileRotator new 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 1)
		archiveStrategy: nil 
		retentionPolicy: nil.

	start := DateAndTime now.
	task := TsfTask 
		named: 'TsfFileRotatorTest' 
		receiver: rotator 
		selector: #execute.
	end := DateAndTime now.

	start := DateAndTime now.
	task execute.
	end := DateAndTime now.

	duration := end - start.

	"Assert: Die Datei ist noch da (Rotation gescheitert)"
	self assert: logFile exists.

	"Assert: Er hat mind. 30ms gewartet (3 * 10ms)"
	"Wir geben etwas Puffer für Ausführungszeit, sagen wir > 20ms"
	self assert: duration asMilliSeconds > 20.
	
]

{ #category : 'tests' }
TsfFileRotatorScheduleTest >> testSkipsLockedFile [
	| logFile task lockFile rotator|

	"Arrange"
	logFile := self createFile: 'blocked.log' content: (String new: 100 withAll: $X).

	"Wir erstellen manuell eine frische LOCK Datei"
	lockFile := testDir / 'blocked.log.LOCK'.
	lockFile writeStreamDo: [ :s | s nextPutAll: 'BLOCKED' ].

	rotator := TsfFileRotator new 
		initializeWithFiles: { logFile }
		rotationPolicy: (TsfFileSizeLimitPolicy new limit: 10)
		archiveStrategy: nil
		retentionPolicy: nil.

	task := TsfTask 
		named: 'TsfFileRotatorTest' 
		receiver: rotator 
		selector: #execute.

	task execute.

	"Assert"
	"Die Rotation darf NICHT passiert sein, weil gelockt"
	self assert: logFile exists.
	self assert: lockFile exists. "Lock darf nicht gelöscht werden"
	self assert: (testDir childrenMatching: 'blocked.log.*.bak') isEmpty.
	
]
