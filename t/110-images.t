use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q image', {
  my Str $uri1 = "https://www.google.nl/search?q=graphql";
  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $ghi .= instance;

  # uri via query
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
#  diag "Result: " ~ $result.perl();

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

  # load uri before query but we could do without because
  # 1) singleton is not removed
  # 2) uri is same as above so current-page comes from the same source
  $ghi.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $idx: Int, $count: Int) {
        imageList( idx: $idx, count: $count) {
          alt
        }
      }
      EOQ

#  diag "Query: $query";

  my Any $result;
  $result = $ghi.q(
    $query, :!json,
    :variables( %( :idx(1), :count(3)))
  );
#  diag "Result: " ~ $result.perl();

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
  my GraphQL::Html $ghi .= instance;

  my Any $result = $ghi.q( Q:q:to/EOQ/, :!json, :variables(%( :idx(0))));

      query Page( $idx: Int) {
        image( idx: $idx) {
          other
        }
      }
      EOQ

#  diag "Result: " ~ $result<data><image><other>.perl();

  is $result<data><image><other><data-reactid>, '59', 'react id is 59';
  ok $result<data><image><other><srcset>:exists, 'there is a source set';
  ok $result<data><image><other><style>:exists, 'there is a style too';
}

#------------------------------------------------------------------------------
done-testing;
