require_relative 'html_formatter'

class NoteParser
    include HtmlFormatter

    # TODO: Allow for more flexibility. 
    #       Name of ruby block for tags, history, title, main, etc.
    #       Layout file to use.
    #       Whether to even then process via RML parsing.

    LAYOUT_FILENAME = "post_layout.rml"
    AUTHOR_SEPARATOR = ", "
    DATE_SEPARATOR = ", "
    TAG_SEPARATOR = " "
    SECTION_TAGS = %w[img h1 h2 h3 h4 h5 h6 div section p article main header footer]

    def initialize(string, filename="Raw text", preprocess=nil, postprocess=nil)
        @filename = filename
        @meta = {}
        @string = string
        @preprocess = preprocess
        @postprocess = postprocess
    end

    def parse
        extract_meta_info
        preprocess
        generate_html
        postprocess
        add_to_layout
        fix_formatting
        return @string
    end

    def preprocess
        return if @preprocess.nil?
        @string = @preprocess.call(@string)
    end

    def postprocess
        return if @postprocess.nil?
        @string = @postprocess.call(@string)
    end

    def extract_meta_info
        lines = @string.lines
        @meta[:title] = lines.shift.chomp
        @meta[:authors] = lines.shift.chomp.split(AUTHOR_SEPARATOR)
        @meta[:dates] = lines.shift.chomp.split(DATE_SEPARATOR)
        @meta[:tags] = lines.shift.chomp.split(TAG_SEPARATOR)
        @string = lines.join
    end

    def add_to_layout
        if LAYOUT_FILENAME.end_with?(".rml")
            add_to_rml_layout
        end
    end

    def add_to_rml_layout
        tags_content = @meta[:tags].map { |tag| "<li>#{tag}</li>" }.join("\n")
        history = @meta[:dates].zip(@meta[:authors].cycle)
         
        begin
            date, author = *history.shift
            history_content = "<dt>Created</dt>\n<dd>\nOn #{date} by #{author}\n</dd>\n"
        end
        history_content += history.map { |date, author| "<dt>Updated</dt>\n<dd>\nOn #{date} by #{author}\n</dd>\n" }.join("\n")

        rml_tags    = "<ruby block-begin=\"tags\">\n"    + tags_content    + "\n<ruby block-end=\"tags\">\n"
        rml_history = "<ruby block-begin=\"history\">\n" + history_content + "\n<ruby block-end=\"history\">\n"
        rml_main    = "<ruby block-begin=\"main\">\n"    + @string         + "\n<ruby block-end=\"main\">\n"
        rml_content = "<ruby include=\"#{LAYOUT_FILENAME}\">\n#{rml_tags}\n#{rml_history}\n#{rml_main}\n"
        rml_parser = RMLParser.new(rml_content, @filename)
        @string = rml_parser.parse
    end

    def generate_html
        # Parse Images
        @string.gsub!(/\[(.+?)\]\(!(.+?)\)/) { |m| "<img src=\"#{$2}\" alt=\"#{$1}\" title=\"#{$1}\">" }
        @string.gsub!(/\(!(.+?)\)/) { "<img src=\"#{$1}\">" }
        # Parse links
        @string.gsub!(/\[(.+?)\]\((.+?)\)/) { "<a href=\"#{$2}\">#{$1}</a>" }
        # Parse headings
        @string.gsub!(/^###### (.+?)\s*$/) { "<h6>#{$1}</h6>\n" }
        @string.gsub!(/^##### (.+?)\s*$/) { "<h5>#{$1}</h5>\n" }
        @string.gsub!(/^#### (.+?)\s*$/) { "<h4>#{$1}</h4>\n" }
        @string.gsub!(/^### (.+?)\s*$/) { "<h3>#{$1}</h3>\n" }
        @string.gsub!(/^## (.+?)\s*$/) { "<h2>#{$1}</h2>\n" }
        @string.gsub!(/^# (.+?)\s*$/) { "<h1>#{$1}</h1>\n" }
        # Parse paragraphs
        paras = @string.split(/\n\s*\n/)
        paras.map! do |text| 
            # Leave alone any blocks starting with certain tags (img, h1, div)
            if SECTION_TAGS.any? { |tag| text.lstrip.start_with?("<#{tag}") }
                text
            else
                "\n<p>\n#{text}\n</p>\n" 
            end
        end
        @string = paras.join("\n")
        # Parse lists
    end

end
