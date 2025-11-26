Class {
	#name : 'TsfArchiveStrategy',
	#superclass : 'Object',
	#category : 'TSF-FileRotator-Strategie',
	#package : 'TSF-FileRotator',
	#tag : 'Strategie'
}

{ #category : 'as yet unclassified' }
TsfArchiveStrategy >> archive: aFileReference [
	"Nimmt eine Datei (z.B. log.bak), archiviert sie und gibt die Referenz auf das neue Archiv zurück.
	wenn nichts getan wird, gibt es aFileReference zurück."

	self subclassResponsibility
]
