$KCODE='u'

require 'date'
require 'erb'
require 'fileutils'
require 'optparse'
require 'set'

require File.expand_path('../lib/transliteration', __FILE__)
require File.expand_path('../lib/norm_tags', __FILE__)
require File.expand_path('../lib/templates', __FILE__)

FORMS = {}
CARDS = {}
HWDS = Set.new
cards_list = []

$VERSION = '0.8'
$FAST = false
$FORCE = false
$NORMALIZE_TAGS = true
$TRANSLITERATE = true
$HREF_ARROWS = true
$count = 0
$WORD_FORMS_FILE = nil
$DSL_FILE = nil
$HTML_ONLY = false
$OUT_DIR = "."
$IN = nil

# Need more data for other languages as well
$LANG_MAP = {
  "English" => "en",
  "Russian" => "ru",
  "GermanNewSpelling" => "de",
  "French" => "fr"
}

opts = OptionParser.new

opts.on("-i", "--in DSL_FILE", "convert this DSL file") { |val|
  $DSL_FILE = val
  $stderr.puts "Reading DSL: #{$DSL_FILE}"
}

opts.on("-o", "--out DIR", "convert to directory") { |val|
  $OUT_DIR = val
  $stderr.puts "INFO: Output directory: #{$OUT_DIR}"
  if File.file?($OUT_DIR)
    $stderr.puts "ERROR: Target directory is a file."
    exit
  end
  unless File.exist?($OUT_DIR)
    $stderr.puts "INFO: Output directory doesn't exist, creating..."
    Dir.mkdir($OUT_DIR)
  end
}

opts.on("-w FILE", "--wordforms FILE", "use the word forms from this file") { |val|
  $WORD_FORMS_FILE = val
  $stderr.puts "Using word forms file: #{$WORD_FORMS_FILE}"
}

opts.separator ""
opts.separator "Advanced options:"

opts.on("-l", "--translit true/false", "transliterate Russian headwords (default: true)") { |val|
  $TRANSLITERATE = !!(val =~ /(true|1|on)/i)
}

opts.on("-n", "--normtags true/false", "normalize DSL tags (default: true)") { |val|
  $NORMALIZE_TAGS = !!(val =~ /(true|1|on)/i)
  $stderr.puts "DSL tags normalization: #{$NORMALIZE_TAGS}"
}

opts.on("-a", "--refarrow true/false", "put arrows before links (default: true)") { |val|
  $HREF_ARROWS = !!(val =~ /(true|1|on)/i)
  $stderr.puts "Reference arrows: #{$HREF_ARROWS}"
}

opts.on("-t", "--htmlonly true/false", "produce HTML only (default: false)") { |val|
  $HTML_ONLY = !!(val =~ /(true|1|on)/i)
  $stderr.puts "Generate HTML only: #{$HTML_ONLY}"
}

opts.on("-f", "--force", "overwrite existing files") { |val|
  $FORCE = true
}

opts.on("-s", "--sample", "generate small sample") { |val|
  $FAST = true
}

opts.separator ""
opts.separator "Common options:"

opts.on("-v", "--version", "print version") {
  puts "Dsl2Mobi Converter, ver. #{$VERSION}"
  puts "Copyright (C) 2010 VVSiz"
  exit
}

opts.on("-h", "--help", "print help") {
  puts opts.to_s
  exit
}

opts.separator ""
opts.separator "Example:"
opts.separator "    ruby dsl2mobi.rb -i in.dsl -o result_dir -w forms-EN.txt"
opts.separator "    Converts in.dsl file into result_dir directory, with English wordforms."

rest = opts.parse(*ARGV)
$stderr.puts "WARNING: Some options are not recognized: \"#{rest.join(', ')}\"" unless (rest.empty?)

unless $DSL_FILE
  $stderr.puts "ERROR: Input DSL file is not specified"
  $stderr.puts
  $stderr.puts opts.to_s
  exit
end

$stderr.puts "INFO: Headwords transliteration: #{$TRANSLITERATE}"
$stderr.puts "INFO: DSL Tags normalization: #{$NORMALIZE_TAGS}"
$stderr.puts "INFO: Reference arrows in HTML: #{$HREF_ARROWS}"

$ARROW = ($HREF_ARROWS ? "↑" : "")

class Card
  def initialize(hwd)
    @hwd, @body, @empty = hwd, [], []
    if @hwd =~ /;\s/
      @sub_hwds = hwd.split(/\s*;\s*/)
    else
      @sub_hwds = []
    end
    if @hwd =~ /\{\\\(/
      $stderr.puts "ERROR: Can't handle headwords with brackets: #{@hwd}"
      exit
    end
  end

  def print_out(io)
    if (@body.empty?)
      $stderr.puts "ERROR: Original file contains multiple headwords for the same card: #{@hwd}"
      $stderr.puts "Make sure that there is only one headword for each card no the DSL!"
      exit
    end

    hwd = clean_hwd(@hwd)
    io.puts %Q{<a name="\##{href_hwd(@hwd)}"/>}
    io.puts '<idx:entry name="word" scriptable="yes">'
    io.print %Q{<font size="6" color="#002984"><b><idx:orth>}
    io.puts clean_hwd_to_display(@hwd)

    # inflections (word forms)
    if hwd !~ /[-\.'\s]/
      if (FORMS[hwd]) # got some inflections
        forms = FORMS[hwd].flatten.uniq

        # delete forms that explicitly exist in the dictionary
        forms = forms.delete_if {|form| HWDS.include?(form)}

        if (forms.size > 0)
          io.puts "<idx:infl>"
          forms.each { |form| io.puts %Q{    <idx:iform value="#{form}"/>} }
          io.puts "</idx:infl>"
        end

        # $stderr.puts "HWD: #{hwd} -- #{FORMS[hwd].flatten.uniq.join(', ')}"
      end
    end

    io.puts "</idx:orth></b></font>"

    if ($TRANSLITERATE)
        trans = transliterate(hwd)
        if (trans != hwd)
          io.puts %Q{<idx:orth value="#{trans.gsub(/"/, '')}"/>}
        end
    end

    # handle body
    @body.each { |line|
      indent = 0
      m = line.match(/^\[m(\d+)\]/)
      indent = m[1] if m

      # quote any symbol if there is an \ immedately before
      line.gsub!(/\\(.)/, '+_-_+\1+_-_+')

      # \[ and \] -> something else, without [ and ]
      line.gsub!('+_-_+[+_-_+', '+_-_+LBRACKET+_-_+')
      line.gsub!('+_-_+]+_-_+', '+_-_+RBRACKET+_-_+')

      # delete {{comments}}
      line.gsub!(/\{\{.*?\}\}/, '')

      # <<link>> --> [ref]link[/ref]
      line.gsub!('<<', '[ref]')
      line.gsub!('>>', '[/ref]')

      # < and > --> &lt; and &gt;
      line.gsub!('<', '&lt;')
      line.gsub!('>', '&gt;')

      # \[ and \] --> _{_ and _}_
      line.gsub!('\[', '_{_')
      line.gsub!('\]', '_}_')

      # (\#16) --> (#16). in ASIS.
      line.gsub!('\\#', '#')

      # remove trn tags
      line.gsub!(/\[\/?!?tr[ns]\]/, '')

      # remove lang tags
      line.gsub!(/\[\/?lang[^\]]*\]/, '')

      # remove com tags
      line.gsub!(/\[\/?com\]/, '')

      # remove s tags
      line.gsub!(/\[s\](.*?)\[\/s\]/) do |match|
        file_name = $1

        # handle images
        if file_name =~ /.(jpg|jpeg|bmp|gif|tif|tiff)$/
          # hspace="0" align="absbottom" hisrc=
          # %Q{<img hspace="0" vspace="0" align="middle" src="#{$1}"/>}
          %Q{<img hspace="0" hisrc="#{file_name}"/>}
        elsif file_name =~ /.wav$/
          # just ignore it
        else
          $stderr.puts "WARN: Don't know how to handle media file: #{file_name}"
        end
      end

      # remove t tags
      line.gsub!(/\[t\]/, '<!-- T1 -->')
      line.gsub!(/\[\/?t\]/, '<!-- T2 -->')

      # remove m tags
      line.gsub!(/\[\/?m\d*\]/, '')

      # remove * tags
      line.gsub!('[*]', '')
      line.gsub!('[/*]', '')

      if ($NORMALIZE_TAGS)
        line = Normalizer::norm_tags(line)
      end

      # replace ['] by <u>
      line.gsub!("[']", '<u>')
      line.gsub!("[/']", '</u>')

      # bold
      line.gsub!('[b]', '<b>')
      line.gsub!('[/b]', '</b>')

      # italic
      line.gsub!('[i]', '<i>')
      line.gsub!('[/i]', '</i>')

      # underline
      line.gsub!('[u]', '<u>')
      line.gsub!('[/u]', '</u>')

      line.gsub!('[sup]', '<sup>')
      line.gsub!('[/sup]', '</sup>')

      line.gsub!('[sub]', '<sub>')
      line.gsub!('[/sub]', '</sub>')

      line.gsub!('[ex]', '<span class="dsl_ex">')
      line.gsub!('[/ex]', '</span>')

      # line.gsub!('[ex]', '<ul><ul><li><span class="dsl_ex">')
      # line.gsub!('[/ex]', '</span></li></ul></ul>')

      line.gsub!('[p]', '<span class="dsl_p">')
      line.gsub!('[/p]', '</span>')

      # color translation
      line.gsub!('[c tomato]', '[c   red]')
      line.gsub!('[c slategray]', '[c gray]')

      # ASIS:
      line.gsub!(/\[c   red\](.*?)\[\/c\]/, '[c red]<b>\1</b>[/c]')

      # color
      line.gsub!('[c]', '<font color="green">')
      line.gsub!('[/c]', '</font>')
      line.gsub!(/\[c\s+(\w+)\]/) do |match|
        %Q{<font color="#{$1}">}
      end

      # _{_ --> [
      line.gsub!('_{_', '[')
      line.gsub!('_}_', ']')

      # unquote \[ and \]
      line.gsub!('+_-_+LBRACKET+_-_+', '[')
      line.gsub!('+_-_+RBRACKET+_-_+', ']')

      # unquote any symbol when \ is before it
      line.gsub!('+_-_+', '')

      # handle ref and {{ }} tags (references)
      line.gsub!(/(?:↑\s*)?\[ref(?:\s+dict="(.*?)")?\s*\](.*?)\[\/ref\]/) do |match|
        # $stderr.puts "#{$1} -- #{$2}"
        %Q{#{$ARROW} <a href="\##{href_hwd($2)}">#{$2}</a>}
      end

      io.puts %Q{<div class="dsl_m#{indent}">#{line}</div>}
    }

    # handle end of card
    io.puts "</idx:entry>"
    io.puts %Q{<div>\n  <img hspace="0" vspace="0" align="middle" src="padding.gif"/>}
    io.puts %Q{  <table width="100%" bgcolor="#992211"><tr><th widht="100%" height="2px"></th></tr></table>\n</div>}
  end
  def break_headword
    res = "#{@hwd}\n"
    @sub_hwds.each { |sub_hwd|
      res << "#{sub_hwd} {\\(#{@hwd}\\)}\n"
    }
    res
  end
  def << line
    l = line.strip
    if (l.empty?)
      @empty << line
    else
      @body << line.strip
    end
  end
end

def clean_hwd_global(hwd)
  hwd.gsub('\{', '_<_').gsub('\}', '_>_').
      gsub(/\{.*?\}/, '').
      gsub('_<_', '\{').gsub('_>_', '\}')
end

def clean_hwd_to_display(hwd)
  clean_hwd_global(
    hwd.gsub(/\{\['\]\}(.*?)\{\[\/'\]\}/, '<u>\1</u>') # {[']}txt{[/']} ---> <u>txt</u>
  )
end

def clean_hwd(hwd)
  clean_hwd_global(hwd)
end

def href_hwd(hwd)
  clean_hwd_global(hwd).gsub(/[\s\(\)'"#°!?]+/, '_')
end

def transliterate(hwd)
  Russian::Transliteration.transliterate(hwd)
end

if ($WORD_FORMS_FILE)
  forms_size = 0
  File.open($WORD_FORMS_FILE) do |f|
    f.each do |l|
      l.strip!
      stem, forms = l.split(':')
      stem.strip!
      forms.strip!

      unless FORMS[stem]
        forms_size += 1
        FORMS[stem] = []
      end

      FORMS[stem] << forms.split(/\s*,\s*/)
    end
  end
  $stderr.puts "FORMS SIZE: #{forms_size} -- #{FORMS.size}"
else
  $stderr.puts "INFO: Word forms are not enabled (use --wordforms switch to enable)"
end

# get the full list of headwords in the DSL file,
# as well as title, and in- and out- languages.
first = true
in_header = true
File.open($DSL_FILE) do |f|
  while (line = f.gets)         # read every line
    if (first)
      # strip BOM, if it's there
      if line[0, 3] == "\xEF\xBB\xBF" # UTF-8
        line = line[3, line.size - 3]
      elsif line[0, 2] == "\xFE\xFF"  # UTF-16BE
        $stderr.puts "ERROR: Wrong DSL encoding: UTF-16BE"
        exit(1)
      elsif line[0, 2] == "\xFF\xFE"  # UTF-16LE
        $stderr.puts "ERROR: Currently not supported DSL encoding: UTF-16LE"
        $stderr.puts "INFO: Convert the DSL file into UTF-8 before running this script."
        exit(1)
      end
      first = false
    end
    if line =~ /^#/           # ignore comments
      if in_header            # but first, read the header
          res = line.scan(/^#NAME\s+"(.*)"/i)[0]
          $TITLE = res[0] if res
          res = line.scan(/^#INDEX_LANGUAGE\s+"(\w*)"/i)[0]
          $INDEX_LANGUAGE = res[0] if res
          res = line.scan(/^#CONTENTS_LANGUAGE\s+"(\w*)"/i)[0]
          $CONTENTS_LANGUAGE = res[0] if res
      end
      next
    end
    if (line =~ /^[^\t\s]/)   # is headword?
      in_header = false
      hwd = clean_hwd(line.strip)        # strip \n\r from the end
      HWDS << hwd
    end
  end
end

def get_base_name
  File.basename($DSL_FILE).gsub(/(\..*)*\.dsl$/i, '')
end

$stderr.puts "INFO: Generating only a small sample..." if $FAST

# Calculate where to save the HTML file:
out_file = File.join($OUT_DIR, get_base_name + '.html')
if File.exist?(out_file)
  $stderr.print "WARNING: Output file already exists: \"#{out_file}\". "
  if $FORCE
    $stderr.puts "OVERWRITING!"
  else
    $stderr.puts "Use --force to overwrite."
    exit
  end
end

card = nil
first = true
File.open($DSL_FILE) do |f|

  $stderr.puts "Generating HTML: #{out_file}"
  File.open(out_file, "w+") do |out|

    # print HTML header first
    # TODO: get the info from the DSL file
    title = $TITLE
    subtitle = "Generated by Dsl2Mobi-#{$VERSION}"
    html_header = ERB.new(HTML_HEADER_TEMPLATE, 0, "%<>")
    out.puts html_header.result(binding)

    while (line = f.gets)         # read every line
      if (first)
        # strip UTF-8 BOM, if it's there
        if line[0, 3] == "\xEF\xBB\xBF"
          line = line[3, line.size - 3]
        end
        first = false
      end
      if line =~ /^#/           # ignore comments
        # puts line
        next
      end
      if (line =~ /^[^\t\s]/)   # is headword?
        hwd = line.strip        # strip \n\r from the end
        if (CARDS[hwd])
          $stderr.puts "ERROR: Original file contains diplicates: #{hwd}"
          exit
        end
        card.print_out(out) if card
        $count += 1
        break if ($count == 1000 && $FAST)
        card = Card.new(hwd)
        #CARDS[hwd] = card
        #cards_list << card
      else
        card << line if card
      end
    end

    # don't forget the very latest card!
    card.print_out(out) if card

    # end of HTML
    out.puts "</body>"
    out.puts "</html>"
  end
end

# copy CSS and image files
FileUtils::cp(File.expand_path('../lib/dic.css', __FILE__), $OUT_DIR, :verbose => false )
FileUtils::cp(File.expand_path('../lib/padding.gif', __FILE__), $OUT_DIR, :verbose => false )

# generate OPF file
opf_file = File.join($OUT_DIR, get_base_name + '.opf')
if File.exist?(opf_file)
  $stderr.print "WARNING: Output file already exists: \"#{opf_file}\". "
  if $FORCE
    $stderr.puts "OVERWRITING!"
  else
    $stderr.puts "Use --force to overwrite."
    exit
  end
end

$stderr.puts "Generating OPF: #{opf_file}"
File.open(opf_file, "w+") do |out|
  # TODO: get the title/langue info from DSL file
  title = $TITLE
  # $stderr.puts "INFO: Title: #{$TITLE}"

  in_lang = $LANG_MAP[$INDEX_LANGUAGE]
  unless in_lang
    $stderr.puts "WARN: Don't know this DSL language string: #{$INDEX_LANGUAGE}. Assuming English."
    $stderr.puts "WARN: Please set the proper languages in the OPF file manually!"
    in_lang = "en"
  else
    $stderr.puts "INFO: Index Language: #{$INDEX_LANGUAGE} (#{in_lang})"
  end
  language = in_lang

  out_lang = $LANG_MAP[$CONTENTS_LANGUAGE]
  unless out_lang
    $stderr.puts "WARN: Don't know this DSL language string: #{$CONTENTS_LANGUAGE}. Assuming English."
    $stderr.puts "WARN: Please set the proper languages in the OPF file manually!"
    out_lang = "en"
  else
    $stderr.puts "INFO: Content Language: #{$CONTENTS_LANGUAGE} (#{out_lang})"
  end

  description = "Generated by Dsl2Mobi-#{$VERSION} on #{Date.today.to_s}."
  html_file = File.basename(out_file)
  opf_content = ERB.new(OPF_TEMPLATE, 0, "%<>")
  out.puts opf_content.result(binding)
end
