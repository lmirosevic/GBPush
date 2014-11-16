Pod::Spec.new do |s|
  s.name                  = 'GBPush'
  s.version               = '1.1.0'
  s.summary               = 'Objective-C client library for Goonbee\'s push service, for iOS and OS X.'
  s.homepage              = 'https://github.com/lmirosevic/GBPush'
  s.license               = { type: 'Apache License, Version 2.0', file: 'LICENSE' }
  s.author                = { 'Luka Mirosevic' => 'luka@goonbee.com' }
  s.source                = { git: 'https://github.com/lmirosevic/GBPush.git', tag: s.version.to_s, submodules: true }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.requires_arc          = true
  s.source_files          = 'GBPush.{h,m}', 'GBPushApi.{h,m}', 'thrift/gen-cocoa/GoonbeePushService.{h,m}'
  s.public_header_files   = 'GBPush.h', 'GBPushApi.h', 'thrift/gen-cocoa/GoonbeePushService.h'

  s.dependency 'GBToolbox'
  s.dependency 'GBStorage', '~> 2.1'
  s.dependency 'GBThriftApi', '~> 1.0'
end
