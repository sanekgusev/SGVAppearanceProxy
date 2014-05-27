Pod::Spec.new do |s|

  s.name         = "SGVAppearanceProxy"
  s.version      = "1.0.0"
  s.summary      = "An UIAppearance proxy wrapper to work around performance issues on iOS7."

  s.description  = <<-DESC
                      UIAppearance performs slow under iOS7 because of some internal changes: certain setter methods (those with axis values or those with more than one argument end up calling an expensive method_exchageImplementations() function. 
                      This proxy wraps around original appearance proxy and uses the message forwarding mechanism of Objective-C to translate the affected method calls into methods with a single argument, and then passes them along to the original proxy, thus mitigating the problem.
                   DESC

  s.homepage     = "https://github.com/sanekgusev/SGVAppearanceProxy"

  s.license      = "MIT"
  
  s.author             = { "Alexander Gusev" => "sanekgusev@gmail.com" }
  s.social_media_url   = "http://twitter.com/sanekgusev"

  s.platform     = :ios, "5.0"

  s.source       = { :git => "https://github.com/sanekgusev/SGVAppearanceProxy.git", :tag => "#{s.version}" }

  s.source_files  = "src"

  s.frameworks  = "Foundation", "UIKit"

  s.requires_arc = true

end
