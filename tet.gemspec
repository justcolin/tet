Gem::Specification.new do |s|
  s.name     = 'tet'
  s.version  = '1.3.1'

  s.summary     = "Barely a test framework"
  s.homepage    = 'https://github.com/justcolin/tet'
  s.description = "A very minimal test framework designed for simple projects. A couple of features, relatively nice looking output, and nothing else. Does the world need another test framework? No. Is Tet the product of boredom and yak shaving? Yes."

  s.authors = ['Colin Fulton']
  s.email   = 'justcolin@gmail.com'
  s.license = 'BSD-3-Clause'

  s.files                 = ['lib/tet.rb', 'lib/tests.rb']
  s.required_ruby_version = '>= 2.1.3'
end
