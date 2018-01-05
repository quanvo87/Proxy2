# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

inhibit_all_warnings!

def pods
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'Firebase'
  pod 'FirebaseAuth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'GroupWork', '~> 0.0'
  pod 'MessageKit'
  pod 'Spring', :git => 'https://github.com/MengTo/Spring.git'
  pod 'SwiftVideoBackground', '~> 2.0'
  pod 'ViewGlower'
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
