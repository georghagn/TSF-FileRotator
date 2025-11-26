Class {
	#name : 'TsfCountRetentionPolicy',
	#superclass : 'TsfRetentionPolicy',
	#instVars : [
		'maxCount'
	],
	#category : 'TSF-FileRotator-Strategie',
	#package : 'TSF-FileRotator',
	#tag : 'Strategie'
}

{ #category : 'as yet unclassified' }
TsfCountRetentionPolicy class >> defaultMaxCount [

	^ 3
]

{ #category : 'private - actions' }
TsfCountRetentionPolicy >> enforceRetentionFor: aOriginalFileReference [
	| backupPattern backups toDelete |

	"Muster: original.log.* (findet sowohl .bak als auch .zip)"
	backupPattern := aOriginalFileReference basename , '.*'.

	"Alle passenden Dateien im Ordner suchen"
	backups := aOriginalFileReference parent childrenMatching: backupPattern.

	"Wenn wir weniger haben als das Limit, sind wir fertig"
	backups size <= maxCount ifTrue: [ ^ self ].

	"Sortieren: Neueste zuerst (anhand Änderungsdatum)"
	backups := backups sorted: [ :a :b | a modificationTime > b modificationTime ].

	"Die 'Überzähligen' identifizieren (ab index maxCount + 1 bis Ende)"
	toDelete := backups copyFrom: (maxCount + 1) to: backups size.

	"Löschen"
	toDelete do: [ :each | 
		each delete.
		Transcript 
			show: '[TsfRetention] Deleted old backup: ';
			show: each basename; cr.
	].


]

{ #category : 'initialization' }
TsfCountRetentionPolicy >> initialize [ 

	super initialize.
	
	maxCount := self class defaultMaxCount .
]

{ #category : 'accessing' }
TsfCountRetentionPolicy >> maxCount: anInteger [

	maxCount := anInteger.
]
