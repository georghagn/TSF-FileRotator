"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
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
