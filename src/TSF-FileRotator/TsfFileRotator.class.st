Class {
	#name : 'TsfFileRotator',
	#superclass : 'Object',
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
TsfFileRotator >> acquireLock: aLockFile [

	aLockFile exists ifTrue: [
		"Stale Check: is lock older as 60 seconds?"
		(self currentSystemTime - aLockFile modificationTime) > 60 seconds ifTrue: [ 
			Transcript 
				show: '[TsfFileRotator] Removing stale lock: ';
				show: aLockFile basename; cr.
			aLockFile delete. 
			"Now the way is clear for the writeStream below."
		] ifFalse: [ 
			"fresh lock -> cancel"
			^ false 
		].
	].
	

	"Create a lock. We'll write our signature in it.."
	[ 
		aLockFile writeStreamDo: [ 	:s 	| s 
			nextPutAll: 'LOCKED by TsfFileRotator a	t ';
			nextPutAll: self currentSystemTime asString .
		].
		^ true
	] on: Error do: [ :ex | 
		"Could not create file (Permission, Race Condition etc.)"
		^ false 
	].

]

{ #category : 'private - actions' }
TsfFileRotator >> acquireLock: aLockFile retries: anInteger [

	anInteger timesRepeat: [ 
		"Try"
		(self acquireLock: aLockFile) ifTrue: [ ^ true ].

		"Wait short (Backoff)"
		(Delay forMilliseconds: 10) wait.
	].

	"Despite all attempts, still no success."
	^ false
]

{ #category : 'converting' }
TsfFileRotator >> asFileNameString: aDateAndTime [

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

	"determine lock file: meinedatei.log -> meinedatei.log.LOCK"
	lockFile := aFileReference parent / (aFileReference basename , '.LOCK').

	"NEW: we try 3 times (always with 10ms pause)"
	(self acquireLock: lockFile retries: 3) ifFalse: [ 
		Transcript 
			show: '[TsfFileRotator] Skipped locked file (after 3 retries): ';
			show: aFileReference basename; cr.
		^ self 
	].

	[
		"citical section: rename"
		self performRotation: aFileReference.
	] ensure: [ 
		"clean up: Delete the lock, no matter what happens."
		lockFile deleteIfAbsent: [ 
			Transcript 
				show: '[TsfFileRotator] Error deleting lock for ';
				show: aFileReference basename; cr. 
		].
		Transcript show: '[TsfFileRotator] OK '; cr. 
	].

]

{ #category : 'private - accessing' }
TsfFileRotator >> currentSystemTime [

	"actual time. overwrite in tests."
	^ DateAndTime now
]

{ #category : 'executing' }
TsfFileRotator >> execute [
	| fileRef |

	monitoredPaths do: [ :eachPath | 
		"every time create a fresh fileReference on path"
		fileRef := eachPath asFileReference.

		"ask policy"
		(rotationPolicy shouldRotate: fileRef) ifTrue: [ 
			^ self attemptRotationFor: fileRef 
		]
	].

]

{ #category : 'initialization' }
TsfFileRotator >> initializeWithFiles: aCollectionOfFileRefs 
	rotationPolicy: aRotPolicy 
	archiveStrategy: anArchStrategy 
	retentionPolicy: aRetPolicy [

	self initialize.
    
	"IMPORTANT: We only store paths, not file references. 
	 Reason: `renameTo` mutates file references, which would lead to errors on the next iteration."
	monitoredPaths := aCollectionOfFileRefs collect: [ :each | each asPath ].
    
	rotationPolicy := aRotPolicy.
	archiveStrategy := anArchStrategy ifNil: [ TsfNoCompressionStrategy new ].
	retentionPolicy := aRetPolicy.
	
]

{ #category : 'private - actions' }
TsfFileRotator >> performRotation: aFileReference [
	| originalBaseName newName timestamp rotatedRef finalRef |

	"we remember the name (e.g., 'app.log') because aFileReference is mutated immediately."
	originalBaseName := aFileReference basename.
    
	timestamp := self asFileNameString: DateAndTime now.
	"newName := originalBaseName , '.' , timestamp , '.bak'."
	newName := originalBaseName , '.' , timestamp.

	"1. RENAME (Das 'Wegreißen')"
	"Achtung: aFileReference zeigt nun auf die .timestamp Datei!"
	rotatedRef := aFileReference renameTo: newName.
	Transcript show: ('[TsfFileRotator] Rotated to {1}' format: {newName}); cr.
    
	"2. ARCHIVE (Optional Zippen)"
	"reference to zip (or .bak, if no zip) "
	finalRef := archiveStrategy archive: rotatedRef.
    
	"3. RETENTION (CleanUp)"
	retentionPolicy ifNotNil: [ 
		"We create a reference to the original name ('app.log'), so that the policy 
		knows which backups (app.log.*) to count."
		retentionPolicy enforceRetentionFor: (finalRef parent / originalBaseName).
	].

]
