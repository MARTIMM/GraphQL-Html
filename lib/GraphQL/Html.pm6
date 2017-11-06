use v6;
use GraphQL;
use JSON::Fast;
use OpenSSL::Digest;
use HTTP::UserAgent;
use HTML::Parser::XML;
use XML;
use XML::XPath;

#------------------------------------------------------------------------------
# introduce the query class and variable classes here
class GraphQL::Html::QC { ... }
class GraphQL::Html::QC::Image { ... }

#------------------------------------------------------------------------------
# this class is a singleton class and is called from the query and its
# variables to download html pages and
class GraphQL::Html:auth<github:MARTIMM> {

  has GraphQL::Schema $!schema-object;

  # $!uri holds current website page. $!current-page-name is the sha1 code
  # of the uri and is used as key in the hash $!queries and $!xpath.
  has Str $!uri;
  has Str $!current-page-name;

  # in memory cache of sha1 keys pointing to query parsed documents
  has Hash $!queries;

  # in memory cache of xpath document of loaded page. its value is an array of
  # 2 elements. one for a ref count and one for the xpath object
  has Hash $!xpath;

  # path where config and cache is stored
  has Str $!rootdir;

  # singleton object
  my GraphQL::Html $gh-obj;

  #----------------------------------------------------------------------------
  #| singleton class, use instance to initialize or to get object
  submethod new ( ) { !!! }

  #----------------------------------------------------------------------------
  # can only initialize once with rootdir
  method instance ( Str :$rootdir ) {

    unless $gh-obj.defined {
      $gh-obj = self.bless(:$rootdir);
      $gh-obj.set-schema(
        GraphQL::Html::QC,
        GraphQL::Html::QC::Image,
        :query-class(GraphQL::Html::QC.^name)
      );
    }

    $gh-obj
  }

  #----------------------------------------------------------------------------
  submethod BUILD ( Str :$!rootdir ) {

    $!rootdir //= "$*HOME/.graphql-html";
    mkdir( $!rootdir, 0o750) unless $!rootdir.IO.d;
    mkdir( "$!rootdir/cache", 0o750) unless "$!rootdir/cache".IO.d;

    $!queries = {};
    $!xpath = {};
  }

  #----------------------------------------------------------------------------
  method load-page ( --> Str ) {

    return 'empty uri' unless $!uri;
#note "Load page: $!uri";

    my Str $status;

    my Str $xml;
    $!current-page-name = self.sha1($!uri);
    my Str $page-path = "$!rootdir/cache/$!current-page-name";

    if $!xpath{$!current-page-name}:exists {
      $status = 'page from memory cache';
    }

    else {
      if $page-path.IO ~~ :r {
        $status = 'read from cache';
#TODO Check date to refresh page
        $xml = $page-path.IO.slurp;
      }

      else {
        $status = 'page downloaded';

        my HTTP::UserAgent $ua .= new;
        $ua.timeout = 10;
        my $r = $ua.get($!uri);
        die "Download not successful" unless $r.is-success;
        $xml = $r.content;
        $page-path.IO.spurt($xml);
      }

      my HTML::Parser::XML $parser .= new;
      $parser.parse($xml);
      my $document = $parser.xmldoc;
      self!set-xpath(XML::XPath.new(:$document));
    }

#note "Sts: $status";
    $status
  }

  #----------------------------------------------------------------------------
  method sha1 ( Str:D $txt --> Str ) {

    sha1($txt.encode)>>.fmt('%02x').join;
  }

  #----------------------------------------------------------------------------
  multi method set-schema ( Str:D $schema!, Any:D :$resolvers! ) {

    $!schema-object .= new( $schema, :$resolvers);
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method set-schema ( *@types, :$query-class ) {

    $!schema-object .= new( @types, :query($query-class));
  }

  #----------------------------------------------------------------------------
  method get-xpath ( --> XML::XPath ) {

    if $!xpath{$!current-page-name}:exists {
      $!xpath{$!current-page-name}[0]++;
      $!xpath{$!current-page-name}[1]
    }

    else {
      XML::XPath
    }
  }

  #----------------------------------------------------------------------------
  method !set-xpath ( XML::XPath:D $xpath ) {

#note "set xpath $!xpath.elems(), $!current-page-name, $xpath";
    # check if cache is not growing too big. if so, remove least used one
    # checks done in load-page() ensures that $!current-page-name is
    # not stored yet
    if $!xpath.elems > 10 {
      my Int $min-ref = Inf;
      my Str $min-ref-key;
      for $!xpath.kv -> $k, $v {
        if $min-ref > $v[0] {
          $min-ref-key = $k;
          $min-ref = $v[0];
        }
      }

      $!xpath{$min-ref-key}:delete;
    }

    # store xpath object and referenced once
    $!xpath{$!current-page-name} = [ 1, $xpath];
#note "Cache xpath $!current-page-name, $!xpath{$!current-page-name}";
  }

  #----------------------------------------------------------------------------
  method q ( Str $query, Bool :$json = False, :%variables = %(), --> Any ) {

    my $result;

    # create a key to store queries
    my Str $sha1 = self.sha1($query);

    # store query as a schema document if new
    $!queries{$sha1} = $!schema-object.document($query)
      unless $!queries{$sha1}:exists;

    # get the document
    my GraphQL::Document $doc = $!queries{$sha1};

    # execute the query with any variables
    with $!schema-object.execute( :document($doc), :%variables) {
      if $json {
        $result = .to-json;
      }

      else {
        my Str $json = .to-json;
#note "JSon: ", $json;
        $json ~~ s:g/\n/ /;
        $json ~~ s:g/\\ <?before <-[\\]>>/\\\\/;
        $result = from-json($json);
      }
    }

    $result;
  }

  #----------------------------------------------------------------------------
  # Following methods can be used from query and its variables
  #----------------------------------------------------------------------------
  method uri ( Str:D :$!uri --> Str ) {

    self.load-page;
  }

  #----------------------------------------------------------------------------
  method title ( --> Str ) {

    my $xpath = self.get-xpath;
    return '' unless ?$xpath;

    my $txt = $xpath.find('head/title/text()').text;
    $txt //= $xpath.find('//title/text()').text;
    $txt //= 'no title found';

    $txt
  }

  #----------------------------------------------------------------------------
  method nResults ( --> Str ) {

    my $xpath = self.get-xpath;
    return '0 results' unless ?$xpath;

    my $x = $xpath.find('//div[@id="resultStats"]/text()').text;
    $x
  }
}

#------------------------------------------------------------------------------
# Query variable classes
#------------------------------------------------------------------------------
# Image variable
class GraphQL::Html::QC::Image {
  has Str $.src is rw;
  has Str $.alt is rw;
}

#------------------------------------------------------------------------------
# Query class
class GraphQL::Html::QC {

#  has GraphQL::Html::QC::Image $.img is rw;

  #----------------------------------------------------------------------------
  method uri ( Str :$uri --> Str ) {

    GraphQL::Html.instance.uri(:$uri);
  }

  #----------------------------------------------------------------------------
  method title ( --> Str ) {

    GraphQL::Html.instance.title
  }

  #----------------------------------------------------------------------------
  method image ( Int :$idx = 0 --> GraphQL::Html::QC::Image ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;

    return GraphQL::Html::QC::Image unless ?$xpath;

    my $i = $xpath.find( "//img", :to-list);
    my %a = $i[$idx].attribs;

    GraphQL::Html::QC::Image.new(
      :src(%a<src>//'No src'),
      :alt(%a<alt>//'No alt')
    );
  }

#`{{
  #----------------------------------------------------------------------------
  method imageList ( Int :$idx = 0, Int :$count = 1 --> Array ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;
    return GraphQL::Html::QC::Image unless ?$xpath;

    my $i = $xpath.find('//img');
    my %a = $i[$idx].attribs;

    GraphQL::Html::QC::Image.new(
      :src(%a<src>//'No src'),
      :alt(%a<alt>//'No alt')
    );
  }
}}
}
