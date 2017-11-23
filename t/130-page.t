use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q page', {

  my Str $uri = 'https://nl.pinterest.com/pin/626211523159394612/';
  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));

  my Str $query = Q:q:to/EOQ/;

      query pinterest ( $uri: String, $idx: Int) {
        page( uri: $uri) {
          status
          title
          imageList {
            alt
          }
        }
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%(:$uri, :idx(0))));
  diag "Result: " ~ $result.perl();

  $result = $result<data><page>;
  is $result<status>, "read from cache",$result<status>;
  like $result<title>, /:s What beautiful landscaping and decorating/,
    'title found on page';
  like $result<imageList>[0]<alt>, /:s Paint the pumpkins/,
    'found alt on 1st image';

  $result = $gh.q( $query, :variables(%( :$uri, :idx(0))))<data><page>;
#  diag "Result: " ~ $result.perl();

  is $result<status>, "page from memory cache",$result<status>;

#`{{
  is $result<data><linkList>[2]<href>,
    '/pin/550213279447448557/',
    "href of 3rd link found";
  like $result<data><linkList>[2]<imageList>[0]<alt>,
       /:s Fall/,
       '3rd link image alt ok';
}}
}

#------------------------------------------------------------------------------
done-testing;
