use v6;
use Test;

use GraphQL::Html;

#------------------------------------------------------------------------------
subtest 'q 1', {

  my GraphQL::Html $gh .= instance(:rootdir('./t/Root'));
  my Str $schema = Q:q:to/EO-SCHEMA/;
      type Query {
        hello: String
      }
      EO-SCHEMA

  $gh.schema(
    $schema,
    :resolvers(
      Query => {
        hello => sub ( ) { 'Hello World'; }
      }
    )
  );

  my Str $query = Q:q:to/EOQ/;
      query H {
        hello
      }
      EOQ

  my Any $result;
  $result = $gh.q($query);
  is $result<data><hello>, "Hello World", 'Hash result ok';
}

#------------------------------------------------------------------------------
subtest 'q 2', {

  my class Query {

    method hello ( Str :$name --> Str ) {
      "Hello $name"
    }
  }

  my GraphQL::Html $gh .= instance;
  $gh.schema(Query);

  my Str $query = q:to/EOQ/;
      query H( $name1: String, $name2: String) {
        h1: hello(name: $name1)
        h2: hello(name: $name2)
        h3: hello(name: World)
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables(%(:name1<Marcel>, :name2<Loes>)));

  is $result<data><h1>, "Hello Marcel", 'answer h1 ok';
  is $result<data><h2>, "Hello Loes", 'answer h2 ok';
  is $result<data><h3>, "Hello World", 'answer h3 ok';
}

#------------------------------------------------------------------------------
subtest 'q 3', {
  my Str $uri = "https://www.google.nl/search?q=graphql";
  my GraphQL::Html $gh .= instance;

  my class Query {
    method page ( Str :$uri --> Str ) { $gh.page(:$uri) }
    method title ( --> Str ) { $gh.title }
    method search ( Str :$xpath --> Str ) { $gh.search(:$xpath) }
  }

  $gh.schema(Query);

  my Str $query = Q:q:to/EOQ/;
      query Q1 ( $uri: String, $xpath: String) {
        page( uri: $uri)
        title
        search( xpath: $xpath)
      }
      EOQ

  my Any $result;
  $result = $gh.q( $query, :variables( %( :$uri, :xpath('//div[@id="resultStats"]'))));
  #diag "\nR: $result.perl()";
  is $result<data><title>, 'graphql - Google zoeken', "title found";
  like $result<data><search>, /:s Ongeveer .* resultaten/, "results found";
}

#------------------------------------------------------------------------------
subtest 'q 4', {
  my $cwd = ~$*CWD;
  my $test-file = 't/Root/test-file.html';
  my Str $uri = "file:///$cwd/$test-file";
  my GraphQL::Html $gh .= instance;

  unless $test-file.IO ~~ :r {
    $test-file.IO.spurt(Q:q:to/EOHTML/);
      <html>
        <head>
          <base href="https://google.nl/">
        </head>
        <body>
          <h1>text 1</h1>
          <p>and some paragraph text</p>
        </body>
      </html>
      EOHTML
  }

  my class Query {
    method page ( Str :$uri --> Str ) { GraphQL::Html.instance.page(:$uri); }
    method base ( --> Str ) { $gh.base; }
    method searchList ( --> Str ) { $gh.searchList(:xpath<//body>); }
  }

  $gh.schema(Query);

  my Str $query = Q:q:to/EOQ/;
      query Q1( $uri: String) {
        page(uri: $uri)
        base
      }
      EOQ

  my Any $result;
  my $xpath = '//div[@id="resultStats"]';
  $result = $gh.q( $query, :variables( %( :$uri, :$xpath)));
  #diag "\nR: $result.perl()";
  is $result<data><base>, 'https://google.nl/', "base found";
  #is $result<data><searchList>[0], 'text 1', '1st text found';
  #is $result<data><searchList>[1], 'and some paragraph text', '2nd text found';
}


#------------------------------------------------------------------------------
done-testing;
