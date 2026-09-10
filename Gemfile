source "https://rubygems.org"

gem "fastlane", "2.235.0"

# representable/json.rb가 런타임에 require하지만 어느 gemspec에도 선언되지 않은
# soft dependency다. 없으면 fastlane 로딩 단계에서 Gem::LoadError로 실패한다.
gem "multi_json"
