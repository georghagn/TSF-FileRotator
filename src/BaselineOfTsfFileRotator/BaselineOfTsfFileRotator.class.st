Class {
	#name : 'BaselineOfTsfFileRotator',
	#superclass : 'Object',
	#category : 'BaselineOfTsfFileRotator',
	#package : 'BaselineOfTsfFileRotator'
}

{ #category : 'baselines' }
BaselineOfTsfFileRotator >> baseline: spec [
	<baseline>

	spec for: #common do: [
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec .
	].
]

{ #category : 'baselines - dependencies' }
BaselineOfTsfFileRotator >> defineDependencies: spec [

	spec
		baseline: 'TsfScheduler'
		with: [ 
			spec repository: 'github://georghagn/tsf-scheduler:main' 
		]. 


]

{ #category : 'baselines - groups' }
BaselineOfTsfFileRotator >> defineGroups: spec [

	spec 
		group: 'Core' with: #('TSF-FileRotator-Core');
		group: 'Tests' with: #('TSF-FileRotator-Tests');
		group: 'default' with: #('Core' 'Tests')
		
]

{ #category : 'baselines - packages' }
BaselineOfTsfFileRotator >> definePackages: spec [

	"Die Reihenfolge und Abhängigkeiten basieren auf unserer Architektur"
	spec package: 'TSF-FileRotator-Policies'.
	spec package: 'TSF-FileRotator-Strategies'.
	spec package: 'TSF-FileRotator-Core' with: [ 
		spec requires: #('TsfScheduler' 'TSF-FileRotator-Policies' 'TSF-FileRotator-Strategies') 
	].

	spec package: 'TSF-FileRotator-Tests' with: [ 
		spec requires: #('TSF-FileRotator-Core') 
	].
]

{ #category : 'accessing' }
BaselineOfTsfFileRotator >> projectClass [
	^ MetacelloCypressBaselineProject
]
