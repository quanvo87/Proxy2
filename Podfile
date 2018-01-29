# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

inhibit_all_warnings!

def pods
  pod 'Device'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'Firebase'
  pod 'FirebaseAuth'
  pod 'Firebase/Database'
  pod 'FirebaseHelper', '~> 0.1'
  pod 'GroupWork'
  pod 'MessageKit'
  pod 'SearchTextField'
  pod 'Spring', :git => 'https://github.com/MengTo/Spring.git'
  pod 'SwiftLint'
  pod 'SwiftVideoBackground'
end

target 'Proxy' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Proxy
  pods

  target 'ProxyTests' do
    inherit! :search_paths
    # Pods for testing
    pods
  end

  target 'ProxyUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
