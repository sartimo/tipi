require 'cgi'
require 'uri'

module Tipi
  class Parser
    attr_accessor :allowed_schemes
    attr_writer :extensions
    def extensions?; @extensions; end
    attr_writer :no_escape
    def no_escape?; @no_escape; end

    def initialize(text, options = {})
      @allowed_schemes = %w(http https ftp ftps)
      @text            = text
      @extensions = @no_escape = nil
      options.each_pair {|k,v| send("#{k}=", v) }
    end

    def to_html
      @out = ''
      @p = false
      @stack = []
      parse_block(@text)
      @out
    end

    protected

    def escape_html(string)
      CGI::escapeHTML(string)
    end

    def escape_url(string)
      CGI::escape(string)
    end

    def start_tag(tag)
      @stack.push(tag)
      @out << '<' << tag << '>'
    end

    def end_tag
      @out << '</' << @stack.pop << '>'
    end

    def toggle_tag(tag, match)
      if @stack.include?(tag)
        if @stack.last == tag
          end_tag
        else
          @out << escape_html(match)
        end
      else
        start_tag(tag)
      end
    end

    def end_paragraph
      end_tag while !@stack.empty?
      @p = false
    end

    def start_paragraph
      if @p
        @out << ' ' if @out[-1] != ?\s
      else
        end_paragraph
        start_tag('p')
        @p = true
      end
    end

    def make_local_link(link) #:doc:
      no_escape? ? link : escape_url(link)
    end

    def make_direct_link(url) #:doc:
      url
    end

    def make_image_link(url) #:doc:
      url
    end

    def make_image(uri, alt)
      if alt
        '<img src="' << escape_html(uri) << '" alt="' << escape_html(alt) << '"/>'
      else
        '<img src="' << escape_html(uri) << '"/>'
      end
    end

    def make_headline(level, text)
      "<h#{level}>" << escape_html(text) << "</h#{level}>"
    end

    def make_explicit_link(link)
      begin
        uri = URI.parse(link)
        return uri.to_s if uri.scheme && @allowed_schemes.include?(uri.scheme)
      rescue URI::InvalidURIError
      end
      make_local_link(link)
    end

    def parse_inline(str)
      until str.empty?
        case str
        when /\A(\~)?((https?|ftps?):\/\/\S+?)(?=([\,.?!:;"'\)]+)?(\s|$))/
          str = $'
          if $1
            @out << escape_html($2)
          else
            if uri = make_direct_link($2)
              @out << '<a href="' << escape_html(uri) << '">' << escape_html($2) << '</a>'
            else
              @out << escape_html($&)
            end
          end
        when /\A\[\[\s*([^|]*?)\s*(\|\s*(.*?))?\s*\]\]/m
          str = $'
          link, content = $1, $3
          if uri = make_explicit_link(link)
            @out << '<a href="' << escape_html(uri) << '">'
            if content
              until content.empty?
                content = parse_inline_tag(content)
              end
            else
              @out << escape_html(link)
            end
            @out << '</a>'
          else
            @out << escape_html($&)
          end
        else
          str = parse_inline_tag(str)
        end
      end
    end

    def parse_inline_tag(str)
      case str
      when /\A\{\{\{(.*?\}*)\}\}\}/
        @out << '<tt>' << escape_html($1) << '</tt>'
      when /\A\{\{\s*(.*?)\s*(\|\s*(.*?)\s*)?\}\}/
        if uri = make_image_link($1)
          @out << make_image(uri, $3)
        else
          @out << escape_html($&)
        end
      when /\A([[:alpha:]]|[[:digit:]])+/
        @out << $&
      when /\A\s+/
        @out << ' ' if @out[-1] != ?\s
      when /\A\*\*/
        toggle_tag 'strong', $&
      when /\A\/\//
        toggle_tag 'em', $&
      when /\A\\\\/
        @out << '<br/>'
      else
        if @extensions
          case str
          when /\A__/
            toggle_tag 'u', $&
          when /\A\-\-/
            toggle_tag 'del', $&
          when /\A\+\+/
            toggle_tag 'ins', $&
          when /\A\^\^/
            toggle_tag 'sup', $&
          when /\A\~\~/
            toggle_tag 'sub', $&
          when /\A\(R\)/i
            @out << '&#174;'
          when /\A\(C\)/i
            @out << '&#169;'
          when /\A~([^\s])/
            @out << escape_html($1)
          when /./
            @out << escape_html($&)
          end
        else
          case str
          when /\A~([^\s])/
            @out << escape_html($1)
          when /./
            @out << escape_html($&)
          end
        end
      end
      return $'
    end

    def parse_table_row(str)
      @out << '<tr>'
      str.scan(/\s*\|(=)?\s*((\[\[.*?\]\]|\{\{.*?\}\}|[^|~]|~.)*)(?=\||$)/) do
        if !$2.empty? || !$'.empty?
          @out << ($1 ? '<th>' : '<td>')
          parse_inline($2) if $2
          end_tag while @stack.last != 'table'
          @out << ($1 ? '</th>' : '</td>')
        end
      end
      @out << '</tr>'
    end

    def make_nowikiblock(input)
      input.gsub(/^ (?=\}\}\})/, '')
    end

    def ulol?(x); x == 'ul' || x == 'ol'; end

    def parse_block(str)
      until str.empty?
        case str
        when /\A\{\{\{\r?\n(.*?)\r?\n\}\}\}/m
          end_paragraph
          nowikiblock = make_nowikiblock($1)
          @out << '<pre>' << escape_html(nowikiblock) << '</pre>'
        when /\A\s*-{4,}\s*$/
          end_paragraph
          @out << '<hr/>'
        when /\A\s*(={1,6})\s*(.*?)\s*=*\s*$(\r?\n)?/
          end_paragraph
          level = $1.size
          @out << make_headline(level, $2)
        when /\A[ \t]*\|.*$(\r?\n)?/
          if !@stack.include?('table')
            end_paragraph
            start_tag('table')
          end
          parse_table_row($&)
        when /\A\s*$(\r?\n)?/
          end_paragraph
        when /\A(\s*([*#]+)\s*(.*?))$(\r?\n)?/
          line, bullet, item = $1, $2, $3
          tag = (bullet[0,1] == '*' ? 'ul' : 'ol')
          if bullet[0,1] == '#' || bullet.size != 2 || @stack.find {|x| ulol?(x) }
            count = @stack.select { |x| ulol?(x) }.size

            while !@stack.empty? && count > bullet.size
              count -= 1 if ulol?(@stack.last)
              end_tag
            end

            end_tag while !@stack.empty? && @stack.last != 'li'

            if @stack.last == 'li' && count == bullet.size
              end_tag
              if @stack.last != tag
                end_tag
                count -= 1
              end
            end

            while count < bullet.size
              start_tag tag
              count += 1
              start_tag 'li' if count < bullet.size
            end

            @p = true
            start_tag('li')
            parse_inline(item)
          else
            start_paragraph
            parse_inline(line)
          end
        when /\A([ \t]*\S+.*?)$(\r?\n)?/
          start_paragraph
          parse_inline($1)
        else
          raise "Parse error at #{str[0,30].inspect}"
        end
        #p [$&, $']
        str = $'
      end
      end_paragraph
      @out
    end
  end
end
