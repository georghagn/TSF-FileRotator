Class {
	#name : 'TsfFileSizeLimitPolicyTest',
	#superclass : 'TsfFileRotatorTest',
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
TsfFileSizeLimitPolicyTest >> testShouldNotRotate [
	"Policy: Alles über 1KB rotieren"
	| policy |

	policy := TsfFileSizeLimitPolicy new limit: 2048.
	
	self assert: (policy shouldRotate: testFile) not.
]

{ #category : 'tests' }
TsfFileSizeLimitPolicyTest >> testShouldRotate [
	"Policy: Alles über 1KB rotieren"
	| policy |

	policy := TsfFileSizeLimitPolicy new limit: 1024.
]
