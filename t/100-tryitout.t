use v6;
use Test;

use GraphQL::Http;
use HTTP::UserAgent;
use HTML::Parser::XML;
use XML;
use XML::XPath;

diag '';

#------------------------------------------------------------------------------
subtest 'q 1', {

  my GraphQL::Http $gh .= new;
  my Str $schema = Q:q:to/EO-SCHEMA/;
      type Query {
        hello: String
      }
      EO-SCHEMA

  $gh.set-schema(
    $schema,
    :resolvers(
      Query => {
        hello => sub ( ) { 'Hello World'; }
      }
    )
  );

  my Str $query = Q:q:to/EOQ/;
      query H {
        hello
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :json);
#  diag "Result: $result";
  like $result, /:s '"hello": "Hello World"'/, 'query ok';

  $result = $gh.q( $query, :!json);
#  diag "Result: $result.perl()";
  is $result<data><hello>, "Hello World", 'Hash result ok';
}

#------------------------------------------------------------------------------
subtest 'q 2', {

  my class Query {

    method hello ( Str :$name --> Str ) {
      "Hello $name"
    }
  }

  my GraphQL::Http $gh .= new;
  $gh.set-schema(:class(Query));

  my Str $query = q:to/EOQ/;
      query H( $name1: String, $name2: String) {
        h1: hello(name: $name1)
        h2: hello(name: $name2)
        h3: hello(name: World)
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :json, :variables(%(:name1<Marcel>, :name2<Loes>)));
#  diag "Result: $result";
  like $result, /:s '"h1": "Hello Marcel"'/, 'answer h1 ok';
  like $result, /:s '"h2": "Hello Loes"'/, 'answer h2 ok';
  like $result, /:s '"h3": "Hello World"'/, 'answer h3 ok';
}

#------------------------------------------------------------------------------
subtest 'q 3', {
  my Str $uri = "https://www.google.nl/search?q=graphql";

  my class Query {
    my XML::Document $document;

    method uri ( Str :$uri --> Str ) {

      my $html;
      if 't/cached-page.html'.IO ~~ :r {
        $html = 't/cached-page.html'.IO.slurp;
      }

      else {

        my HTTP::UserAgent $ua .= new;
        $ua.timeout = 10;
        my $r = $ua.get($uri);
        if $r.is-success {
          $html = $r.content;
          't/cached-page.html'.IO.spurt($html);
        }

        else {
          die "Download not successful";
        }
      }

      my HTML::Parser::XML $parser .= new;
      $parser.parse($html);
#say "Index: $parser.index()";
      try {
        $document = $parser.xmldoc;
        CATCH {
          default {
            .note;
          }
        }
      }
#say "Doc ", $document.perl;
#say "Uri: $uri";

      $uri
    }

    method title ( --> Str ) {

      return '' unless ?$document;

      my $xpath = XML::XPath.new(:$document);
      $xpath.find('/html/head/title/text()').text
    }

    method nResults ( --> Str ) {

      return '0 results' unless ?$document;

      my $xpath = XML::XPath.new(:$document);
      my $x = $xpath.find('//div[@id="resultStats"]/text()').text;
#note $x.perl;
      $x
    }

#`{{
    method items ( --> Hash ) {

      return {} unless ?$document;

      my Hash $h = {};
      my $xpath = XML::XPath.new(:$document);
      for | $xpath.find('//h3[@class="r"]/a') -> $a {
        note 'A: ', $a.WHAT;
        my Str $txt;
        for |$a.nodes() -> $node {
          .text.join('');
        my Str $href = $a.attribs<href>;
        $h{$txt} = $href;
      }

      note "H: ", $h;
      $h
    }
}}
  }

  my GraphQL::Http $gh .= new;
  $gh.set-schema(:class(Query));

  my Str $query = Q:q:to/EOQ/;
      query Page($uri: String ) {
        uri(uri: $uri)
        title
        nResults
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :!json, :variables(%(:uri($uri),)));
#  diag "Result: $result.perl()";
  is $result<data><uri>, $uri, "Uri $result<data><uri> returned";
  is $result<data><title>,
     'graphql - Google zoeken',
     "title found: $result<data><title>";
  like $result<data><nResults>,
       /:s Ongeveer .* resultaten/,
       $result<data><nResults>;
}

#------------------------------------------------------------------------------
done-testing;
