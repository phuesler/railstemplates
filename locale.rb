locales = (ENV['LOCALES'] || ask("Which locales do you want to use (separate with commas if more)?")).split(/[,\s]+/)

locales.each do |locale|
  locale += '.yml' unless locale =~ /\.(yml|rb)$/
  file "config/locales/#{locale}",
    open("http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/#{locale}").read
end

def uri_exists?(uri)
  uri = URI.parse(uri)
  Net::HTTP.start(uri.host, uri.port) do |http|
    http.head(uri.request_uri).is_a?(Net::HTTPSuccess)
  end
end

gsub_file "config/environment.rb",
  /(#\s*)?config.i18n.default_locale.*$/,
  "config.i18n.default_locale = '#{locales.first.gsub(/\.(yml|rb)$/, '')}'"

git :add => "."
git :commit => "-a -m 'Added #{locales.join(",")} localizations'"
