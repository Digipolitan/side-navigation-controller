workspace 'SideNavigationController.xcworkspace'

## Frameworks targets
abstract_target 'Frameworks' do
	use_frameworks!
	target 'SideNavigationController-iOS' do
		platform :ios, '9.0'
	end

	target 'SideNavigationController-tvOS' do
		platform :tvos, '9.0'
	end
end

## Tests targets
abstract_target 'Tests' do
	use_frameworks!
	target 'SideNavigationControllerTests-iOS' do
		platform :ios, '8.0'
	end

	target 'SideNavigationControllerTests-tvOS' do
		platform :tvos, '9.0'
	end
end

## Samples targets
abstract_target 'Samples' do
	use_frameworks!
	target 'SideNavigationControllerSample-iOS' do
		project 'Samples/SideNavigationControllerSample-iOS/SideNavigationControllerSample-iOS'
		platform :ios, '8.0'
	end

	target 'SideNavigationControllerSample-tvOS' do
		project 'Samples/SideNavigationControllerSample-tvOS/SideNavigationControllerSample-tvOS'
		platform :tvos, '9.0'
	end
end
