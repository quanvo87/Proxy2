platform :ios, '11.0'

inhibit_all_warnings!

def pods
  pod 'CFAlertViewController', '~> 3.0'
  pod 'Device', '~> 3.0'
  pod 'FacebookCore', '~> 0.3'
  pod 'FacebookLogin', '~> 0.3'
  pod 'Firebase', '~> 4.8'
  pod 'FirebaseAuth', '~> 4.4'
  pod 'FirebaseDatabase', '~> 4.1'
  pod 'FirebaseHelper', '~> 1.0'
  pod 'GroupWork', '~> 0.0'
  pod 'MessageKit', '~> 0.13'
  pod 'NotificationBannerSwift', '~> 1.6'
  pod 'PureLayout', '~> 3.0'
  pod 'SearchTextField', '~> 1.2'
  pod 'Segmentio', '~> 3.0'
  pod 'SkyFloatingLabelTextField', '~> 3.4'
  pod 'Spring', '~> 1.0'
  pod 'SwiftLint', '~> 0.24'
  pod 'SwiftMessages', '~> 4.1'
  pod 'SwiftVideoBackground', '~> 2.1'
  pod 'SwiftyButton', '~> 0.8'
  pod 'FontAwesome.swift', '~> 1.3'
  pod 'WQNetworkActivityIndicator', '~> 0.1'
end

target 'Proxy' do
  use_frameworks!

  pods

  target 'ProxyTests' do
    inherit! :search_paths
    pods
  end

  target 'ProxyUITests' do
    inherit! :search_paths
  end

end
