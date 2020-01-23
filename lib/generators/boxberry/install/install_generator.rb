module Boxberry
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path("../templates", __FILE__)

    def add_files
      template 'boxberry_api.rb', 'config/initializers/boxberry_api.rb'
    end

  end
end
