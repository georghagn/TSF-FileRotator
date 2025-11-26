Class {
	#name : 'TsfFileRotationPolicy',
	#superclass : 'Object',
	#category : 'TSF-FileRotator-Core',
	#package : 'TSF-FileRotator',
	#tag : 'Core'
}

{ #category : 'asserting' }
TsfFileRotationPolicy >> shouldRotate: aFileReference [
	
	self subclassResponsibility
]
