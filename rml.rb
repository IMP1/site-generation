require_relative 'html_elements'
require_relative 'page_server'
require_relative 'html_formatter'

class RMLParser
    include HtmlElementGenerator
    include PageServer
    include HtmlFormatter

    SEPARATOR = " "

    def initialize(string, filename="Raw text")
        @filename = filename
        @string = string
    end

    def parse(variables=nil)
        @variables = variables || {}
        add_included_files
        handle_blocks
        eval_ruby
        fix_formatting
        return @string
    end

    def add_included_files
        @string.scan(/<ruby include=.+?>/).each do |m|
            filename = m[/include="(.+?)"/, 1]
            args = m[/args="(.+?)"/, 1]
            unless File.file?(filename)
                raise "Could not find file to include: '#{filename}'. Working directory is #{Dir.pwd}"
            end
            include_string = File.read(filename)
            if include_string.nil?

            else
                if !args.nil?
                    args.split("&").each do |pair| 
                        key, value = *pair.split("=")
                        include_string.gsub!(/\#\{#{key}\}/, value)
                    end
                end
                import = RMLParser.new(include_string, filename)
                # TODO: do any imported files need more processing?
                @string.sub!(m, import.add_included_files)
            end
        end
        return @string
    end

    def handle_blocks
        blocks = {}

        # Find all blocks and store their contents in `blocks`
        @string.scan(/<ruby block\-begin=".+?">/m).each do |m|
            block_name = m[19..-3]
            blocks[block_name] ||= []
            block_start_index = (0..blocks[block_name].size).inject(-1) { |memo, i| @string.index(m, memo + 1) }
            block_end_index = @string.index(/<ruby block\-end="#{block_name}">/m, block_start_index)
            if block_end_index.nil?
                raise "Could not find and end tag for ruby block `#{block_name}`."
            end
            block_inner = @string[block_start_index+m.size...block_end_index]
            blocks[block_name].push(block_inner)
        end

        # Resolve any block-super calls
        blocks.each do |block_name, block_levels|
            block_levels.each_with_index do |block, i|
                block_levels[i].gsub!(/<ruby block\-super>/, block_levels[i-1])
            end
        end

        # Replace first instance of block with final evaluation of the block content
        blocks.keys.each do |block_name|
            @string.sub!(/<ruby block\-begin="#{block_name}">.+?<ruby block\-end="#{block_name}">/m, blocks[block_name].last)
        end

        # Remove all remaining blocks
        @string.gsub!(/<ruby block\-begin="(.+?)">.+?<ruby block\-end="\1">/m, "")
        return @string
    end

    def eval_ruby
        @view_bag = @variables
        @view_bag['nav'] ||= []
        alias puts_inspect p  # Save p in a local method
        define_singleton_method("p"){ |arg| @current_output.push(arg) }
        @string.scan(/<ruby>.+?<\/ruby>/m).each do |m|
            @current_output = []
            code = m[6..-8]
            binding.eval(code)    
            @string = @string.sub(m, @current_output.join(SEPARATOR))
        end
        alias p puts_inspect  # Restore p
        return @string
    end

end
