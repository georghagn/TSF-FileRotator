Class {
	#name : 'TsfFileRotatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile',
		'testDir'
	],
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
TsfFileRotatorTest >> createFile: aFileName content: aString [
	"Hilfsmethode zum schnellen Erstellen von Dateien"
	| file |

	file := testDir / aFileName.
	file writeStreamDo: [ :stream | stream nextPutAll: aString ].
	
	^ file
]

{ #category : 'running' }
TsfFileRotatorTest >> setUp [
	super setUp.

	"Testdatei erzeugen"
	testFile := FileSystem workingDirectory / 'test_data.txt'.
	"testFile := FileLocator workingDirectory / 'test.log'."

	testFile writeStreamDo: [ :s | s nextPutAll: (String new: 1500 withAll: $x) ]. "1.5 KB Datei"

	"Erstellt einen Ordner im OS-Temp-Verzeichnis"
	testDir := FileSystem workingDirectory / ('tsf_test_' , UUID new asString).
	testDir ensureCreateDirectory.
	
]

{ #category : 'running' }
TsfFileRotatorTest >> tearDown [ 

	testFile ensureDelete.
	
	"Löscht den Testordner rekursiv nach jedem Test"
	testDir ensureDeleteAll.
	
	super tearDown 
]

{ #category : 'tests' }
TsfFileRotatorTest >> testSchedulerRunsRotator [
    | logFile rotator task cron scheduler testSemaphore |

    "1. Setup Environment"
    testSemaphore := Semaphore new.
    cron := TsfCron current.
    scheduler := TsfScheduler current.
    
    "Reset sicherstellen"
    cron stop. scheduler stop.

    "2. File vorbereiten (Groß genug für Rotation!)"
    logFile := self createFile: 'integration.log' content: (String new: 2048 withAll: $A).
    logFile := logFile asAbsolute.

    "3. POJO konfigurieren (Das ist dein neuer TsfFileRotator)"
    rotator := TsfFileRotator new.
    rotator configureWithFiles: { logFile }
            rotationPolicy: (TsfFileSizeLimitPolicy new limit: 1024)
            archiveStrategy: nil 
            retentionPolicy: nil.

    "4. Task erstellen (Die Brücke)"
    task := TsfTask 
        named: 'IntegrationTestRotator' 
        receiver: rotator 
        selector: #execute 
        frequency: 50 milliSeconds.

    "WICHTIG für Tests: Wir hängen uns an den Erfolg, um das Semaphore zu signalisieren"
    task onSuccess: [ :result | testSemaphore signal ].

    [
        "5. System starten"
        scheduler start.
        cron start.
        
        "Task einplanen"
        cron addPeriodicTask: task.

        "6. Warten auf das Signal vom Scheduler (via onSuccess)"
        "Wenn das hier durchläuft, hat der Scheduler den Job erfolgreich erledigt"
        testSemaphore waitTimeoutSeconds: 2.
        
        "7. Assertions"
        self deny: logFile exists description: 'Datei sollte rotiert sein'.
        self assert: (testDir childrenMatching: 'integration.log.*') notEmpty description: 'Backup sollte existieren'.
        self assert: task isFinished description: 'Task Status sollte finished sein'.
        
    ] ensure: [
        cron stop.
        scheduler stop.
        cron removeTask: task.
    ].
]
