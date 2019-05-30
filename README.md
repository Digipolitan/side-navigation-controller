SideNavigationController
=================================

[![Swift Version](https://img.shields.io/badge/swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Build Status](https://travis-ci.org/Digipolitan/side-navigation-controller.svg?branch=master)](https://travis-ci.org/Digipolitan/side-navigation-controller)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SideNavigationController.svg)](https://img.shields.io/cocoapods/v/SideNavigationController.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/SideNavigationController.svg?style=flat)](http://cocoadocs.org/docsets/SideNavigationController)
[![Twitter](https://img.shields.io/badge/twitter-@Digipolitan-blue.svg?style=flat)](http://twitter.com/Digipolitan)

Side navigation controller written in swift.

### Demo iOS

![Demo iOS](https://github.com/Digipolitan/side-navigation-controller/blob/develop/Screenshots/ios_capture.gif?raw=true "Demo iOS")

### Demo tvOS

![Demo tvOS](https://github.com/Digipolitan/side-navigation-controller/blob/develop/Screenshots/tvos_capture.gif?raw=true "Demo tvOS")

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Works with iOS 9+, tested on Xcode 8.2

### Installing

To install the `SideNavigationController` using **cocoapods**

- Add an entry in your Podfile  

```
# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

target 'YourTarget' do
  frameworks
   use_frameworks!

  # Pods for YourTarget
  pod 'SideNavigationController'
end
```

- Then install the dependency with the `pod install` command.

## Usage

How to register the side navigation

```swift
let sideNavigationController = SideNavigationController(mainViewController: UINavigationController(rootViewController: ViewController()))
sideNavigationController.rightSide(viewController: RightViewController())
window.rootViewController = sideNavigationController
self.window = window
```

### Configuration

You can customize the side by passing options:

```swift
let options = SideNavigationController.Options(widthPercent: 0.5,
                                                      scale: 0.9,
                                                   position: .front)
sideNavigationController.rightSide(viewController: RightViewController(),
                                          options: options)
```

Here the list of all available options :

| Property | type | Description  | Default |
| --- | --- | --- | --- |
| widthPercent | `CGFloat` | Size of the side view controller [0-1] | 0.33 |
| animationDuration | `TimeInterval` | How long the animation will last | 0.3 |
| overlayColor | `UIColor` | The overlay color | white |
| overlayOpacity | `CGFloat` | Opacity of the overlay [0-1] |  0.5 |
| shadowColor | `UIColor` | Shadow color around the main or the side view controller | white |
| shadowOpacity | `CGFloat` | Opacity of the shadow [0-1] | 0.8 |
| alwaysInteractionEnabled | `Bool` | Sets to true allows always user interaction on the main view controller | false |
| panningEnabled | `Bool` | Allows panning to display and hide sides | true |
| scale | `CGFloat` | Transform the scale of main view controller during the animation [0-2] | 1 |
| position | `SideNavigationController.Position` | The position of the side, such as below or above the main view controller | back |

## Built With

[Fastlane](https://fastlane.tools/)
Fastlane is a tool for iOS, Mac, and Android developers to automate tedious tasks like generating screenshots, dealing with provisioning profiles, and releasing your application.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details!

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to [contact@digipolitan.com](mailto:contact@digipolitan.com).

## License

SideNavigationController is licensed under the [BSD 3-Clause license](LICENSE).
