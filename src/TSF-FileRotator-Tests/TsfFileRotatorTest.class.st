Class {
	#name : 'TsfFileRotatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile'
	],
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
TsfFileRotatorTest >> setUp [
	super setUp.

	"Testdatei erzeugen"
	testFile := FileSystem workingDirectory / 'test_data.txt'.
	"testFile := FileLocator workingDirectory / 'test.log'."

	testFile writeStreamDo: [ :s | s nextPutAll: (String new: 1500 withAll: $x) ]. "1.5 KB Datei"

]

{ #category : 'running' }
TsfFileRotatorTest >> tearDown [ 

	testFile ensureDelete.

	super tearDown 
]
