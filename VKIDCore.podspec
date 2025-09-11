Pod::Spec.new do |spec|
  spec.name = "VKIDCore"
  spec.version = "2.7.1"
  spec.summary = "VKID core functionality. Not for public use."
  spec.homepage = "https://id.vk.ru/business"
    spec.authors = { 'VK ID' => 'devsupport@corp.vk.ru' }
  spec.license = { :type => 'Copyright (c) 2023 - present, LLC “V Kontakte”', :text => <<-LICENSE
1. Permission is hereby granted to any person obtaining a copy of this Software to
use the Software without charge.

2. Restrictions
You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
create derivative works based upon the Software or any part thereof.

3. Termination
This License is effective until terminated. LLC “V Kontakte” may terminate this
License at any time without any negative consequences to our rights.
You may terminate this License at any time by deleting the Software and all copies
thereof. Upon termination of this license for any reason, you shall continue to be
bound by the provisions of Section 2 above.
Termination will be without prejudice to any rights LLC “V Kontakte” may have as
a result of this agreement.

4. Disclaimer of warranty and liability
THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
SPECIFIC RESULTS OF USE OF THE SOFTWARE.
UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
  LICENSE
}

  spec.platform = :ios
  spec.ios.deployment_target = "12.0"
  spec.swift_version = "5.9"
  spec.source = { :git => "https://github.com/VKCOM/vkid-ios-sdk.git", :tag => "#{spec.version}" }
  spec.cocoapods_version = ">= 1.11.2"
  spec.static_framework = true
  spec.dependency 'VKCaptchaSDK', '0.1.1'

  spec.source_files = "VKIDCore/Sources/**/*.swift"
    spec.resource_bundles = {
    'VKID-Core-Resources' => ['VKIDCore/Sources/Resources/*.{xcprivacy}']
  }
  spec.pod_target_xcconfig = {
    'SWIFT_PACKAGE_NAME' => 'VKID'
  }
end
