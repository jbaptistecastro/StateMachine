Pod::Spec.new do |s|
  s.name         = "StateMachine"
  s.version      = "1.0.0"
  s.summary      = "A thread safe state machine implemented in pure Swift"
  s.homepage     = "https://github.com/jbaptistecastro/StateMachine"
  s.license      = { :type => "MIT" }
  s.author             = { "Jean-Baptiste Castro" => "jbaptistecastro@gmail.com" }
  s.social_media_url   = "http://twitter.com/jbaptistecastro"

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"

  s.source       = { :git => "https://github.com/jbaptistecastro/StateMachine.git", :tag => s.version.to_s }
  s.source_files              = "Sources/**/*.swift"
  s.module_name               = "StateMachine"
end
