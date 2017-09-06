# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

def pods
  pod 'Firebase'
  pod 'FirebaseAuth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'JSQMessagesViewController'
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
