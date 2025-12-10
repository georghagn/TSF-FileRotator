"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
Class {
	#name : 'TsfArchiveStrategy',
	#superclass : 'Object',
	#instVars : [
		'logger'
	],
	#category : 'TSF-FileRotator-Strategie',
	#package : 'TSF-FileRotator',
	#tag : 'Strategie'
}

{ #category : 'subclassing' }
TsfArchiveStrategy >> archive: aFileReference [
	"Nimmt eine Datei (z.B. log.bak), archiviert sie und gibt die Referenz auf das neue Archiv zurück.
	wenn nichts getan wird, gibt es aFileReference zurück."

	self subclassResponsibility
]

{ #category : 'error handling' }
TsfArchiveStrategy >> logError: aString [

    logger 
        ifNotNil: [ logger error: '[TsfArchiveStrategy] ', aString ]
        ifNil: [ Transcript show: '[TsfArchiveStrategy ERROR] '; show: aString; cr ]
]

{ #category : 'accessing' }
TsfArchiveStrategy >> logInfo: aString [
    "Die Weiche: Haben wir einen Logger? Wenn ja, nutze ihn. Wenn nein, Transcript."

    logger 
        ifNotNil: [ logger info: '[ArchiveStrategy] ', aString ]
        ifNil: [ Transcript show: '[ArchiveStrategy] ' ; show: aString; cr ]
]

{ #category : 'accessing' }
TsfArchiveStrategy >> logger: aLogger [

	logger := aLogger 
]
