Class {
	#name : 'TsfZipArchiveStrategy',
	#superclass : 'TsfArchiveStrategy',
	#instVars : [
		'compressionLevel'
	],
	#classVars : [
		'CompressionDeflated',
		'CompressionLevelDefault',
		'CompressionLevelNone',
		'CompressionStored',
		'DeflatingCompressionFast',
		'DeflatingCompressionMaximum',
		'DeflatingCompressionNormal',
		'DeflatingCompressionSuperFast'
	],
	#category : 'TSF-FileRotator-Strategie',
	#package : 'TSF-FileRotator',
	#tag : 'Strategie'
}

{ #category : 'as yet unclassified' }
TsfZipArchiveStrategy class >> defaultCompressionLevel [

	^ CompressionLevelDefault .
]

{ #category : 'class initialization' }
TsfZipArchiveStrategy class >> initialize [ 

	CompressionDeflated			:= 8.
	CompressionLevelNone			:= 0.
	CompressionLevelDefault		:= 6.
]

{ #category : 'private - actions' }
TsfZipArchiveStrategy >> archive: aFileReference [
	| zipFileName zipRef zip |

	"Zielname: app.log.2023...bak -> app.log.2023...bak.zip"
	zipFileName := aFileReference basename , '.zip'.
	zipRef := aFileReference parent / zipFileName.

	[
		zip := ZipArchive new.

		"Datei zum Zip hinzufügen. 
		'as:': Wir wollen nur den Dateinamen im Zip, nicht den ganzen Pfad."
		zip addFile: aFileReference fullName as: aFileReference basename.

		"Zip auf Platte schreiben"
		zip writeToFile: zipRef.
		zip close.

		"Erfolg: Originale .bak löschen"
		aFileReference delete.

		Transcript 
			show: '[TsfFileRotator] Zipped: ';
			show: zipRef basename; cr.
        
		"Wir geben das Zip zurück, falls nachfolgende Prozesse (Retention) das brauchen"
		^ zipRef
        
	] on: Error do: [ :ex |
		Transcript 
			show: '[TsfFileRotator] Zip failed: '; 
			show: ex messageText; cr.
		"Bei Fehler: Zip (falls halb fertig) löschen, Original behalten"
		zipRef ensureDelete.
		^ aFileReference
	].

]

{ #category : 'initialization' }
TsfZipArchiveStrategy >> initialize [

	super initialize.
	
	compressionLevel := self class defaultCompressionLevel.
]
