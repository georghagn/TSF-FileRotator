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
	| file policy |

	policy := TsfFileSizeLimitPolicy new limit: 1024.

	"Arrange: Datei mit 10 Bytes"
	file := self createFile: 'test.log' content: '0123456789'. 
	policy := TsfFileSizeLimitPolicy new.
    
	"Act & Assert 1: Limit 20 Bytes -> False"
	policy limit: 20.
	self deny: (policy shouldRotate: file).
    
	"Act & Assert 2: Limit 5 Bytes -> True"
	policy limit: 5.
	self assert: (policy shouldRotate: file).

	"Act & Assert 3: Datei existiert nicht -> False"
	file delete.
	self deny: (policy shouldRotate: file).
	
]
