Pod::Spec.new do |s|
s.name             = 'AppNexusSDK-NoEventKit'
s.version          = '3.5.1'
s.summary          = 'AppNexus iOS Mobile Advertising SDK'
s.description      = <<-DESC
Our mobile advertising SDK gives developers a fast and convenient way to monetize their apps.
DESC

s.homepage         = 'https://github.com/appnexus/mobile-sdk-ios'
s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
s.author           = { 'Jose Cabal-Ugaz' => 'josecu@appnexus.com' }
s.source           = { :git => 'https://github.com/ikovalisko/mobile-sdk-ios.git', :branch => 'master' }

s.ios.deployment_target = '8.0'

s.source_files = 'sdk/**/*.{h,m}'
s.public_header_files = 'sdk/*.h', 'sdk/native/*.h'
s.resources = 'sdk/**/*.{png,bundle,xib,nib,js,html,strings}'

s.frameworks = 'WebKit'

end
