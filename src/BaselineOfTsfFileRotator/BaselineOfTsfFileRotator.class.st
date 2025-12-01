Class {
	#name : 'BaselineOfTsfFileRotator',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfTsfFileRotator',
	#package : 'BaselineOfTsfFileRotator'
}

{ #category : 'baselines' }
BaselineOfTsfFileRotator >> baseline: spec [
	<baseline>

    spec for: #common do: [
		spec package: 'TSF-FileRotator'.
		spec package: 'TSF-FileRotator-Tests' with: [ spec requires: #('TSF-FileRotator') ].
    ].

    spec group: 'core' with: #( 'TSF-FileRotator' ).
    spec group: 'tests' with: #( 'TSF-FileRotator-Tests' ).
    spec group: 'default' with: #( 'core' 'tests').

]
