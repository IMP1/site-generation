module HtmlElementGenerator

    def self.define_element(element)
        element_name = element.to_s.downcase
        block = lambda do |contents, properties={}|
            contents = [contents] if contents.is_a?(String)

            attrs = properties.to_a.map { |key, value| "#{key.to_s}=\"#{value}\"" }

            open_tag = "<#{[element_name, *attrs].join(" ")}>"
            open_tag += "\n" if contents.first.start_with?("<")
            close_tag = ""
            close_tag += "\n" if contents.first.start_with?("<")
            close_tag += "</#{element_name}>\n"

            return open_tag + contents.join(" ") + close_tag
        end
        define_method(element, &block)
    end

    def self.define_void_element(element)
        element_name = element.to_s.downcase
        block = lambda do |properties={}|
            attrs = properties.to_a.map { |key, value| "#{key.to_s}=\"#{value}\"" }

            tag = "<#{[element_name, *attrs].join(" ")}>\n"

            return tag
        end
        define_method(element, &block)
    end

    %i[
        HTML HEAD BODY
        ARTICLE SECTION DIV SPAN HEADER FOOTER MAIN ASIDE NAV
        H1 H2 H3 H4 H5 H6 EM STRONG S SUP SUB MARK I B
        INS DEL KBD SAMP CODE BLOCKQUOTE DFN ABBR PRE ADDRESS
        OUTPUT TIME
        OL UL LI DL DT DD TABLE TBODY TFOOT THEAD TR TD TH
        FORM BUTTON A TEXTAREA SELECT OPTION OPTGROUP
        VIDEO CANVAS OBJECT IFRAME AUDIO SCRIPT
        PROGRESS MENU MAP VAR 
        DETAILS SUMMARY FIGURE FIGCAPTION CAPTION CITE LABEL
    ].each do |elem|
        define_element(elem)
    end

    %i[
        AREA BASE BR WBR COL COMMAND EMBED HR IMG INPUT 
        KEYGEN LINK META PARAM SOURCE TRACK
    ].each do |elem|
        define_void_element(elem)
    end

end
