require 'ostruct'

module PageServer

    @@dir = __dir__

    def self.set_dir(dir)
        @@dir = dir
    end

    def dir
        return @@dir
    end

    def files(folder)
        return Dir[dir + "/" + folder + "/**/*"]
    end

    def posts
        return files("posts").map do |filename|
            post = OpenStruct.new
            post.content = File.read(filename)
            lines = post.content.lines
            post.title = lines.shift.chomp
            post.authors = lines.shift.chomp.split(NoteParser::AUTHOR_SEPARATOR)
            post.dates = lines.shift.chomp.split(NoteParser::DATE_SEPARATOR)
            post.tags = lines.shift.chomp.split(NoteParser::TAG_SEPARATOR)
            post.link = File.basename(filename, ".*") + ".html"
            post
        end
    end

end