Class {
	#name : 'TsfFileRotationTask',
	#superclass : 'TsfTask',
	#instVars : [
		'monitoredPaths',
		'rotationPolicy',
		'archiveStrategy',
		'retentionPolicy'
	],
	#category : 'TSF-FileRotator-Core',
	#package : 'TSF-FileRotator',
	#tag : 'Core'
}

{ #category : 'private - actions' }
TsfFileRotationTask >> acquireLock: aLockFile [
	"Gibt true zurück, wenn wir den Lock haben. Löscht verwaiste Locks."

	aLockFile exists ifTrue: [
		"Stale Check: Ist der Lock älter als 60 Sekunden?"
		(DateAndTime now - aLockFile modificationTime) > 60 seconds ifTrue: [ 
			Transcript 
				show: '[TsfFileRotator] Removing stale lock: ';
				show: aLockFile basename; cr.
			aLockFile delete. 
			"Jetzt ist der Weg frei für den writeStream unten"
		] ifFalse: [ 
			"Lock ist frisch -> Abbruch"
			^ false 
		].
	].
	

	"Lock erstellen. Wir schreiben unsere Signatur hinein."
	[ 
		aLockFile writeStreamDo: [ 	:s 	| s 
			nextPutAll: 'LOCKED by TsfFileRotator a	t ';
			nextPutAll: DateAndTime now asString .
		].
		^ true
	] on: Error do: [ :ex | 
		"Konnte Datei nicht anlegen (Permission, Race Condition etc.)"
		^ false 
	].

]

{ #category : 'private - actions' }
TsfFileRotationTask >> attemptRotationFor: aFileReference [
	| lockFile |

	"Lock-Datei bestimmen: meinedatei.log -> meinedatei.log.LOCK"
	lockFile := aFileReference parent / (aFileReference basename , '.LOCK').

	"Versuchen, den Lock zu bekommen (inkl. Stale Check)"
	(self acquireLock: lockFile) ifFalse: [ 
		Transcript 
			show: '[TsfFileRotator] Skip locked file: ';
			show: aFileReference basename; cr.
		^ self
	].

	[
		"Kritische Sektion: Umbenennen"
		self performRotation: aFileReference.
	] ensure: [ 
		"Aufräumen: Lock löschen, egal was passiert"
		lockFile deleteIfAbsent: [ 
			Transcript 
				show: '[TsfFileRotator] Error deleting lock for ';
				show: aFileReference basename; cr. 
		].
		Transcript show: '[TsfFileRotator] OK '; cr. 
	].

]

{ #category : 'converting' }
TsfFileRotationTask >> dasherized: aDateAndTime [
	"z.B. 2023-11-24_14-00-00"
   | stream |
	
	stream := String new writeStream.
	aDateAndTime printYMDOn: stream.
	stream << '_'.
	aDateAndTime printHMSWithDashesOn: stream.

	^ stream contents
	

]

{ #category : 'private - actions' }
TsfFileRotationTask >> executeAction [
	| fileRef |

	monitoredPaths do: [ :eachPath | 
		"Hier erzeugen wir jedes Mal eine frische Referenz auf den Pfad"
		fileRef := eachPath asFileReference.

		"Policy fragen"
		(rotationPolicy shouldRotate: fileRef) ifTrue: [ 
			^ self attemptRotationFor: fileRef 
		]
	].

]

{ #category : 'initialization' }
TsfFileRotationTask >> initializeWithFiles: aCollectionOfFileRefs 
	rotationPolicy: aRotPolicy 
	archiveStrategy: anArchStrategy 
	retentionPolicy: aRetPolicy [

	self initialize.
    
	"WICHTIG: Wir speichern nur Pfade (Paths), keine FileReferences.
	Grund: renameTo: mutiert FileReferences, was beim nächsten 
	Durchlauf zu Fehlern führen würde."
	monitoredPaths := aCollectionOfFileRefs collect: [ :each | each asPath ].
    
	rotationPolicy := aRotPolicy.
	archiveStrategy := anArchStrategy ifNil: [ TsfNoCompressionStrategy new ].
	retentionPolicy := aRetPolicy.
]

{ #category : 'private - actions' }
TsfFileRotationTask >> performRotation: aFileReference [
    | originalBaseName newName timestamp rotatedRef finalRef |
    
    "Wir merken uns den Namen (z.B. 'app.log'), da aFileReference gleich mutiert wird"
    originalBaseName := aFileReference basename.
    
    timestamp := self dasherized: DateAndTime now .
    newName := originalBaseName , '.' , timestamp , '.bak'.
    
    "1. RENAME (Das 'Wegreißen')"
    "Achtung: aFileReference zeigt nun auf die .bak Datei!"
    rotatedRef := aFileReference renameTo: newName.
    Transcript show: ('[TsfFileRotator] Rotated to {1}' format: {newName}); cr.
    
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
