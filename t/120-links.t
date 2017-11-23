use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q link', {

  my Str $uri = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));

  my Str $query-not-yet-possible = Q:q:to/EOQ/;

      fragment imgs on Link {
        imageList {
          src
          alt
        }
      }

      query pinterest ( $uri: String, $idx: Int) {
        page(uri: $uri)
        link(idx: $idx) {
          href
          text
          ...imgs
        }
      }
      EOQ

  my Str $query = Q:q:to/EOQ/;

      query pinterest ( $uri: String, $idx: Int) {
        page(uri: $uri)
        link(idx: $idx) {
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
  $result = $gh.q( $query, :variables(%( :$uri, :idx(0))));
#  diag "Result: " ~ $result.perl();

  is $result<data><link><href>,
    'https://www.pinterest.com/_/_/about/cookie-policy/',
    "href of link 0 found";
  is $result<data><link><text>, 'gebruikt cookies', 'link text ok';

  $result = $gh.q( $query, :variables(%( :$uri, :idx(13))));
  #diag "\nResult: " ~ $result.perl();
  is $result<data><link><href>, '/pin/240450067580525288/',
     'href is found of 14th link';
  is $result<data><link><imageList>[0]<alt>, 'If only I had a front porch.',
     'found alt of first image of 14th link';
}

#------------------------------------------------------------------------------
subtest 'q link list', {

  my Str $uri = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance;

  my Str $query = Q:q:to/EOQ/;

      query pinterest ( $uri: String, $idx: Int, $count: Int) {
        page( uri: $uri)
        linkList( idx: $idx, count: $count) {
          href
          imageList {
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%( :idx(4), :count(10), :$uri)));
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
subtest 'q link with always an image', {

  my Str $uri = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));

  my Str $query = Q:q:to/EOQ/;

      query pinterest ( $uri: String, $idx: Int) {
        page( uri: $uri)
        link( idx: $idx, withImage: true) {
          href
          imageList {
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%( :$uri, :idx(0))));
#  diag "Result: " ~ $result.perl();

  is $result<data><link><href>,
    '/pin/626211523159394612/',
    "href of link 0 found";
  like $result<data><link><imageList>[0]<alt>,
       /:s What beautiful landscaping and decorating/,
       'link image alt ok';

  $result = $gh.q( $query, :variables(%( :$uri, :idx(5))));
#  diag "\nResult: " ~ $result.perl();
  like $result<data><link><imageList>[0]<alt>,
       /:s Beauty pumpkin and flowers photo/,
       'found alt of first image of 5th link';
}

#------------------------------------------------------------------------------
subtest 'q link list with always an image', {

  my Str $uri = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));

  my Str $query = Q:q:to/EOQ/;

      query pinterest ( $uri: String, $idx: Int) {
        page( uri: $uri)
        linkList( idx: $idx, count: 3, withImage: true) {
          href
          imageList {
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%( :$uri, :idx(0))));
#  diag "Result: " ~ $result.perl();

  is $result<data><linkList>[2]<href>,
    '/pin/550213279447448557/',
    "href of 3rd link found";
  like $result<data><linkList>[2]<imageList>[0]<alt>,
       /:s Fall/,
       '3rd link image alt ok';

}

#------------------------------------------------------------------------------
done-testing;
