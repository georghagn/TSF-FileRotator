"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
Class {
	#name : 'TsfFileSizeLimitPolicy',
	#superclass : 'TsfFileRotationPolicy',
	#instVars : [
		'limitInBytes'
	],
	#category : 'TSF-FileRotator-Core',
	#package : 'TSF-FileRotator',
	#tag : 'Core'
}

{ #category : 'accessing' }
TsfFileSizeLimitPolicy class >> defaultLimit [ 

	^ 1024.
]

{ #category : 'initialization' }
TsfFileSizeLimitPolicy >> initialize [ 

	super initialize .
	self limit: self class defaultLimit .
]

{ #category : 'accessing' }
TsfFileSizeLimitPolicy >> limit: aByteSize [

	limitInBytes := aByteSize
]

{ #category : 'asserting' }
TsfFileSizeLimitPolicy >> shouldRotate: aFileReference [
	"Rotieren, wenn Datei existiert UND größer als das Limit ist"

	^ aFileReference exists and: [ aFileReference size > limitInBytes ]
]
