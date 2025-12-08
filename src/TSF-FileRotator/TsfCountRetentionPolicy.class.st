"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
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

	backupPattern := aOriginalFileReference basename , '.*'.
	backups := aOriginalFileReference parent childrenMatching: backupPattern.

	backups size <= maxCount ifTrue: [ ^ self ].

	"FIX: Tie-Breaker hinzufügen für Dateien mit identischem Timestamp!"
	backups := backups sorted: [ :a :b | 
		a modificationTime = b modificationTime
			ifTrue: [ a basename > b basename ] "Sekundäres Kriterium: Name (z.B. log.2025... > log.2024...)"
			ifFalse: [ a modificationTime > b modificationTime ] "Primäres Kriterium: Zeit"
	].

	toDelete := backups copyFrom: (maxCount + 1) to: backups size.

	toDelete do: [ :each | 
		each delete.
		Transcript 
			show: '[TsfRetention] Deleted: ';
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
