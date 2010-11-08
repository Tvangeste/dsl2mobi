=== Dsl2Mobi ===

This converter takes a dictionary in Lingvo DSL format and converts
to MOBI dictionary format, suitable for Kindle and Mobipocket Reader.

=== Dependencies ===

1. Ruby 1.8.7 (to run this conversion script):
   http://www.ruby-lang.org/en/downloads/

   For Windows, the following package is recommended:
   http://rubyforge.org/frs/download.php/72085/rubyinstaller-1.8.7-p302.exe

2. Mobipocket creator (to fine-tune the OPF file):
   http://www.mobipocket.com/en/DownloadSoft/DownloadCreator.asp

3. Mobigen or KindleGen (to generate the final MOBI file):
   Mobigen: http://www.mobipocket.com/soft/prcgen/mobigen.zip
   KindleGen: http://www.amazon.com/gp/feature.html?ie=UTF8&docId=1000234621

=== How to use ===

Creation of a Kindle (MOBI) dictionary is a multi-step process.

1. First, we need to convert a DSL dictionary to HTML, and we need to
create so-called OPF file (which is needed by mobigen/kindlegen tools).

In most typical case, just execute:
  
  ruby dsl2mobi.rb -i dictionary.dsl -o result_dir

This will convert the specificed dictionary.dsl file and put the results
into result_dir directory. You'll get the main HTML file, the OPF file,
the CSS style for the HTML, etc.

For all command line switches, just execute:

  ruby dsl2mobi.rb --help

2. Now, open the OPF file in Mobipocket Creator (or modify manually, which is
less convenient). The point of this step is to adjust/correct the metadata
(which is stored in OPF file). Things like cover image, description,
input and output languages (these are important!), etc.

Once you're satisfied with your OPF file, proceed to step 3.

3. In this step the actual MOBI dictionary is being generated. Execute:

    mobigen dictionary.opf

This command will produce the MOBI file that can be used on Kindle
or with Mobipocket Reader. Mobigen is a command line utility that comes
with Mobipocket Creator.

You could also use the following command line switch to produce much
smaller, better compressed MOBI file, but it'll take longer to produce it:

    mobigen -c2 dictionary.opf

Alternatively, kindlegen utility can be used, but it is much, *MUCH*
slower, and seems to be hanging on big dictionaries, so use with care.

=== Notes ===

1. The DSL dictionary *MUST* *BE* in UTF-8 format!!! Typically, the DSL
   dictionaries come in UCS-2 encoding. So, in most cases, the DSL file
   needs to be converted to proper UTF-8 first.

2. It is assumed that the input dictionary is a fully valid DSL dictionary,
   without any errors, duplicates, etc. Essentially, the DSL dictionary
   should be in such a conditian that it could be compiled by Lingvo compiler
   without any errors or warnings.

=== License ===

Dsl2Mobi is a copyrighted free and open source software, that can be
distributed under Ruby or GPL License (see LICENSE.txt).
