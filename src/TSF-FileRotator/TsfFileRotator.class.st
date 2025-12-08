"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
Class {
	#name : 'TsfFileRotator',
	#superclass : 'Object',
	#instVars : [
		'monitoredPaths',
		'rotationPolicy',
		'archiveStrategy',
		'retentionPolicy',
		'logger'
	],
	#category : 'TSF-FileRotator-Core',
	#package : 'TSF-FileRotator',
	#tag : 'Core'
}

{ #category : 'private - actions' }
TsfFileRotator >> acquireLock: aLockFile [
	"Gibt true zurück, wenn wir den Lock haben. Löscht verwaiste Locks."

	aLockFile exists ifTrue: [
		"Stale Check: Ist der Lock älter als 60 Sekunden?"
		(self currentSystemTime - aLockFile modificationTime) > 60 seconds ifTrue: [ 
			aLockFile delete. 
			"Jetzt ist der Weg frei für den writeStream unten"
		] ifFalse: [ 
			"Lock ist frisch -> Abbruch"
			^ false 
		].
	].
	
	[ 
		aLockFile writeStreamDo: [ :s | s nextPutAll: 'LOCKED' ].
		^ true
	] on: Error do: [ ^ false ].

]

{ #category : 'private - actions' }
TsfFileRotator >> acquireLock: aLockFile retries: anInteger [
	"Versucht den Lock mehrfach zu bekommen, bevor aufgegeben wird."

	anInteger timesRepeat: [ 
		"Versuch"
		(self acquireLock: aLockFile) ifTrue: [ ^ true ].

		"Kurz warten (Backoff)"
		(Delay forMilliseconds: 10) wait.
	].

	"Nach allen Versuchen immer noch kein Erfolg"
	^ false

]

{ #category : 'converting' }
TsfFileRotator >> asFileNameString: aDateAndTime [
	"z.B. 2023-11-24_14-00-00"
   | stream |
	
	stream := String new writeStream.
	aDateAndTime printYMDOn: stream.
	stream << '_'.
	aDateAndTime printHMSWithDashesOn: stream.

	^ stream contents
	

]

{ #category : 'private - actions' }
TsfFileRotator >> attemptRotationFor: aFileReference [
	| lockFile |

	lockFile := aFileReference parent / (aFileReference basename , '.LOCK').

	"Retry Logik: 3 Versuche à 10ms"
	(self acquireLock: lockFile retries: 3) ifFalse: [ 
		self logInfo: 'Skipped locked file: ' , aFileReference basename.
		^ self 
	].

	[
		self performRotation: aFileReference.
	] ensure: [ 
		lockFile deleteIfAbsent: [].
	].

]

{ #category : 'configuration' }
TsfFileRotator >> configureWithFiles: aCollectionOfFileRefs rotationPolicy: aRotPolicy 
archiveStrategy: anArchStrategy retentionPolicy: aRetPolicy [

	"Wir speichern absolute Pfade, um Kontext-Probleme zu vermeiden"
    monitoredPaths := aCollectionOfFileRefs collect: [ :each | each asAbsolute asPath ].
    
    rotationPolicy := aRotPolicy.
    archiveStrategy := anArchStrategy ifNil: [ TsfNoCompressionStrategy new ].
    retentionPolicy := aRetPolicy.

]

{ #category : 'private - accessing' }
TsfFileRotator >> currentSystemTime [

	"Gibt die aktuelle Zeit zurück. Kann in Tests überschrieben werden."
	^ DateAndTime now
]

{ #category : 'executing' }
TsfFileRotator >> execute [
    "Das ist der Einstiegspunkt für die Business-Logik."
    | fileRef |

    monitoredPaths do: [ :eachPath | 
        "Jedes Mal eine frische Referenz (wichtig!)"
        fileRef := eachPath asFileReference.

        (rotationPolicy shouldRotate: fileRef) ifTrue: [ 
            self attemptRotationFor: fileRef 
        ]
    ].
]

{ #category : 'error handling' }
TsfFileRotator >> logError: aString [

    logger 
        ifNotNil: [ logger error: '[TsfFileRotator] ', aString ]
        ifNil: [ Transcript show: '[TsfFileRotator ERROR] '; show: aString; cr ]
]

{ #category : 'accessing' }
TsfFileRotator >> logInfo: aString [
    "Die Weiche: Haben wir einen Logger? Wenn ja, nutze ihn. Wenn nein, Transcript."

    logger 
        ifNotNil: [ logger info: '[TsfFileRotator] ', aString ]
        ifNil: [ Transcript show: '[TsfFileRotator] ' ; show: aString; cr ]
]

{ #category : 'private - actions' }
TsfFileRotator >> performRotation: aFileReference [
	| originalBaseName newName timestamp rotatedRef finalRef |

	"Wir merken uns den Namen (z.B. 'app.log'), da aFileReference gleich mutiert wird"
	originalBaseName := aFileReference basename.
    
	timestamp := self asFileNameString: DateAndTime now.
	"newName := originalBaseName , '.' , timestamp , '.bak'."
	newName := originalBaseName , '.' , timestamp.

	"1. RENAME (Das 'Wegreißen')"
	"Achtung: aFileReference zeigt nun auf die .timestamp Datei!"
	rotatedRef := aFileReference renameTo: newName.
	self logInfo: 'Rotated to {1} format: {newName})'.
    
	"2. ARCHIVE (Optional Zippen)"
	"Gibt Referenz auf das Zip (oder die .bak, falls kein Zip) zurück"
	finalRef := archiveStrategy archive: rotatedRef.
    
	"3. RETENTION (Aufräumen)"
	retentionPolicy ifNotNil: [ 
		"Wir bauen eine Referenz auf den Ursprungsnamen ('app.log'), 
		damit die Policy weiß, welche Backups (app.log.*) sie zählen soll."
		retentionPolicy enforceRetentionFor: (finalRef parent / originalBaseName).
	].

]
