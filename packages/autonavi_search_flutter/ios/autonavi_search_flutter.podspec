Pod::Spec.new do |s|
  s.name             = 'autonavi_search_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for AutoNavi (高德) search services on Android and iOS.'
  s.description      = <<-DESC
A Flutter plugin for AutoNavi (高德) search services on Android and iOS.
Provides POI search, geocoding, and route planning.
                       DESC
  s.homepage         = 'https://github.com/walkunvs/autonavi-maps-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AutoNavi Maps Flutter' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.static_framework = true

  s.dependency 'Flutter'
  s.dependency 'AMapSearch', '~> 9.7'
  s.platform         = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
