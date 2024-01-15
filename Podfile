# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Delgo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Delgo

    pod 'SnapKit', '~> 5.6.0'
    pod 'Then'
    pod 'FBAudienceNetwork'
    pod 'FBSDKCoreKit/Swift'
    pod 'AirBridge', '1.33.4'
    pod 'SDWebImage'
    pod 'SDWebImageWebPCoder'

  # Pods for Firebase
    # Add the Firebase pod for Google Analytics
    pod 'FirebaseAnalytics'
    pod 'FirebaseMessaging'
    
    target 'NotificationService' do
       inherit! :search_paths
       # Pods for NotificationService
       pod 'SDWebImage'
       pod 'SDWebImageWebPCoder'
     end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
end
end
