![logo](/logo.png)

- [x] Create unlimited, anonymous identities (Proxies) with just one tap
- [x] Use your Proxies to chat with any other Proxy
- [x] Delete a Proxy when you're done with it. It can no longer be contacted!
- [x] Never share your real contact info with strangers again

#### Development

- Architecture
  - Dependency injection
  - Encapsulation:
    - All properties and functions declared private except where required for protocol conformance
    - Third party dependencies abstracted behind protocols
  - Careful usage of singletons

- UI
  - Co authored [SwiftVideoBackground](https://github.com/dingwilson/SwiftVideoBackground) to manage background video on login screen
  - Twitter-like animated launch screen with [RevealingSplashView](https://github.com/PiXeL16/RevealingSplashView)
  - Onboarding with [paper-onboarding](https://github.com/Ramotion/paper-onboarding)
  - Chat UI built on [MessageKit](https://cocoapods.org/pods/MessageKit)
  - Implemented an efficient [SearchTextField](https://github.com/apasccon/SearchTextField) that makes it fast, easy, and intuitive to search and select the recipient of your message
  - Expressive and responsive UI:
    - Wrote [WQNetworkActivityIndicator](https://github.com/quanvo87/WQNetworkActivityIndicator) to manage network activity indicator
    - Display loading indicator for network requests
    - Animate button taps with [Spring](https://cocoapods.org/pods/Spring)
    - Success/error notifications with [NotificationBannerSwift](https://github.com/Daltron/NotificationBanner) and [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages)
    - Sound and haptics
  - Make elements using storyboard, xibs, and programmatically
  - Set constraints with auto layout and [Pure Layout](https://github.com/PureLayout/PureLayout)
  - Detect device size with [Device](https://github.com/Ekhoo/Device) and adjust UI accordingly
  - Created logo with [Sketch](https://www.sketchapp.com/)
  - Other UI libraries used:
    - [CFAlertViewController](https://github.com/Codigami/CFAlertViewController)
    - [FontAwesome.swift](https://github.com/thii/FontAwesome.swift)
    - [Piano](https://github.com/saoudrizwan/Piano)
    - [SkyFloatingLabelTextField](https://github.com/Skyscanner/SkyFloatingLabelTextField)
    - [SwiftyButton](https://github.com/TakeScoop/SwiftyButton)

- Database
  - Built chat backend from scratch on top of [Firebase](https://firebase.google.com/)
  - Wrote [FirebaseHelper](https://github.com/quanvo87/FirebaseHelper), for safe and easy wrappers around common database functions
  - Flat data structure for performant queries
  - Data is indexed on server for performance
  - All data that is no longer needed is cleaned up when appropriate
  - [Cloud Functions](https://firebase.google.com/docs/functions/) watch for "zombie" data as a result of race conditions and clean them up
  - Pagination load: load some initial data, load more when user scrolls up
  - Email and Facebook authentication
  - Proxy name generating algorithm uses handpicked adjectives and nouns for over half a billion possibilities

- Notifications
  - Apple Push Notifications using [Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/)
  - Open conversation when tap new message notification, play sound, update badge count, etc.
  - Serverless [Cloud Function](https://firebase.google.com/docs/functions/) in Javascript triggers on certain database events, processes, and sends the notification

- Memory management
  - Weak references in closure capture lists
  - Use Instruments for memory profiling

- Concurrency:
  - Wrote [GroupWork](https://github.com/quanvo87/GroupWork) to manage asynchronous tasks in a clean and easily debuggable way

- Testing
  - Tests against development database using XCTest

- Consistent style
  - Function and property naming
  - Function and property ordering
  - Spacing
  - [SwiftLint](https://github.com/realm/SwiftLint)

#### Todo

- UI tests
- Refactor view controllers:
  - Extract elements (UITableViewDatasource, UITableViewDelegate, etc.)
  - More decoupling of view and model

#### Acknowledgements

- Icons and sounds from [Icons8](https://icons8.com/)
- Login screen videos from [Coverr](http://coverr.co/)
- [swiftbysundell.com](https://www.swiftbysundell.com/)
