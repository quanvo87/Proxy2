# Proxy - iOS
Create unlimited, anonymous user names (Proxy's) with just one tap. Chat with any other Proxy. Delete your Proxy when you're done. Never share your phone number or email with strangers again.

#### Libraries Used:

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
