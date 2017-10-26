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
unit class GraphQL::Http:auth<github:MARTIMM>;

has GraphQL::Schema $!schema-object;
has Str $!uri;
has Hash $!query-sha1;
has XML::Document $!document;
has Str $!rootdir;

#------------------------------------------------------------------------------
submethod BUILD ( Str :$!rootdir = "$*HOME/.graphql-http", Str :$!uri ) {

  $!query-sha1 = {};

  mkdir( $!rootdir, 0o750) unless $!rootdir.IO.d;
  mkdir( "$!rootdir/cache", 0o750) unless "$!rootdir/cache".IO.d;

  self.load-page if $!uri;
}

#------------------------------------------------------------------------------
method set-uri ( Str:D $!uri ) {

  self.load-page if $!uri;
}

#------------------------------------------------------------------------------
multi method set-schema ( Str:D $schema!, Any:D :$resolvers! ) {

  $!schema-object .= new( $schema, :$resolvers);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method set-schema ( :$class! ) {

  $!schema-object .= new($class);
}

#------------------------------------------------------------------------------
method q ( Str $query, Bool :$json = False, :%variables = %(), --> Any ) {

  my GraphQL::Document $doc;
  my Str $sha1 = self.sha1($query);

  $!query-sha1{$sha1} = $!schema-object.document($query)
    unless $!query-sha1{$sha1}:exists;

  $doc = $!query-sha1{$sha1};

  with $!schema-object.execute( :document($doc), :%variables) {
    if $json {
      .to-json
    }

    else {
      my Str $json = .to-json;
#note "JSon: ", $json;
      $json ~~ s:g/\n/ /;
      $json ~~ s:g/\\ <?before <-[\\]>>/\\\\/;
      from-json($json)
    }
  }
}

#------------------------------------------------------------------------------
method load-page ( ) {

  my Str $xml;
  my Str $page-name = self.sha1($!uri);
  my Str $page-path = "$!rootdir/cache/$page-name";

  if $page-path.IO ~~ :r {
note "Load cached from $page-path";
    $xml = $page-path.IO.slurp;
  }

  else {

note "Load $!uri and cache in $page-path";
    my HTTP::UserAgent $ua .= new;
    $ua.timeout = 10;
    my $r = $ua.get($!uri);
    die "Download not successful" unless $r.is-success;
    $xml = $r.content;
    $page-path.IO.spurt($xml);
  }

  my HTML::Parser::XML $parser .= new;
  $parser.parse($xml);
  $!document = $parser.xmldoc;
  my $xpath = XML::XPath.new(:$!document);
#say "Doc ", $!document.perl;
#say "Uri: $!uri";
}

#------------------------------------------------------------------------------
method sha1 ( Str:D $txt --> Str ) {

  sha1($txt.encode)>>.fmt('%02x').join;
}

#------------------------------------------------------------------------------
method title ( --> Str ) {

  return '' unless ?$!document;

#  my $xpath = XML::XPath.new(:$!document);
  $xpath.find('/html/head/title/text()').text
}

#------------------------------------------------------------------------------
method nResults ( --> Str ) {

  return '0 results' unless ?$!document;

#  my $xpath = XML::XPath.new(:$!document);
  my $x = $xpath.find('//div[@id="resultStats"]/text()').text;
#note $x.perl;
  $x
}
