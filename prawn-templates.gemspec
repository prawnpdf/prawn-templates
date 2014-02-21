Gem::Specification.new do |spec|
  spec.name = "prawn-templates"
  spec.version = File.read(File.expand_path('VERSION', File.dirname(__FILE__))).strip
  spec.platform = Gem::Platform::RUBY
  spec.summary = "Prawn::Templates allows using PDFs as templates in Prawn"
  spec.files =  Dir.glob("{lib}/**/**/*") +
                ["prawn-templates.gemspec"]
  spec.require_path = "lib"
  spec.required_ruby_version = '>= 1.9.3'
  spec.required_rubygems_version = ">= 1.3.6"

  spec.authors = ["Gregory Brown","Brad Ediger","Daniel Nelson","Jonathan Greenberg","James Healy"]
  spec.email = ["gregory.t.brown@gmail.com","brad@bradediger.com","dnelson@bluejade.com","greenberg@entryway.net","jimmy@deefa.com"]
  spec.add_dependency('pdf-reader', '~>1.3')
  spec.add_dependency('prawn', '>= 0.15.0')
  spec.add_development_dependency('pdf-inspector', '~> 1.1.0')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rake')
  spec.homepage = "http://prawn.majesticseacreature.com"
  spec.description = "Prawn::Templates allows using PDFs as templates in Prawn"
end
