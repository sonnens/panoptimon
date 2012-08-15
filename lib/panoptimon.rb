require "panoptimon/version"

module Panoptimon

  class Panoptimon
  end

def self.load_options (args)
  defaults = {
    :daemonize      => true,
    :config_dir     => '/etc/panoptimon/',
    :config_file    => '/etc/panoptimon/panoptimon.json',
    :collectors_dir => '%/collectors',
    :plugins_dir    => '%/plugins',
    :collector_timeout  => 120,
    :collector_interval => 60,
  }

  options = ->() {
    o = {}
    OptionParser.new do |opts|

      opts.on('-c', '--config-file [FILENAME]',
        "Alternative configuration file (#{defaults[:config_file]})"
      ) { |v| o[:config_file] = v }

      opts.on('-D', '--[no-]foreground',
        "Don't daemonize (#{not defaults[:daemonize]})"
      ) { |v| o[:daemonize] = ! v }

      ['config', 'collectors', 'plugins'].each { |x|
        k = "#{x}_dir".to_sym
        opts.on("--#{x}-dir [DIR]",
          "#{x.capitalize} directory (#{defaults[k]})"
        ) { |v| o[k] = v }
      }

      [:collectors, :plugins, :roles].each { |x|
        opts.on('--list-'+x.to_s, "list all #{x} found"
        ) { (o[:lists] ||= []).push(x) }
      }

      opts.on('-o', '--configure [X=Y]',
        'Set configuration values'
      ) { |x|
        (k,v) = x.split(/=/, 2)
        (o[:configure] ||= {})[k.to_sym] = v
      }

      opts.on('-l', '--location [LOC]', "Set node location"
        # TODO this feature might be implemented as a plugin
      ) { raise "--location unimplemented" }

      opts.on('-d', '--debug', "Enable debugging."
      ) { |v| o[:debug] = v }

      opts.on('--verbose', "Enable verbose output"
      ) { |v| o[:verbose] = v }

      opts.separator ""
      opts.separator "Common options:"

      opts.on_tail('-v', '--version', "Print version"
      ) { 
        puts "panoptimon version #{Panoptimon::VERSION}"
        o[:quit] = true
        opts.terminate
      }

      opts.on_tail("-h", "--help", "Show this message"
      ) {
        puts opts
        o[:quit] = true
        opts.terminate
      }

    end.parse!(args)

    return o
  }.call

  return false if options[:quit]

  config = defaults.merge(
    options[:config_file].to_s == '' ? {} : JSON.parse(
      File.read(options[:config_file] || defaults[:config_file]),
      {:symbolize_names => true}
    )
  ).merge(options);

  (config.delete(:configure) || {}).each { | k,v| config[k] = v }

  # these can be relative to config_dir
  [:collectors_dir, :plugins_dir].each { |d|
    config[d] = File.join(config[:config_dir], config[d]) \
      if config[d].sub!(/^%\//, '')
  }

  return OpenStruct.new(config).freeze

end

end

# vim:ts=2:sw=2:et:sta
