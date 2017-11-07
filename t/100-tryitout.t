use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q 1', {

  my GraphQL::Html $gh .= instance;
  my Str $schema = Q:q:to/EO-SCHEMA/;
      type Query {
        hello: String
      }
      EO-SCHEMA

  $gh.schema(
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

  my Any $result;
  $result = $gh.q( $query, :json);
  like $result, /:s '"hello": "Hello World"'/, 'query ok';

  $result = $gh.q( $query, :!json);
  is $result<data><hello>, "Hello World", 'Hash result ok';
}

#------------------------------------------------------------------------------
subtest 'q 2', {

  my class Query {

    method hello ( Str :$name --> Str ) {
      "Hello $name"
    }
  }

  my GraphQL::Html $gh .= instance;
  $gh.schema(Query);

  my Str $query = q:to/EOQ/;
      query H( $name1: String, $name2: String) {
        h1: hello(name: $name1)
        h2: hello(name: $name2)
        h3: hello(name: World)
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :json, :variables(%(:name1<Marcel>, :name2<Loes>)));

  like $result, /:s '"h1": "Hello Marcel"'/, 'answer h1 ok';
  like $result, /:s '"h2": "Hello Loes"'/, 'answer h2 ok';
  like $result, /:s '"h3": "Hello World"'/, 'answer h3 ok';
}

#------------------------------------------------------------------------------
subtest 'q 3', {
  my Str $uri = "https://www.google.nl/search?q=graphql";
  my GraphQL::Html $gh .= instance;

  my class Query {

    method uri ( Str :$uri --> Str ) {

      $gh.uri(:$uri);
    }

    method title ( --> Str ) {

      $gh.title
    }

    method nResults ( --> Str ) {

      $gh.nResults
    }
  }

  $gh.schema(Query);

  my Str $query = Q:q:to/EOQ/;
      query Page {
        uri( uri: "https://www.google.nl/search?q=graphql" )
        title
        nResults
      }
      EOQ

  my Any $result;
note "start";
  $result = $gh.q( $query, :!json);
note "done";
  is $result<data><title>, 'graphql - Google zoeken', "title found";
  like $result<data><nResults>, /:s Ongeveer .* resultaten/, "results found";
}

#------------------------------------------------------------------------------
done-testing;
