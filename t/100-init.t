use v6;
use GraphQL::Http;
use Test;

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

  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :json);
  diag "Result: $result";
  like $result, /:s '"hello": "Hello World"'/, 'query ok';

#`{{
  $result = $gh.q( $query, :!json);
  diag "Result: " ~ $result.perl;
  note "R: ", $result.^methods;
  note "Rntv: ", ($result.name//'N', $result.type//'T', $result.value//'V').join(', ');
  my $r2 = $result.value;
  note "R2ntv[0]: ", ($r2[0].name//'N', $r2[0].type//'T', $r2[0].value//'V').join(', ');
}}
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
      query H($name: String) {
        hello(name: $name)
      }
      EOQ

  diag "Query: $query";

  my Any $result;
  my %variables = %(
    name => 'Marcel'
  );
  $result = $gh.q( $query, :json, :variables(:name<Marcel>));
  diag "Result: $result";
  like $result, /:s '"hello": "Hello Marcel"'/, 'query ok';
}

#------------------------------------------------------------------------------
subtest 'q 3', {
  my Str $uri = "https://www.google.nl/search?q=graphql";

  my class Query {

    method hello ( --> Str ) {
      'Hello World'
    }
  }

  my GraphQL::Http $gh .= new;
  $gh.set-schema(:class(Query));

  my Str $query = Q:q:to/EOQ/;
      query H {
        uri
        hello
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :json);
  diag "Result: $result";
  like $result, /:s '"hello": "Hello World"'/, 'query ok';
}

#------------------------------------------------------------------------------
done-testing;
