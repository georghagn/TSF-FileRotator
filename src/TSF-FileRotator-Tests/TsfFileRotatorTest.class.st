Class {
	#name : 'TsfFileRotatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'testFile',
		'testDir'
	],
	#category : 'TSF-FileRotator-Tests-Core',
	#package : 'TSF-FileRotator-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
TsfFileRotatorTest >> createFile: aFileName content: aString [
	"Hilfsmethode zum schnellen Erstellen von Dateien"
	| file |

	file := testDir / aFileName.
	file writeStreamDo: [ :stream | stream nextPutAll: aString ].
	
	^ file
]

{ #category : 'running' }
TsfFileRotatorTest >> setUp [
	super setUp.

	"Testdatei erzeugen"
	testFile := FileSystem workingDirectory / 'test_data.txt'.
	"testFile := FileLocator workingDirectory / 'test.log'."

	testFile writeStreamDo: [ :s | s nextPutAll: (String new: 1500 withAll: $x) ]. "1.5 KB Datei"

	"Erstellt einen Ordner im OS-Temp-Verzeichnis"
	testDir := FileSystem workingDirectory / ('tsf_test_' , UUID new asString).
	testDir ensureCreateDirectory.
	
]

{ #category : 'running' }
TsfFileRotatorTest >> tearDown [ 

	testFile ensureDelete.
	
	"Löscht den Testordner rekursiv nach jedem Test"
	testDir ensureDeleteAll.
	
	super tearDown 
]
