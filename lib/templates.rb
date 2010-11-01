
HTML_HEADER_TEMPLATE = %q{<?xml version="1.0" encoding="utf-8"?>
  <html xmlns:idx="www.mobipocket.com" xmlns:mbp="www.mobipocket.com" xmlns:xlink="http://www.w3.org/1999/xlink">
    <link rel="stylesheet" type="text/css" href="dic.css"/>
    <head>
      <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
      <title><%= title %></title>
    </head>
    <body>
      <center>
        <h1><%= title %></h1>
        <h5><%= subtitle %></h5>
        <hr width="10%" />
          <a onclick="index_search('dic')">Index</a><br />
        <hr />
      </center>
      <mbp:pagebreak />
  
  <!-- DICTIONARY ENTRIES -->
  
}.gsub(/^  /, '')

OPF_TEMPLATE =%q{<?xml version="1.0"?><!DOCTYPE package SYSTEM "oeb1.ent">
  <package unique-identifier="uid" xmlns:dc="Dublin Core">
    <metadata>
      <dc-metadata>
        <dc:Identifier id="uid">dic</dc:Identifier>
        <!-- Title of the document -->
        <dc:Title><%= title %></dc:Title>
        <dc:Language><%= language %></dc:Language>
        <dc:Subject BASICCode="REF008000">Dictionaries</dc:Subject>
        <dc:Creator></dc:Creator>
        <dc:Publisher></dc:Publisher>
        <dc:Identifier scheme="ISBN"></dc:Identifier>
        <dc:Description><%= description %></dc:Description>
      </dc-metadata>
      <x-metadata>
        <output encoding="utf-8" flatten-dynamic-dir="yes"/>
        <DictionaryInLanguage><%= in_lang %></DictionaryInLanguage>
        <DictionaryOutLanguage><%= out_lang %></DictionaryOutLanguage>
        <EmbeddedCover></EmbeddedCover>
        <SRP Currency="USD">0</SRP>
      </x-metadata>
    </metadata>

    <!-- list of all the files needed to produce the .mobi file -->
    <manifest>
      <item id="dictionary0" media-type="text/x-oeb1-document" href="<%= html_file %>"></item>
    </manifest>

    <!-- list of the html files in the correct order  -->
    <spine>
      <itemref idref="dictionary0"/>
    </spine>

    <tours/>
    <guide> <reference type="search" title="Dictionary Search" onclick="index_search()"/> </guide>
  </package>
}.gsub(/^  /, '')
