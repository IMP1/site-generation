require 'toml-rb'
require 'fileutils'

require_relative 'rml'
require_relative 'git_helpers'

class Generator

    def initialize(source_dir, target_dir, source_branch, target_branch)
        @source_path = source_dir
        @target_path = target_dir
        @source_branch = source_branch
        @target_branch = target_branch
        @whitelist = []
        @blacklist = []
    end

    def generate
        Dir.chdir(@source_path) do
            if @source_branch
                Git.checkout(@source_branch) do 
                    process_source_content 
                end
            else
                process_source_content
            end
        end
    end

    def process_source_content
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

    def create_output_content(filename, contents)
        puts "Converting #{filename}"
        Dir.chdir(@target_path) do
            if @target_branch
                commit_message = "Add #{filename}" # TODO: allow for custom message and custom message format
                Git.checkout(@target_branch) do
                    create_output_file(filename, contents)
                    Git.add(@target_path)
                    Git.commit(commit_message)
                end
            else
                create_output_file(filename, contents)
            end
        end
    end

    def create_output_file(filename, contents)
        puts "Creating output file #{filename}"
        dirname = File.dirname(filename)
        unless File.directory?(dirname)
            FileUtils.mkdir_p(dirname)
        end
        File.open(filename, 'w') do |file|
            file.write(contents)
            file.write("\n")
        end
    end

end
