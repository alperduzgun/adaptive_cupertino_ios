Pod::Spec.new do |s|
  s.name             = 'adaptive_cupertino_ios'
  s.version          = '0.1.0'
  s.summary          = 'Native iOS Cupertino widgets with adaptive platform support'
  s.description      = <<-DESC
Native iOS Cupertino widgets with iOS 18+ Liquid Glass design and automatic fallback.
                       DESC
  s.homepage         = 'https://github.com/yourusername/adaptive_cupertino_ios'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
