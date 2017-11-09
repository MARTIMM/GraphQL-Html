use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q link', {

  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));
  $gh.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $idx: Int) {
        link( idx: $idx) {
          href
          text
          imageList {
            src
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%(:idx(0))));
#  diag "Result: " ~ $result.perl();

  is $result<data><link><href>,
    'https://www.pinterest.com/_/_/about/cookie-policy/',
    "href of link 0 found";
  is $result<data><link><text>, 'gebruikt cookies', 'link text ok';


  $result = $gh.q( $query, :variables(%(:idx(13))));
#  diag "\nResult: " ~ $result.perl();
  is $result<data><link><imageList>[0]<alt>,
     'If only I had a front porch.',
     'found alt of first image of 13th link';
}

#------------------------------------------------------------------------------
subtest 'q link list', {

  my Str $uri3 = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance;
  $gh.uri(:uri($uri3));

  my Str $query = Q:q:to/EOQ/;

      query Page( $idx: Int, $count: Int) {
        linkList( idx: $idx, count: $count) {
          href
          imageList {
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%( :idx(4), :count(10))));
#  diag "Result: " ~ $result.perl();

  is $result<data><linkList>[0]<href>,
    '/explore/deco/',
    "href of link 0 found";

  is $result<data><linkList>[1]<href>,
    '/explore/halloween/',
    "href of link 1 found";

  is $result<data><linkList>[2]<href>,
    '/explore/tuin/',
    "href of link 2 found";

  like $result<data><linkList>[6]<imageList>[0]<alt>,
    /:s What beautiful landscaping and decorating/,
    "found alt on 1st image on 6th link from list";
}

#------------------------------------------------------------------------------
done-testing;
