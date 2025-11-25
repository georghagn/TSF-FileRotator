Class {
	#name : 'TsfFileRotatorTaskTest',
	#superclass : 'TsfFileRotatorTest',
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
TsfFileRotatorTaskTest >> setUp [

	super setUp.

	TsfCron reset.
	TsfScheduler reset.
	(Delay forMilliseconds: 10) wait.
	
	TsfScheduler current start.
	TsfCron current start.	
	(Delay forMilliseconds: 10) wait.
]

{ #category : 'running' }
TsfFileRotatorTaskTest >> tearDown [
"Nach dem Test auch wieder aufräumen, falls der Test etwas gestartet hat."

	TsfCron reset.
	TsfScheduler reset.
	
	super tearDown.
]

{ #category : 'tests' }
TsfFileRotatorTaskTest >> testExecuteAction [
"Testet Ausführung standalone (ohne Scheduler)"
	| policy task result |

	policy := TsfFileSizeLimitPolicy new limit: 1024.

	task := TsfFileRotationTask new 
   	 initializeWithFiles: { testFile } 
	    policy: policy.

	result := task executeAction.
	self assert: result.




]

{ #category : 'tests' }
TsfFileRotatorTaskTest >> testSchedule [ 
"Testet Ausführung über Scheduler"
	| policy task ok |

	policy := TsfFileSizeLimitPolicy new limit: 1024.

	task := TsfFileRotationTask new 
   	 initializeWithFiles: { testFile } 
	    policy: policy.

	ok := task schedule.
	(ok isKindOf: TsfTask) ifTrue: [ 
		self assert: true description: 'TsfTask'.
	] ifFalse: [ 
		(ok isKindOf: Boolean) ifTrue: [ 
			self assert: ok
		] ifFalse: [ 
			self assert: false description: ok toString.
		]
	].





]
