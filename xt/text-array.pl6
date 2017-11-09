#!/usr/bin/env perl6

use v6;

my Array[Str] $text .= new;

$text.push( 'abc', 'def');

note $text.perl;

sub a ( --> Array[Str] ) {

  my Array[Str] $text .= new;
  $text.push( 'abc', 'def');
  $text;

}

note a.perl;
