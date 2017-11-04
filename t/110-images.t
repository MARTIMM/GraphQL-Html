use v6;
use Test;

use GraphQL::Html;


diag '';
#------------------------------------------------------------------------------
subtest 'q 1', {
  my Str $uri1 = "https://www.google.nl/search?q=graphql";
  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $ghi .= instance;
  $ghi.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $uri: String) {
        uri( uri: $uri)
        title
        image {
          src
          alt
        }
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $ghi.q( $query, :!json, :variables(%(:uri($uri3))));
#  diag "Result: " ~ $result.perl();

  like $result<data><title>, /:s beautiful landscaping/, "title found";
  like $result<data><image><alt>, /:s beautiful landscaping/, "alt found";
  like $result<data><image><src>, /'.jpg' $/, "src found";
}

#------------------------------------------------------------------------------
done-testing;
