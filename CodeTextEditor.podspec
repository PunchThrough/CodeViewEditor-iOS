Pod::Spec.new do |s|
  s.name         = "CodeTextEditor"
  s.version      = "0.2.5"
  s.summary      = "A configurable iOS text editor for sourcecode editing"
  s.homepage     = "https://github.com/mplewis/CodeTextEditor"
  s.dependency     'iOS-Rich-Text-Editor', '~> 0.0.1'
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }

  s.author             = { "Punch Through Design" => "info@punchthrough.com" }
  s.ios.deployment_target = "7.0"
  s.social_media_url   = "http://punchthrough.com/"
  s.source       = { :git => "https://github.com/mplewis/CodeTextEditor.git", :tag => s.version.to_s }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.public_header_files = "Classes/Public/**/*.h"

  s.resources = "Resources/*.*"
  s.requires_arc = true
end
