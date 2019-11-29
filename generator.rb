require 'toml-rb'
require_relative 'rml'

class Settings

    def initialize(path)
        @global_config_settings = TomlRB.load_file(__dir__ + '/config.toml')
        @local_config_settings = {"source" => {"path" => "public"}}
    end

    def get_setting(key_path)
        keys = key_path.split(".")
        table = @local_config_settings
        value = table.dig(*keys)
        if value.nil?
            table = @global_config_settings
            value = value = table.dig(*keys)
        end
        return value
    end

end

class Generator

    def initialize(*args)
        # TODO:
        # What if the source is in a git branch, but the target isn't (or vice versa)?
        # This should be handled gracefully
        @source_root = args.shift || Dir.pwd
        @settings = Settings.new(@source_root)
        @use_git = @settings.get_setting("generation.use_git_branches")
        if @use_git
            @source_branch = @settings.get_setting("source.branch")
            @target_branch = @settings.get_setting("target.branch")
        end
        @source_path = @settings.get_setting("source.path")
        @target_path = @settings.get_setting("target.path")
        @whitelist = @settings.get_setting("generation.whitelist")
        @blacklist = @settings.get_setting("generation.blacklist")
    end

    def git(command, *args)
        return unless @use_git
        `git #{command} #{args.join(" ")}`
    end

    def generate
        current_dir = Dir.pwd
        Dir.chdir(@source_root) do
            if @use_git
                branch = `git branch`
                current_branch = branch.match(/\* (\w+)/)[1]
                git("checkout", @source_branch, "--quiet")
            end
            Dir.chdir(@source_path) do
                Dir["**/*"].each do |filename|
                    # Filter out using whitelist and blacklist
                    if filename.end_with? '.rml'
                        rml_content = File.read(filename)
                        html_content = RMLParser.new(rml_content, filename).parse
                        create_output_content(filename.gsub(".rml", ".html"), html_content)
                    else
                    end
                end
            end
            if @use_git
                git("checkout", current_branch, "--quiet")
            end
        end
    end

    def create_output_content(filename, contents)
        commit_message = "Add #{filename}" # TODO: allow for custom message and custom message format
        Dir.chdir(@source_root) do
            git("checkout", @target_branch, "--quiet")
            Dir.chdir(@target_path) do
                File.open(filename, 'w') do |file|
                    file.write(contents)
                    file.write("\n")
                end
                git("add", ".")
                git("commit", "-m", commit_message, "--quiet")
            end
            git("checkout", @source_branch, "--quiet")
        end
    end

end

g = Generator.new(*ARGV)
g.generate