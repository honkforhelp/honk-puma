Gem::Specification.new do |spec|
  spec.name        = "honk-puma"
  spec.version     = "0.1.0"
  spec.summary     = "A to run Puma the same everywhere."
  spec.description = <<-TEXT
This runs Puma web server with a status logging agent process in a consistent fashion, suitable
for deployment on the Heroku platform.
  TEXT

  spec.authors     = ["HONK Technologies, Inc."]
  spec.email       = "blake@honkforhelp.com"
  spec.homepage    = "https://github.com/honkforhelp/honk-puma"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.6.0"

  spec.add_runtime_dependency 'wannabe_bool'
  spec.add_runtime_dependency 'puma', '~> 5.6', '<= 6'
  spec.add_runtime_dependency 'puma-status'

  spec.files        = Dir["lib/{**/*}.rb", '{config,bin}/*', 'LICENCE', '*.md']
  spec.require_path = 'lib'
  spec.executables  = ['honk-puma']
end
