use v6;
use GraphQL;
#use GraphQL::Server;

#------------------------------------------------------------------------------
unit class GraphQL::Http:auth<github:MARTIMM>;

has GraphQL::Schema $!schema-object;
has Str $!uri;

#------------------------------------------------------------------------------
submethod BUILD ( ) {

}

#------------------------------------------------------------------------------
method set-uri ( Str:D $!uri ) {

}

#------------------------------------------------------------------------------
multi method set-schema ( Str:D $schema!, Any:D :$resolvers! ) {

  $!schema-object .= new( $schema, :$resolvers);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method set-schema ( :$class! ) {

  $!schema-object .= new($class);
}

#------------------------------------------------------------------------------
method q ( Str $query, Bool :$json = False, :%variables = %(), --> Any ) {

  my GraphQL::Document $document = $!schema-object.document($query);
  with $!schema-object.execute( :$document, :%variables) {
    if $json {
      .to-json
    }

    else {
      $_;
    }
  }
}
