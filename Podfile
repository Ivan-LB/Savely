# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'Savely' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Savely
  pod 'GoogleMLKit/TextRecognition'

  target 'SavelyTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SavelyUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = "arm64"
      end
    end
  end

end
