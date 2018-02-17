# Proxy - iOS
Create unlimited, anonymous user names (Proxy's) with just one tap. Chat with any other Proxy. Delete your Proxy when you're done. Never share your phone number or email with strangers again.

#### Software Development Best Practices Applied:

- Architecture
  - Dependency injection:
    - All dependencies are protocols, so that everything is mockable and easily testable
    - Dependencies have default values in function definitions, so call sites in production are short and simple
  - All properties and functions declared private except when required for protocol conformance
  - Careful usage of singletons

- UI:
  - Make elements using storyboard, xibs, and programmatically
  - Set constraints with auto layout and [Pure Layout](https://github.com/PureLayout/PureLayout)
  - Responsive and expressive UI:
    - Animate button taps with [Spring](https://cocoapods.org/pods/Spring)
    - Wrote the CocoaPod [WQNetworkActivityIndicator](https://github.com/quanvo87/WQNetworkActivityIndicator) to manage network activity indicator
    - Show success/error state with [NotificationBannerSwift](https://github.com/Daltron/NotificationBanner) and [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages)
  - Detect device size with [Device]() and adjust UI accordingly
  - Other UI libraries used:
    - [CFAlertViewController](https://github.com/Codigami/CFAlertViewController)
    - [MessageKit](https://cocoapods.org/pods/MessageKit)
    - [SearchTextField](https://github.com/apasccon/SearchTextField)
    - [SkyFloatingLabelTextField](https://github.com/Skyscanner/SkyFloatingLabelTextField)
    - [SwiftyButton](https://github.com/TakeScoop/SwiftyButton)
    - [FontAwesome.swift](https://github.com/thii/FontAwesome.swift)

- Database
  - [Firebase](https://firebase.google.com/)
  - Wrote the CocoaPod [FirebaseHelper](https://github.com/quanvo87/FirebaseHelper), for safe and easy wrappers around common database functions
  - Flat data structure for more performant queries
  - Dealt with race conditions by checking if an invalid write occurred after the fact, then correcting the error
  - All data that is no longer needed is cleaned up when appropriate
  - Data is indexed on server for performance
  - Load partial data in controller, load more when scroll up, for performance
  - Email and Facebook authentication

- Memory management:
  - Weak references in closure capture lists
  - Use Instruments for memory profiling

- Concurrency:
  - Wrote the CocoaPod [GroupWork](https://github.com/quanvo87/GroupWork) to help with calling and waiting on multiple asynchronous tasks in a clean and easily debuggable way

- Testing
  - Tests against development database using XCTest

- Consistent style:
  - Function and property naming
  - Function and property ordering
  - Spacing
  - [SwiftLint](https://github.com/realm/SwiftLint)

#### Acknowledgements:

Icons from [Icons8](https://icons8.com/).
