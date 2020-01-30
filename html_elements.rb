module HtmlElementGenerator

    def self.define_element(element)
        element_name = element.to_s.downcase
        block = lambda do |contents, properties={}|

            if contents.is_a?(String)
                contents = [contents]
            end

            attrs = properties.to_a.map { |key, value| "#{key.to_s}=\"#{value}\"" }

            open_tag = "<#{[element_name, *attrs].join(" ")}>\n"
            close_tag = "\n</#{element_name}>"

            return open_tag + contents.join("\n") + close_tag
        end
        define_method(element, &block)
    end

    def self.define_void_element(element)
        element_name = element.to_s.downcase
        block = lambda do |properties={}|

            attrs = properties.to_a.map { |key, value| "#{key.to_s}=\"#{value}\"" }

            tag = "<#{[element_name, *attrs].join(" ")}>"
            
            return tag

        end
        define_method(element, block)
    end

    [*"H1".."H6", *%w[ARTICLE SECTION DIV A P UL OL LI DL DT DD STRONG EM]].each do |elem|
        define_element(elem.to_sym)
    end

    ["IMG", "BR", "META"].each do |elem|
        define_void_element(elem.to_sym)
    end

end
