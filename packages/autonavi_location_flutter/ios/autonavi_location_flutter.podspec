Pod::Spec.new do |s|
  s.name             = 'autonavi_location_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for AutoNavi (高德) location services on Android and iOS.'
  s.description      = <<-DESC
A Flutter plugin for AutoNavi (高德) location services on Android and iOS.
Provides continuous location stream and geofencing.
                       DESC
  s.homepage         = 'https://github.com/walkunvs/autonavi-maps-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AutoNavi Maps Flutter' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.static_framework = true

  s.dependency 'Flutter'
  # Pinned to exact version — upgrade intentionally and review the official changelog first.
  # Changelog: https://lbs.amap.com/api/ios-location-sdk/guide/create-project/cocoapods
  s.dependency 'AMapLocation', '2.11.0'
  s.platform         = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
