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
            next if File.directory?(File.join(@source_path, filename))
            create_output_content(filename)
        end
    end

    def create_output_content(source_filename)
        puts "Converting #{source_filename}"
        Dir.chdir(@target_path) do
            if @target_branch
                commit_message = "Add #{source_filename}" # TODO: allow for custom message and custom message format
                Git.checkout(@target_branch) do
                    create_output_file(source_filename)
                    Git.add(@target_path)
                    Git.commit(commit_message)
                end
            else
                create_output_file(source_filename)
            end
        end
    end

    def create_output_file(source_filename)
        target_filename = source_filename
        if source_filename.end_with?(".rml")
            target_filename = source_filename.gsub(".rml", ".html")
        end
        source_filepath = File.join(@source_path, source_filename)
        target_filepath = File.join(@target_path, target_filename)
        dirname = File.dirname(target_filepath)
        unless File.directory?(dirname)
            FileUtils.mkdir_p(dirname)
        end

        puts "Creating output file #{target_filename}"
        if source_filename.end_with? '.rml'
            html_content = ""
            Dir.chdir(@source_path) do
                rml_content = File.read(source_filepath)
                html_content = RMLParser.new(rml_content, source_filename).parse
            end
            
            File.open(target_filepath, 'w') do |file|
                file.write(html_content)
                file.write("\n")
            end
        else
            FileUtils.copy(source_filepath, target_filepath)
        end
    end

end
