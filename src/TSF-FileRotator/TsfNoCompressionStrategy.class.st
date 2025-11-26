Class {
	#name : 'TsfNoCompressionStrategy',
	#superclass : 'TsfArchiveStrategy',
	#category : 'TSF-FileRotator-Strategie',
	#package : 'TSF-FileRotator',
	#tag : 'Strategie'
}

{ #category : 'private - actions' }
TsfNoCompressionStrategy >> archive: aFileReference [
	"Macht nichts, gibt die Datei so zurück wie sie ist."

	^ aFileReference
]
