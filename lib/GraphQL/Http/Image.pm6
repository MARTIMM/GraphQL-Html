use v6;

use GraphQL::Http;

#------------------------------------------------------------------------------
unit class GraphQL::Http::Image:auth<github:MARTIMM> is GraphQL::Http;


#------------------------------------------------------------------------------
submethod BUILD ( :$uri ) {

  my $string-schema = Q:q:to/EO-SCHEMA/;
    type Query {
      uri: String
      title: String
      links: {
        image: String
      }
    }
    EO-SCHEMA

  self.set-schema($string-schema);
}
