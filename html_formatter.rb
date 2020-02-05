module HtmlFormatter

    def fix_formatting
        # TODO: there seems to be a problem with lots of tags on one line fucking up
        #       the formatting/indenting.
        string_copy = @string.dup
        opening_tags = []
        void_tags = []
        tag_name = nil
        loop do
            tag_name = string_copy[/<([a-zA-Z][\w\-]*)(?:\s.*)?>.*?<\/\1>/m, 1]
            # TODO: include void tags. 
            # void_tag_name = string_copy[/<([\w\-]+).*?\/?/m, 1]
            # check that void tag name is not the same as the tag name
            # use whichever has the smaller index (whichever is first)
            # and then either add the opening tag OR the void tag.
            break if tag_name.nil?
            i = string_copy.index("<"+tag_name) + tag_name.size
            string_copy = string_copy[i..-1]
            opening_tags.push tag_name
        end
        closing_tags = []

        @string.gsub!(/\n\s*\n?/m, "\n") # remove empty lines

        unfinished_tags = []
        lines = @string.split("\n")
        depth = 0
        lines = lines.map.with_index do |line, line_number|
            padding = " " * (depth * 4)
            loop do
                if opening_tags.size > 0 && line.include?("<#{opening_tags.first}")
                    tag_name = opening_tags.delete_at(0)
                    depth += 1
                    closing_tags.push(tag_name)
                elsif void_tags.size > 0 and line.include?("<#{void_tags.first}")
                    tag_name = void_tags.delete_at(0)
                    puts "THIS SHOULDN'T ACTUALLY HAPPEN YET"
                else
                    break
                end
            end
            loop do
                if closing_tags.size > 0 && line.include?("</#{closing_tags.last}")
                    closing_tags.pop
                    depth -= 1
                    padding = " " * (depth * 4)
                else
                    break
                end
            end
            if line.scan(/<(?!\!)/).count > line.scan(/(?<!\-)>/).count and !tag_name.nil?
                unfinished_tags.push({ :tag => tag_name, :line => line_number })
            end
            padding + line # return the line with its corrected padding
        end
        unfinished_tags.each do |a|
            i = a[:tag].length + 1
            line_number = a[:line] + 1
            loop do
                if lines[line_number].nil?
                    puts line_number
                    puts lines.inspect
                end
                lines[line_number] = (" " * i) + lines[line_number][3..-1]
                break if lines[line_number].include? ">"
                line_number += 1
            end
        end
        @string = lines.join("\n")
    end

end