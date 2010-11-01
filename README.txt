=== Dsl2Mobi ===

This converter takes a dictionary in Lingvo DSL format and converts
to MOBI dictionary format, suitable for Kindle and Mobipocket Reader.

=== Dependencies ===

1. Ruby 1.8.7:
   http://www.ruby-lang.org/en/downloads/

   For Windows, the following package is recommended:
   http://rubyforge.org/frs/download.php/72085/rubyinstaller-1.8.7-p302.exe

2. Mobipocket creator:
   http://www.mobipocket.com/en/DownloadSoft/DownloadCreator.asp

=== How to use ===

In most typical case, just execute:
  
  ruby dsl2mobi -i dictionary.dsl -o result_dir

This will convert the specificed dictionary.dsl file and put the results
into result_dir directory. Then, execute:

    mobigen dictionary.opf

This command will produce the actual MOBI file that can be used on Kindle
or with Mobipocket Reader. Mobigen is a command line utility that comes
with Mobipocket Creator.

Alternatively, kindlegen utility can be used, but it is much, *MUCH*
slower, and seems to be hanging on big dictionaries, so use with care.

For all command line switches, just execute:

  ruby dsl2mobi --help

=== Notes ===

The DSL dictionary *MUST* *BE* in UTF-8 format!!!
