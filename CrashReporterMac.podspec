Pod::Spec.new do |s|
  s.name             = 'CrashReporterMac'
  s.version          = '0.1.0'
  s.summary          = 'Collects and sends crash reports for macOS applications.'

  s.description      = <<-DESC
                       macOS framework to prompt users to send crash logs after your app has crashes. 

                       Supports automatically sending reports if the user choses to.
                       DESC

  s.homepage         = 'https://github.com/CleanCocoa/CrashReporter'
  s.screenshots      = 'https://raw.githubusercontent.com/CleanCocoa/CrashReporter/master/assets/reporter-light.png', 'https://raw.githubusercontent.com/CleanCocoa/CrashReporter/master/assets/reporter-dark.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Tietze' => 'me@christiantietze.de' }
  s.social_media_url = 'https://twitter.com/ctietze'

  s.source           = { :git => 'https://github.com/CleanCocoa/CrashReporter.git', :tag => s.version.to_s }
  s.platform = :macos, '10.11'
  s.swift_version = '5'
  s.source_files = 'Sources/**/*.swift'
  s.frameworks = 'Cocoa'
end
