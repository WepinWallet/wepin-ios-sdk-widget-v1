#
# Be sure to run `pod lib lint WepinWidget.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WepinWidget'
  s.version          = '1.1.0'
  s.summary          = 'A short description of WepinWidget.'
  s.swift_version    = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/WepinWallet/wepin-ios-sdk-widget-v1'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wepin.dev' => 'wepin.dev@iotrust.kr' }
  s.source           = { :git => 'https://github.com/WepinWallet/wepin-ios-sdk-widget-v1.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'WepinWidget/Classes/**/*'
  
  # s.resource_bundles = {
  #   'WepinWidget' => ['WepinWidget/Assets/*.png']
  # }
   s.requires_arc = true
   
#   s.public_header_files = 'WepinWidget/Classes/ObjC/**/*.h'
   
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'WepinCommon', '~> 1.1.0'
  s.dependency 'WepinStorage', '~> 1.1.0'
  s.dependency 'WepinNetwork', '~> 1.1.0'
  s.dependency 'WepinModal', '~> 1.1.0'
  s.dependency 'WepinSession', '~>1.1.0'
  s.dependency 'WepinLogin', '~> 1.1.0'
#  s.dependency 'WepinLogin'
end
