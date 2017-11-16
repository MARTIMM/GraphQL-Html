use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q image', {
  my Str $uri1 = "https://www.google.nl/search?q=graphql";
  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));

  # uri via query
  my Str $query = Q:q:to/EOQ/;

      query Q1 ( $uri: String, $idx: Int) {
        page( uri: $uri)
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

  $result = $gh.q( $query, :variables(%( :uri($uri3), :idx(1))));
#  diag "Result: " ~ $result.perl();

  like $result<data><image><alt>, /:s For something different/, "alt img 1 found";
  like $result<data><image><src>,
    /'pumpkins-pumpkin-farm.jpg' $/,
    "src img 1 found";
}

#------------------------------------------------------------------------------
subtest 'q more images', {
  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance;

  my Str $query = Q:q:to/EOQ/;

      query Page( $uri: String, $idx: Int, $count: Int) {
        page(uri: $uri)
        imageList( idx: $idx, count: $count) {
          alt
        }
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $gh.q( $query, :variables( %( :uri($uri3), :idx(1), :count(3))));

  like $result<data><imageList>[0]<alt>,
    /:s For something different/,
    "alt img 0 found";
  like $result<data><imageList>[1]<alt>,
    /:s Fall/,
    "alt img 1 found";
  like $result<data><imageList>[2]<alt>,
    /:s If only I had a front porch/,
    "alt img 2 found";

  is $result<data><imageList>[0]<src>, Any, 'We did not ask for src\'s';
}

#------------------------------------------------------------------------------
subtest 'q more data on an image', {

  # uri already set above
  my GraphQL::Html $gh .= instance;
  my Str $uri = 'https://nl.pinterest.com/pin/626211523159394612/';

  my Any $result = $gh.q( Q:q:to/EOQ/, :variables(%( :$uri, :idx(0))));

      query Page ( $uri: String, $idx: Int) {
        page(uri: $uri)
        image( idx: $idx) {
          other
          style
        }
      }
      EOQ

#  diag "Result: " ~ $result<data><image><other>.perl();

  is $result<data><image><other><data-reactid>, '59', 'react id is 59';
  ok $result<data><image><other><srcset>:exists, 'there is a source set';
  ok $result<data><image><style>:exists, 'there is a style too';
}

#------------------------------------------------------------------------------
done-testing;
