require 'fileutils'

require_relative 'git_helpers'
require_relative 'rml'
require_relative 'note'

GENERATOR_IGNORE_FILENAME = ".genignore"
LAST_GENERATION_FILENAME = ".genlast"

class Generator

    def initialize(source_dir, target_dir, source_branch, target_branch, options={})
        @source_path = source_dir
        @target_path = target_dir
        @source_branch = source_branch
        @target_branch = target_branch
        @ignore_patterns = []
        @options = options
        create_ignore_list
        PageServer.set_dir(@source_path)
        # TODO, have sync only be set to true if verbose flag is enabled
        $stdout.sync = true
    end

    def log(message, no_newline=false)
        return if @options[:verbose]
        print message
        print "\n" unless no_newline
    end

    def debug(message, no_newline=false)
        return if @options[:debug]
        print message
        print "\n" unless no_newline
    end

    def error(message)
        puts message
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
                if Git.any_unstaged?
                    error("There are changes in the repo. Generation cancelled.")
                    return
                end
                Git.checkout(@source_branch) do 
                    process_source_content 
                end
            else
                process_source_content
            end
        end
        log("Completed generating site.")
    end

    def process_source_content
        files = Dir["**/*"]
        last_index = File.read(LAST_GENERATION_FILENAME).chomp if File.exists?(LAST_GENERATION_FILENAME)
        if last_index and !last_index.empty?
            files = Git.changed_files(last_index)
        end
        files -= [GENERATOR_IGNORE_FILENAME, LAST_GENERATION_FILENAME]
        if files.empty?
            log("No files to generate.")
            return
        end
        files.reject! do |filename| 
            if @ignore_patterns.any? { |pattern| pattern.match?(filename) }
                debug("Ignoring #{filename} as it matches a pattern in #{GENERATOR_IGNORE_FILENAME}.")
                true
            else
                false
            end
        end
        log("Generating #{files.size} files.")
        file_data = {}
        files.each do |filename|
            filepath = File.join(@source_path, filename)
            next if File.directory?(filepath)
            if filename.end_with?(".rml")
                debug("\rConverting #{filename}", true)
                rml_content = File.read(filepath)
                content = RMLParser.new(rml_content, filename).parse
            elsif filename.end_with?(".note")
                debug("\rConverting #{filename}", true)
                note_content = File.read(filepath)
                content = NoteParser.new(note_content, filename).parse
            else
                debug("\rCopying #{filename}", true)
                File.open(filepath, 'rb') { |f| content = f.read }
            end
            debug("")
            file_data[filename] = content
        end
        Dir.chdir(@target_path) do
            if @target_branch
                Git.checkout(@target_branch) do
                    process_target_content(file_data)
                    Git.add(@target_path)
                    Git.commit("Update generated files",
                               "This commit was generated by an automated generator.", 
                               "See https://github.com/IMP1/site-generation for more details.")
                end
            else
                process_target_content(file_data)
            end
        end
        if @source_branch
            File.open(LAST_GENERATION_FILENAME, 'w') do |file|
                file.write(Git.current_index)
            end
            Git.add(LAST_GENERATION_FILENAME)
            Git.commit("Update last generation index")
        end
    end

    def process_target_content(file_data)
        file_data.each do |filename, content|
            create_output_file(filename, content)
        end
        debug("")
    end

    def create_output_file(source_filename, content)
        target_filename = source_filename
        if source_filename.end_with?(".rml")
            target_filename = source_filename.gsub(/\.rml/, ".html")
        elsif source_filename.end_with?(".note")
            target_filename = source_filename.gsub(/\.note/, ".html")
        end
        target_filepath = File.join(@target_path, target_filename)

        dirname = File.dirname(target_filepath)
        unless File.directory?(dirname)
            FileUtils.mkdir_p(dirname)
        end

        debug("\rCreating output file #{target_filename}", true)
        if source_filename.end_with?(".rml") || source_filename.end_with?(".note")
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
