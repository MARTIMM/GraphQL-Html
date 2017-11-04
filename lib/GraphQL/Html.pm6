use v6;
use GraphQL;
use JSON::Fast;
use OpenSSL::Digest;
#use GraphQL::Server;
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
  has Str $!uri;
  has Hash $!query-sha1;
  has XML::Document $!document;
  has Str $!rootdir;
  has $.xpath;

  my GraphQL::Html $gh-obj;

  #----------------------------------------------------------------------------
  #| singleton class, use instance to initialize or to get object
  submethod new ( ) { !!! }

  #----------------------------------------------------------------------------
  # can only initialize once with rootdir
  method instance ( Str :$rootdir ) {

    unless $gh-obj.defined {
      $gh-obj = self.bless(:$rootdir);
      $gh-obj.set-schema( GraphQL::Html::QC, GraphQL::Html::QC::Image, :query-class(GraphQL::Html::QC.^name));
    }

    $gh-obj
  }

  #------------------------------------------------------------------------------
  submethod BUILD ( Str :$!rootdir ) {

    $!rootdir //= "$*HOME/.graphql-html";
    mkdir( $!rootdir, 0o750) unless $!rootdir.IO.d;
    mkdir( "$!rootdir/cache", 0o750) unless "$!rootdir/cache".IO.d;

    $!query-sha1 = {};
  }

  #------------------------------------------------------------------------------
  method load-page ( --> Str ) {

    return 'empty uri' unless $!uri;
#note "Load page: $!uri";

    my Str $status;

    my Str $xml;
    my Str $page-name = self.sha1($!uri);
    my Str $page-path = "$!rootdir/cache/$page-name";

    if $page-path.IO ~~ :r {
      $status = 'read from cache';
#TODO Check date to refresh page
note "Load cached from $page-path";
      $xml = $page-path.IO.slurp;
    }

    else {
      $status = 'page downloaded';

note "Load $!uri and cache in $page-path";
      my HTTP::UserAgent $ua .= new;
      $ua.timeout = 10;
      my $r = $ua.get($!uri);
      die "Download not successful" unless $r.is-success;
      $xml = $r.content;
      $page-path.IO.spurt($xml);
    }

note "start parse";
    my HTML::Parser::XML $parser .= new;
    $parser.parse($xml);
    $!document = $parser.xmldoc;
    $!xpath = XML::XPath.new(:$!document);
note "done parse";

    $status
  }

  #------------------------------------------------------------------------------
  method sha1 ( Str:D $txt --> Str ) {

    sha1($txt.encode)>>.fmt('%02x').join;
  }

  #------------------------------------------------------------------------------
  multi method set-schema ( Str:D $schema!, Any:D :$resolvers! ) {

    $!schema-object .= new( $schema, :$resolvers);
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  multi method set-schema ( *@types, :$query-class ) {

    $!schema-object .= new( @types, :query($query-class));
  }

  #------------------------------------------------------------------------------
  method q ( Str $query, Bool :$json = False, :%variables = %(), --> Any ) {

    my $result;

    # create a key to store queries
    my Str $sha1 = self.sha1($query);

note "Q: $query";

    # store query as a schema document if new
    $!query-sha1{$sha1} = $!schema-object.document($query)
      unless $!query-sha1{$sha1}:exists;
note "Doc $sha1";

    # get the document
    my GraphQL::Document $doc = $!query-sha1{$sha1};

note "execute";
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
note "ex done";
    $result;
  }

  #------------------------------------------------------------------------------
  method uri ( Str:D :$!uri --> Str ) {

    self.load-page;
  }

  #------------------------------------------------------------------------------
  method title ( --> Str ) {

    return '' unless ?$!xpath;

    my $txt = $!xpath.find('head/title/text()').text;
    $txt //= $!xpath.find('//title/text()').text;
    $txt //= 'no title found';

    $txt
  }

  #------------------------------------------------------------------------------
  method nResults ( --> Str ) {

note "nResults";
    return '0 results' unless ?$!xpath;

    my $x = $!xpath.find('//div[@id="resultStats"]/text()').text;
note "Results done";
    $x
  }
}

#------------------------------------------------------------------------------
class GraphQL::Html::QC::Image {
  has Str $.src is rw;
  has Str $.alt is rw;
}

#------------------------------------------------------------------------------
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
  method image ( --> GraphQL::Html::QC::Image ) {

    my GraphQL::Html $gh .= instance;

    my $i = $gh.xpath.find('//img');
    my %a = $i[0].attribs;

    GraphQL::Html::QC::Image.new(
      :src(%a<src>//'No src'),
      :alt(%a<alt>//'No alt')
    );
  }
}
