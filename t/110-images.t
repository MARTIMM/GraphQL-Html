use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q image', {
  my Str $uri1 = "https://www.google.nl/search?q=graphql";
  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $ghi .= instance;
#  $ghi.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $uri: String, $idx: Int) {
        uri( uri: $uri)
        title
        image( idx: $idx) {
          src
          alt
        }
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $ghi.q( $query, :!json, :variables(%( :uri($uri3), :idx(0))));
  diag "Result: " ~ $result.perl();

  like $result<data><title>, /:s beautiful landscaping/, "title found";
  like $result<data><image><alt>, /:s beautiful landscaping/, "alt img 0 found";
  like $result<data><image><src>,
    /'88fe88575fe34f15b8230692d1463742.jpg' $/,
    "src img 0 found";

  $result = $ghi.q( $query, :!json, :variables(%( :uri($uri3), :idx(1))));
#  diag "Result: " ~ $result.perl();

  like $result<data><image><alt>, /:s For something different/, "alt img 1 found";
  like $result<data><image><src>,
    /'pumpkins-pumpkin-farm.jpg' $/,
    "src img 1 found";
}

#------------------------------------------------------------------------------
subtest 'q more images', {
  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $ghi .= instance;
#  $ghi.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $uri: String, $idx: Int) {
        uri( uri: $uri)
        title
        image( idx: $idx) {
          src
          alt
        }
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $ghi.q( $query, :!json, :variables(%( :uri($uri3), :idx(0))));
  diag "Result: " ~ $result.perl();

  like $result<data><title>, /:s beautiful landscaping/, "title found";
  like $result<data><image><alt>, /:s beautiful landscaping/, "alt img 0 found";
  like $result<data><image><src>,
    /'88fe88575fe34f15b8230692d1463742.jpg' $/,
    "src img 0 found";

  $result = $ghi.q( $query, :!json, :variables(%( :uri($uri3), :idx(1))));
  diag "Result: " ~ $result.perl();

  like $result<data><image><alt>, /:s For something different/, "alt img 1 found";
  like $result<data><image><src>,
    /'pumpkins-pumpkin-farm.jpg' $/,
    "src img 1 found";
}

#------------------------------------------------------------------------------
done-testing;
