Class {
	#name : 'TsfRetentionPolicy',
	#superclass : 'Object',
	#category : 'TSF-FileRotator-Strategie',
	#package : 'TSF-FileRotator',
	#tag : 'Strategie'
}

{ #category : 'as yet unclassified' }
TsfRetentionPolicy >> enforceRetentionFor: aOriginalFileReference [

	self subclassResponsibility
]
