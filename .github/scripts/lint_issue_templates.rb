require 'yaml'

paths = IO.popen(['git', 'ls-files', '-z', '--', '.github/ISSUE_TEMPLATE'], &:read).split("\0")
paths.each do |path|
  text = File.read(path)
  if File.extname(path) == '.md'
    front_matter = text.match(/\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)/m)
    abort "#{path}: missing YAML front matter" unless front_matter
    data = YAML.safe_load(front_matter[1])
    unless data.is_a?(Hash) && %w[name about].all? { |key| data[key].is_a?(String) && !data[key].strip.empty? }
      abort "#{path}: name and about must be nonempty strings"
    end
  elsif %w[.yml .yaml].include?(File.extname(path))
    data = YAML.safe_load(text)
    abort "#{path}: expected a YAML mapping" unless data.is_a?(Hash)
    if File.basename(path) == 'config.yml' && data.key?('blank_issues_enabled')
      unless [true, false].include?(data['blank_issues_enabled'])
        abort "#{path}: blank_issues_enabled must be true or false"
      end
    end
  end
  puts "Valid: #{path}"
rescue Psych::Exception => error
  abort "#{path}: #{error.message}"
end
