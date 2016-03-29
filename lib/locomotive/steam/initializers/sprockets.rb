require 'sprockets'
require 'sass'
require 'coffee_script'
require 'compass'
require 'autoprefixer-rails'

require 'execjs'

# Force ExecJS to select the best engine based on the current configuration.
# It means that if, down the road, we load a different javascript engine,
# the ExecJS runtime won't be affected.
ExecJS.runtime

module Locomotive::Steam

  class SprocketsEnvironment < ::Sprockets::Environment

    def initialize(root, options = {})
      super(root)

      @steam_path = root

      append_steam_paths

      install_yui_compressor(options)

      install_autoprefixer
    end

    private

    def append_steam_paths
      %w(fonts stylesheets javascripts).each do |name|
        append_path File.join(@steam_path, name)
      end

      Compass::Frameworks::ALL.each { |f| append_path(f.stylesheets_directory) }
    end

    def install_yui_compressor(options)
      return unless options[:minify]

      require 'yui/compressor'

      if is_java_installed?
        # minify javascripts and stylesheets
        self.js_compressor  = YUI::JavaScriptCompressor.new
        self.css_compressor = YUI::CssCompressor.new
      else
        message = "[Important] YUICompressor requires java to be installed. The JAVA_HOME variable should also be set.\n"
        Locomotive::Common::Logger.warn message.red
        false
      end
    end

    def install_autoprefixer
      file = File.join(root, '..', 'config', 'autoprefixer.yml')

      if File.exists?(file)
        params = (::YAML.load_file(file) || {}).symbolize_keys
        AutoprefixerRails.install(self, params)

        Locomotive::Common::Logger.info "[Autoprefixer] detected and installed".light_white

        if ENV['EXECJS_RUNTIME'].blank?
          Locomotive::Common::Logger.warn "[Autoprefixer]".light_white + " [Warning] if you notice bad performance, install NodeJS and run \"export EXECJS_RUNTIME=Node\" in your shell"
        end

        Locomotive::Common::Logger.info "\n"
      end
    end

    def is_java_installed?
      `which java` != '' && (!ENV['JAVA_HOME'].blank? && File.exists?(ENV['JAVA_HOME']))
    end

  end

end
