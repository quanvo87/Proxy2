# Proxy - iOS

- [x] Create unlimited, anonymous identities (Proxy's) with just one tap
- [x] Use your Proxy to chat with any other Proxy
- [x] Delete your Proxy when you're done
- [x] Never share your real contact info with strangers again

#### Development:

- Architecture
  - Dependency injection:
    - All dependencies are protocols, so that everything is mockable and easily testable
    - Dependencies have default values in function definitions, so call sites in production are short and simple
  - Encapsulation:
    - All properties and functions declared private except when required for protocol conformance
    - Third party dependencies like my [database](https://firebase.google.com/) abstracted behind protocols
  - Careful usage of singletons

- UI:
  - Co authored [SwiftVideoBackground](https://github.com/dingwilson/SwiftVideoBackground) to manage background video on login screen
  - Make elements using storyboard, xibs, and programmatically
  - Set constraints with auto layout and [Pure Layout](https://github.com/PureLayout/PureLayout)
  - Responsive and expressive UI:
    - Wrote [WQNetworkActivityIndicator](https://github.com/quanvo87/WQNetworkActivityIndicator) to manage network activity indicator
    - Animate button taps with [Spring](https://cocoapods.org/pods/Spring)
    - Show loading indicators in buttons
    - Show success/error state notifications with [NotificationBannerSwift](https://github.com/Daltron/NotificationBanner) and [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages)
  - Detect device size with [Device](https://github.com/Ekhoo/Device) and adjust UI accordingly
  - Other UI libraries used:
    - [CFAlertViewController](https://github.com/Codigami/CFAlertViewController)
    - [MessageKit](https://cocoapods.org/pods/MessageKit)
    - [SearchTextField](https://github.com/apasccon/SearchTextField)
    - [SkyFloatingLabelTextField](https://github.com/Skyscanner/SkyFloatingLabelTextField)
    - [SwiftyButton](https://github.com/TakeScoop/SwiftyButton)
    - [FontAwesome.swift](https://github.com/thii/FontAwesome.swift)

- Database
  - Built chat backend from scratch on top of [Firebase](https://firebase.google.com/)
  - Wrote [FirebaseHelper](https://github.com/quanvo87/FirebaseHelper), for safe and easy wrappers around common database functions
  - Flat data structure for more performant queries
  - Dealt with race conditions by checking if an invalid write occurred after the fact, then correcting the error
  - All data that is no longer needed is cleaned up when appropriate
  - Data is indexed on server for performance
  - Pagination load: load some initial data, load more when user scrolls up
  - Email and Facebook authentication

- Memory management:
  - Weak references in closure capture lists
  - Use Instruments for memory profiling

- Concurrency:
  - Wrote [GroupWork](https://github.com/quanvo87/GroupWork) to manage asynchronous tasks in a clean and easily debuggable way

- Testing
  - Tests against development database using XCTest

- Consistent style:
  - Function and property naming
  - Function and property ordering
  - Spacing
  - [SwiftLint](https://github.com/realm/SwiftLint)

#### Acknowledgements:

- Icons from [Icons8](https://icons8.com/)
- Login screen videos from [Coverr](http://coverr.co/)
