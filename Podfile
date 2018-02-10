# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

inhibit_all_warnings!

def pods
  pod 'Device', '~> 3.0'
  pod 'FacebookCore', '~> 0.3'
  pod 'FacebookLogin', '~> 0.3'
  pod 'Firebase', '~> 4.8'
  pod 'FirebaseAuth', '~> 4.4'
  pod 'FirebaseDatabase', '~> 4.1'
  pod 'FirebaseHelper', '~> 1.0'
  pod 'GroupWork', '~> 0.0'
  pod 'MessageKit', '~> 0.13'
  pod 'PureLayout', '~> 3.0'
  pod 'SearchTextField', '~> 1.2'
  pod 'Segmentio', '~> 3.0'
  pod 'SkyFloatingLabelTextField', '~> 3.4'
  pod 'Spring', '~> 1.0'
  pod 'SwiftLint', '~> 0.24'
  pod 'SwiftVideoBackground', '~> 2.0'
  pod 'SwiftyButton', '~> 0.8'
  pod 'FontAwesome.swift', '~> 1.3'
  pod 'WQNetworkActivityIndicator', '~> 0.1'
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
