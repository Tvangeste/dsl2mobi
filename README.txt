=== Dsl2Mobi ===

This converter takes a dictionary in Lingvo DSL format and converts
to MOBI dictionary format, suitable for Kindle and Mobipocket Reader.

=== How to use ===

In most typical case, just execute:
  
  ruby dsl2mobi -i dictionary.dsl -o result_dir

This will convert the specificed dictionary.dsl file and put the results
into result_dir directory.

For all command line switches, just execute:

  ruby dsl2mobi --help

=== Notes ===

The DSL dictionary *MUST* *BE* in UTF-8 format!!!
