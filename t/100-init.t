use v6;
use GraphQL::Http;
use Test;

#------------------------------------------------------------------------------
subtest 'init 1', {
  my Str $uri = "https://www.google.nl/search?q=graphql";
  my GraphQL::Http $gh .= new(:$uri);

  my Str $query = Q:q:to/EOQ/;
      {
        hello
      }
      EOQ

  diag "Query: $query";

  my Str $result = $gh.q($query);
  diag "Result: $result";
  like $result, /:s '"hello": "Hello World"'/, 'query ok';
}

#------------------------------------------------------------------------------
done-testing;
