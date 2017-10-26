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
  my GraphQL::Http $gh .= new(:$uri);

  my class Query {
    my XML::Document $document;

    method title ( --> Str ) {

      $gh.title
    }

    method nResults ( --> Str ) {

      $gh.nResults
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

  $gh.set-schema(:class(Query));

  my Str $query = Q:q:to/EOQ/;
      query Page {
        title
        nResults
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :!json);
#  diag "Result: $result.perl()";
  is $result<data><title>,
     'graphql - Google zoeken',
     "title found: $result<data><title>";
  like $result<data><nResults>,
       /:s Ongeveer .* resultaten/,
       $result<data><nResults>;
}

#------------------------------------------------------------------------------
done-testing;
