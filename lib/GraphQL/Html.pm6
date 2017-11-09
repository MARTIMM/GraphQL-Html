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
class GraphQL::Html::QC::Link { ... }

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
      $gh-obj.schema(
        GraphQL::Html::QC,
        GraphQL::Html::QC::Image,
        GraphQL::Html::QC::Link,
        :query(GraphQL::Html::QC.^name)
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
  method schema ( *@args, *%opts ) {

    $!schema-object .= new( |@args, |%opts);
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
  method q ( Str $query, :%variables = %(), --> Hash ) {

    my Hash $result = {};

    # create a key to store queries
    my Str $sha1 = self.sha1($query);

    # store query as a schema document if new
    $!queries{$sha1} = $!schema-object.document($query)
      unless $!queries{$sha1}:exists;

    # get the document
    my GraphQL::Document $doc = $!queries{$sha1};

    # execute the query with any variables
    with $!schema-object.execute( :document($doc), :%variables) {

      my Str $jsonText = .to-json;

#note "JSon: ", $jsonText;
      # remove some non-json structures

      # drop the linefeed char
      $jsonText ~~ s:g/\n/ /;

      # single escape chars must be doubled. sometime it appears
      # in error messages
      $jsonText ~~ s:g/\\ <?before <-[\\]>>/\\\\/;
      $result = from-json($jsonText);
    }

    $result;
  }

  #----------------------------------------------------------------------------
  # Following methods can be used from query and its variables
  #----------------------------------------------------------------------------
  # uri can be called using the the object too
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

#==============================================================================
# Query variable classes

role GraphQL::Html::QC::CommonAttribs {
  has Str $.id is rw;
  has Str $.class is rw;
  has Str $.style is rw;

  has Hash $.other is rw;

  submethod set-common ( %attribs ) {
    $!id = %attribs<id>:delete if %attribs<id>:exists;
    $!class = %attribs<class>:delete if %attribs<class>:exists;
    $!style = %attribs<style>:delete if %attribs<style>:exists;
    $!other = %attribs;
  }
}

#==============================================================================
# Image variable <img>
class GraphQL::Html::QC::Image does GraphQL::Html::QC::CommonAttribs {
  has Str $.src is rw;
  has Str $.alt is rw;

  submethod BUILD ( *%attribs ) {
    $!src = %attribs<src>:delete if %attribs<src>:exists;
    $!alt = %attribs<alt>:delete if %attribs<alt>:exists;

    self.set-common(%attribs);
  }
}

#==============================================================================
# Link variable <a>
class GraphQL::Html::QC::Link does GraphQL::Html::QC::CommonAttribs {
  has Str $.href is rw;
  has Str $.target is rw;

  has Str $.text is rw;
  has Array[GraphQL::Html::QC::Image] $.imageList is rw;

  submethod BUILD ( *%attribs ) {
    $!href = %attribs<href>:delete if %attribs<href>:exists;
    $!target = %attribs<target>:delete if %attribs<target>:exists;

    self.set-common(%attribs);
  }
}

#==============================================================================
# Query class
class GraphQL::Html::QC {

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

    my @imageElements = $xpath.find( "//img", :to-list);
    GraphQL::Html::QC::Image.new(| @imageElements[$idx].attribs)
  }

  #----------------------------------------------------------------------------
  # select images from document and return a slice starting from $idx for $count
  # images. When $count is -1 or 0, all images starting with $idx are selected.
  method imageList (
    Int :$idx is copy where ($_ >= 0) = 0, Int :$count where ($_ >= 0) = 1
    --> Array[GraphQL::Html::QC::Image]
  ) {

    my Array[GraphQL::Html::QC::Image] $imageList .= new;

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;
    return $imageList unless ?$xpath;

    my @imageElements = $xpath.find( '//img', :to-list);
    $idx = min( @imageElements.elems - 1, $idx);
    my @ie = ?$count ?? @imageElements.splice( $idx, $count)
                     !! @imageElements.splice($idx);

    for @ie -> $imageElement {
      $imageList.push: GraphQL::Html::QC::Image.new(| $imageElement.attribs);
    }

    CATCH { .note; }

    $imageList
  }

  #----------------------------------------------------------------------------
  method link ( Int :$idx = 0 --> GraphQL::Html::QC::Link ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;

    return GraphQL::Html::QC::Link unless ?$xpath;

    my @linkElements = $xpath.find( "//a", :to-list);
    my $linkElement = @linkElements[$idx];
    my GraphQL::Html::QC::Link $link .= new(|$linkElement.attribs);

    my @textElements = $xpath.find( ".//text()", :start($linkElement), :to-list);
    $link.text = @textElements>>.text.join(' ') if ? @textElements;

    my @imageElements = $xpath.find( ".//img", :start($linkElement), :to-list) // ();
    if ? @imageElements {
      my Array[GraphQL::Html::QC::Image] $imageList;
      for @imageElements -> $imageElement {
        $imageList.push: GraphQL::Html::QC::Image.new(| $imageElement.attribs);
      }

      $link.imageList = $imageList;
    }

    CATCH { .note; }

    $link
  }

  #----------------------------------------------------------------------------
  method linkList (
    Int :$idx is copy where ($_ >= 0) = 0, Int :$count where ($_ >= 0) = 1
    --> Array[GraphQL::Html::QC::Link]
  ) {

    my Array[GraphQL::Html::QC::Link] $links .= new;

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;
    return $links unless ?$xpath;

    my @linkElements = $xpath.find( '//a', :to-list);
    $idx = min( @linkElements.elems - 1, $idx);

    my @le = ?$count ?? @linkElements.splice( $idx)
                     !! @linkElements.splice( $idx, $count);

    for @le -> $linkElement {
      my $linkObj = GraphQL::Html::QC::Link.new(| $linkElement.attribs);
      my @imageElements = $xpath.find( ".//img", :start($linkElement), :to-list) // ();
      for @imageElements -> $imageElement {

        $linkObj.imageList.push: GraphQL::Html::QC::Image.new(| $imageElement.attribs);
      }

      $links.push($linkObj);
    }

    CATCH { .note; }

    $links
  }

  #----------------------------------------------------------------------------
  method linkedImage ( Int :$idx = 0 --> GraphQL::Html::QC::Link ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;

    return GraphQL::Html::QC::Image unless ?$xpath;

    my $i = $xpath.find( "//img", :to-list);
    my %a = $i[$idx].attribs;
    my Str $src = %a<src>:delete;
    my Str $alt = %a<alt>:delete;
    my Hash $other = %a;

    GraphQL::Html::QC::Image.new(
      :src($src//'No src'),
      :alt($alt//'No alt'),
      :other($other//{})
    )
  }

#`{{
  #----------------------------------------------------------------------------
  method imageList (
    Int :$idx where ($_ >= 0) = 0, Int :$count where ($_ >= 0) = 1
    --> Array[GraphQL::Html::QC::Image]
  ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;
    return GraphQL::Html::QC::Image unless ?$xpath;

    my Array[GraphQL::Html::QC::Image] $imageList;
    my $xp-imageList = $xpath.find( '//img', :to-list);
    for [@$xp-imageList].splice( $idx, $count) -> $img {
      my %a = $img.attribs;

      $imageList.push: GraphQL::Html::QC::Image.new(
        :src(%a<src>//'No src'),
        :alt(%a<alt>//'No alt')
      );
    }

    $imageList
  }


  #----------------------------------------------------------------------------
  method image ( Int :$idx = 0 --> GraphQL::Html::QC::Image ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;

    return GraphQL::Html::QC::Image unless ?$xpath;

    my $i = $xpath.find( "//img", :to-list);
    my %a = $i[$idx].attribs;
    my Str $src = %a<src>:delete;
    my Str $alt = %a<alt>:delete;
    my Hash $other = %a;

    GraphQL::Html::QC::Image.new(
      :src($src//'No src'),
      :alt($alt//'No alt'),
      :other($other//{})
    )
  }

  #----------------------------------------------------------------------------
  method imageList (
    Int :$idx where ($_ >= 0) = 0, Int :$count where ($_ >= 0) = 1
    --> Array[GraphQL::Html::QC::Image]
  ) {

    my GraphQL::Html $gh .= instance;
    my $xpath = $gh.get-xpath;
    return GraphQL::Html::QC::Image unless ?$xpath;

    my Array[GraphQL::Html::QC::Image] $imageList;
    my $xp-imageList = $xpath.find( '//img', :to-list);
    for [@$xp-imageList].splice( $idx, $count) -> $img {
      my %a = $img.attribs;

      $imageList.push: GraphQL::Html::QC::Image.new(
        :src(%a<src>//'No src'),
        :alt(%a<alt>//'No alt')
      );
    }

    $imageList
  }
}}
  }
