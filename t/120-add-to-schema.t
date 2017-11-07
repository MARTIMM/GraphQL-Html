use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q 1', {

  my GraphQL::Html $gh .= instance;
  my Str $schema = Q:q:to/EO-SCHEMA/;

      schema {
        query: Query
        mutation: Mutation
      }

      type Query {
        hello: String
      }
      EO-SCHEMA

  $gh.schema(
    $schema,
    :resolvers(
      Query => {
        hello => sub ( Str :$name ) { "Hello $name"; }
      }
    ),
    :name('Marcel'),
  );

  my Str $query = Q:q:to/EOQ/;
      query H( $name: String = "-" ) {
        hello
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :!json);
  is $result<data><hello>, "Hello Marcel", 'Hash result ok';
}

#------------------------------------------------------------------------------
done-testing;
