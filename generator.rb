require 'toml-rb'
require 'fileutils'

require_relative 'rml'
require_relative 'git_helpers'

GENERATOR_IGNORE_FILENAME = ".genignore"

class Generator

    def initialize(source_dir, target_dir, source_branch, target_branch)
        @source_path = source_dir
        @target_path = target_dir
        @source_branch = source_branch
        @target_branch = target_branch
        @ignore_patterns = []
        create_ignore_list
        # TODO, have sync only be set to true if verbose flag is enabled
        $stdout.sync = true 
    end

    def create_ignore_list
        path = File.join(@source_path, GENERATOR_IGNORE_FILENAME)
        if File.exists?(path)
            File.readlines(path).each do |line|
                @ignore_patterns.push(ignore_pattern_to_regex(line.chomp))
            end
        end
    end

    def ignore_pattern_to_regex(pattern)
        pattern = pattern.gsub(".") { "\\." }
        pattern = pattern.gsub("-") { "\\-" }
        pattern = pattern.gsub("?") { "." }
        pattern = pattern.gsub("*") { ".+" }
        regex = /#{pattern}/
        return regex
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
            next if filename == GENERATOR_IGNORE_FILENAME
            if @ignore_patterns.any? { |pattern| pattern.match?(filename) }
                puts "Ignoring #{filename} as it matches a pattern in #{GENERATOR_IGNORE_FILENAME}."
                next
            end
            filepath = File.join(@source_path, filename)
            next if File.directory?(filepath)
            if filename.end_with?(".rml")
                puts "Converting #{filename}"
                rml_content = File.read(filepath)
                content = RMLParser.new(rml_content, filename).parse
            else
                puts "Copying #{filename}"
                File.open(filepath, 'rb') { |f| content = f.read }
            end
            create_output_content(filename, content)
        end
    end

    def create_output_content(source_filename, content)
        Dir.chdir(@target_path) do
            if @target_branch
                commit_message = "Add #{source_filename}" # TODO: allow for custom message and custom message format
                Git.checkout(@target_branch) do
                    create_output_file(source_filename, content)
                    Git.add(@target_path)
                    Git.commit(commit_message)
                end
            else
                create_output_file(source_filename, content)
            end
        end
    end

    def create_output_file(source_filename, content)
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
            File.open(target_filepath, 'w') do |file|
                file.write(content)
                file.write("\n")
            end
        else
            File.open(target_filepath, 'wb') do |file|
                file.write(content)
            end
        end
    end

end
