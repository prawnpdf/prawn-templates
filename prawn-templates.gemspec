# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'prawn-templates'
  spec.version = File.read(File.expand_path('VERSION', File.dirname(__FILE__)))
    .strip
  spec.platform = Gem::Platform::RUBY
  spec.summary = 'Prawn::Templates allows using PDFs as templates in Prawn'
  spec.files = Dir.glob('{lib}/**/**/*') + [
    'prawn-templates.gemspec', 'COPYING', 'LICENSE', 'GPLv2', 'GPLv3'
  ]
  spec.require_path = 'lib'
  spec.required_ruby_version = '>= 2.6'
  spec.required_rubygems_version = '>= 2.0.0'
  spec.licenses = %w[Nonstandard GPL-2.0 GPL-3.0]

  spec.authors = [
    'Gregory Brown', 'Brad Ediger', 'Daniel Nelson', 'Jonathan Greenberg',
    'James Healy', 'Burkhard Vogel-Kreykenbohm'
  ]
  spec.email = [
    'gregory.t.brown@gmail.com', 'brad@bradediger.com', 'dnelson@bluejade.com',
    'greenberg@entryway.net', 'jimmy@deefa.com', 'b.vogel@buddyandselly.com'
  ]
  spec.add_dependency('pdf-reader', '~> 2.0', '!= 2.9.0', '!= 2.9.1')
  spec.add_dependency('prawn', '~> 2.2')
  spec.add_development_dependency('pdf-inspector', '~> 1.3')
  spec.add_development_dependency('prawn-dev', '~> 0.3.0')
  spec.homepage = 'https://github.com/prawnpdf/prawn-templates'
  spec.description = 'A extension to prawn that allows to include other pdfs '\
    'either as background to write upon or to combine several pdf documents '\
    'into one.'
end
