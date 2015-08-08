Gem::Specification.new do |spec|
  spec.name = "prawn-templates"
  spec.version = File.read(File.expand_path('VERSION', File.dirname(__FILE__))).strip
  spec.platform = Gem::Platform::RUBY
  spec.summary = "Prawn::Templates allows using PDFs as templates in Prawn"
  spec.files =  Dir.glob("{lib}/**/**/*") + ["prawn-templates.gemspec"]
  spec.require_path = "lib"
  spec.required_ruby_version = '>= 1.9.3'
  spec.required_rubygems_version = ">= 1.3.6"

  spec.authors = ["Gregory Brown", "Brad Ediger", "Daniel Nelson", "Jonathan Greenberg", "James Healy", "Burkhard Vogel"]
  spec.email = ["gregory.t.brown@gmail.com", "brad@bradediger.com", "dnelson@bluejade.com", "greenberg@entryway.net", "jimmy@deefa.com", "b.vogel@buddyandselly.com"]
  spec.add_dependency('pdf-reader', '~>1.3')
  spec.add_dependency('prawn', '>= 2.0.0')
  spec.add_dependency('pdf-core', '>= 0.5.0')
  spec.add_development_dependency('pdf-inspector', '~> 1.2.0')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop', '0.30.1')
  spec.homepage = "https://github.com/prawnpdf/prawn-templates"
  spec.description = "Prawn::Templates allows using PDFs as templates in Prawn"
end
