use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q 1', {

  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance;
  $gh.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $uri: String, $idx: Int) {
        title
        image( idx: $idx) {
          src
          alt
        }
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :variables(%( :uri($uri3), :idx(0))));
#  diag "Result: " ~ $result.perl();

  like $result<data><title>, /:s beautiful landscaping/, "title found";
  like $result<data><image><alt>, /:s beautiful landscaping/, "alt img 0 found";
  like $result<data><image><src>,
    /'88fe88575fe34f15b8230692d1463742.jpg' $/,
    "src img 0 found";


}

#------------------------------------------------------------------------------
done-testing;
