Class {
	#name : 'TsfCountRetentionPolicyTest',
	#superclass : 'TsfFileRotatorTest',
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
TsfCountRetentionPolicyTest >> testEnforceRetention [
	| original policy |

	original := self createFile: 'app.log' content: 'main'.

	"Wir simulieren 3 Backups mit leicht unterschiedlichen Zeitstempeln"
	self createFile: 'app.log.1.bak' content: 'oldest'.
	(Delay forMilliseconds: 100) wait.
	
	self createFile: 'app.log.2.bak' content: 'middle'.
	(Delay forMilliseconds: 100) wait.
	
	self createFile: 'app.log.3.bak' content: 'newest'.

	"Policy: Behalte nur 1 Backup"
	policy := TsfCountRetentionPolicy new maxCount: 1.

	"Act"
	policy enforceRetentionFor: original.
    
	"Assert"
	"Das Neueste (3) und das Original müssen noch da sein"
	self assert: (testDir / 'app.log.3.bak') exists.
	self assert: (testDir / 'app.log') exists.
    
	"Die Älteren müssen weg sein"
	self deny: (testDir / 'app.log.1.bak') exists.
	self deny: (testDir / 'app.log.2.bak') exists.
	
]
