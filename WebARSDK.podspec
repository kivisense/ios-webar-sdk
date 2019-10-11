Pod::Spec.new do |spec|
  spec.name         = "WebARSDK"
  spec.version      = "1.0.0"
  spec.summary      = "WebARSDK"
  spec.homepage     = "https://github.com/kivisense/ios-webar-sdk"
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author       = { "isweal" => "liuliu1994@outlook.com" }

  spec.platform     = :ios
  spec.platform     = :ios, "8.0"

  spec.source       = { :git => "https://github.com/kivisense/ios-webar-sdk'", :tag => "#{spec.version}" }

  spec.requires_arc = true
  spec.source_files = 'WebARSDK/Sources/**/*.{h,m}'
  spec.public_header_files = 'WebARSDK/Sources/**/*.{h}'
  spec.resource  = "WebARSDK/Sources/WEBARView.bundle"

  spec.frameworks = 'Foundation', 'UIKit', 'WebKit', 'AVFoundation'

end