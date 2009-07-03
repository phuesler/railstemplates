modules = [
  ["basic",   "Do basic setup? (only exclude this if you already have a Rails app skeleton with Rails 2.3+ frozen, or as a gem)"],
  ["rspec",   "Use RSpec instead of test/unit?"],
  ["haml",    "Use haml for views and sass for css?"],
  ["jquery",  "Use jQuery instead of Prototype + Script.aculo.us?"],
  ["auth",    "Add authentication module?"],
  ["locale",  "Add specific localizations?"],
  ["misc",    "Add miscellaneous stuff (helpers, basic layout, flashes, initializers)?"],
]

@base_path = if template =~ %r{^(/|\w+://)}
  File.dirname(template)
else
  log '', "You used the app generator with a relative template path."
  ask "Please enter the full path or URL where the modules are located:"
end

modules.each do |modul, question|
    if yes?(question)
      tmpl = "#{@base_path}/#{modul}.rb"
      log "applying", "template: #{tmpl}"
      load_template(tmpl)
      log "applied", tmpl
    end
end
