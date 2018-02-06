# Proxy - iOS
Create unlimited, anonymous user names (Proxy's) with just one tap. Chat with any other Proxy. Delete your Proxy when you're done. Never share your phone number or email with strangers again.

#### Software Development Best Practices Applied:

- Architecture
  - Dependency injection:
    - All dependencies are protocols, so that everything is mockable and easily testable
    - Dependencies have default values in function definitions, so call sites in production are short and simple
  - Controllers, classes, etc. only know about themselves
  - All properties and functions declared private except when required for protocol conformance
  - Careful usage of singletons

- Database
  - [Firebase](https://firebase.google.com/)
  - Wrote the CocoaPod [FirebaseHelper](https://github.com/quanvo87/FirebaseHelper), used for its safe and easy to use wrappers around common database functions
  - Flat data structure for performant queries
  - Dealt with race conditions by checking if an invalid write occurred after the fact, then correcting the error
  - All data that is no longer needed is cleaned up when appropriate
  - Data is indexed on server for performance
  - Load partial data in controller, load more when scroll up, for performance
  - Email or Facebook authentication

- Concurrency:
  - Wrote the CocoaPod [GroupWork](https://github.com/quanvo87/GroupWork) to help with calling and waiting on multiple asynchronous tasks in a clean and easily debuggable way
  - Search text field:
    - When user stops typing:
      - Cancel previous `DispatchWorkItem`
      - Fire off search query after 250 ms
      - Limits amount of unnecessary queries

- Memory management:
    - Weak references in closure capture lists
    - Use Instruments for memory profiling

- Swift features:
  - Protocols:
    - Composition
      - Separation of concerns
      - Multiple protocol conformance when needed
    - Extensions with constraints
    - Default implementations
    - Separate protocol conformance in extensions for readability
  - Collections operations: forEach, flatMap
  - Lazy properties
  - Self executing closures
  - Never force down cast

- UI:
  - Storyboard, xibs, and programmatically
  - Constraints for correct display on different device sizes
  - Different UI element and font sizes based on device size
  - Wrote the CocoaPod [WQNetworkActivityIndicator](https://github.com/quanvo87/WQNetworkActivityIndicator) to manage showing the network activity indicator during network requests
  - Co-authored the CocoaPod [SwiftVideoBackground](https://github.com/dingwilson/SwiftVideoBackground), which plays the log in screen background video

- Testing
  - Tests against development database using XCTest

- Error handling:
  - `ProxyError` implements `Error`
  - Callbacks return `Result` enum when appropriate:

  ```swift
  enum Result<T, Error> {
      case success(T)
      case failure(Error)
  }
  ```

  > Avoid unnecessary optionals

  > More error information than just a `nil` object

- Consistent style:
  - Function and property naming
  - Function and property ordering
  - Spacing
  - [SwiftLint](https://github.com/realm/SwiftLint)

#### Acknowledgements:

Knowledge:
 - @johnsundell and his [Swift blog](https://www.swiftbysundell.com/)
 - Many others

[CocoaPods](https://cocoapods.org/) used:

- [Device](https://cocoapods.org/pods/Device)
- [Facebook](https://cocoapods.org/pods/FacebookCore)
- [Firebase](https://cocoapods.org/pods/Firebase)
- [FirebaseHelper](https://github.com/quanvo87/FirebaseHelper)
- [GroupWork](https://github.com/quanvo87/GroupWork)
- [MessageKit](https://cocoapods.org/pods/MessageKit)
- [SearchTextField](https://cocoapods.org/pods/SearchTextField)
- [Spring](https://cocoapods.org/pods/Spring)
- [SwiftLint](https://cocoapods.org/pods/SwiftLint)
- [SwiftVideoBackground](https://cocoapods.org/pods/SwiftVideoBackground)
- [WQNetworkActivityIndicator](https://github.com/quanvo87/WQNetworkActivityIndicator)

Icons from [Icons8](https://icons8.com/).

#### Develop Locally:

- Clone the repo: `git clone https://github.com/quanvo87/Proxy`
- `cd` into the directory and run `pod install`
- Follow these [instructions](https://firebase.google.com/docs/ios/setup) to:
  - Create a new Firebase project,
  - Add Firebase to your iOS app
  - Download the `GoogleService-Info.plist` (no need to do anything else from that page)
- Inside the `Proxy` directory, there is another directory called `Proxy`, `cd` into that, and make a directory called `Firebase`, then in that directory make a directory called `Dev`
- Place the `GoogleService-Info.plist` in the `Dev` folder
- The path should be `/Proxy/Proxy/Firebase/Dev/GoogleService-Info.plist`
- Make a test user in your database, and put in the appropriate credentials in `ProxyTests/FirebaseTest.swift`
- You should now be able to run Proxy tests on your database (in debug mode, which is the default)
