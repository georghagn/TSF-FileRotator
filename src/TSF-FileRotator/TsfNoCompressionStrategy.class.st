"
Copyright 2025 Georg Hagn
SPDX-License-Identifier: Apache-2.0


"
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
