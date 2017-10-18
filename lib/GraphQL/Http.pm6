use v6;
use GraphQL;
#use GraphQL::Server;

#------------------------------------------------------------------------------
unit class GraphQL::Http:auth<github:MARTIMM>;

has GraphQL::Schema $!schema;
has Str $!gsl;

#----------------------------------------------------------------------------
submethod BUILD ( Str :$uri ) {

  $!gsl = Q:q:to/EO-SCHEMA/;
      type Query {
        hello: String
      }
      EO-SCHEMA

  $!schema .= new(
    $!gsl,
    resolvers => {
      Query => {
        hello => sub ( ) { self.hello(); }
      }
    }
  );

#  $!schema .= new(self);
#  GraphQL-Server($!schema);
}

#----------------------------------------------------------------------------
method q ( Str $query --> Str ) {

  $!schema.execute($query).to-json
}

#----------------------------------------------------------------------------
method hello ( --> Str ) {

  'Hello World'
}
