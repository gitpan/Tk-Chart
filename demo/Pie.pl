#!/usr/bin/perl
use strict;
use warnings;
use Tk;

use Tk::Chart::Pie;
my $mw = new MainWindow( -title => 'Tk::Chart::Pie example', );

my $Chart = $mw->Pie(
  -title      => 'There are currently 231 CPAN mirrors around the World (20/09/2010 18:50:57).',
  -background => 'white',
  -linewidth  => 2,
)->pack(qw / -fill both -expand 1 /);

my @data = ( [ 'Europe', 'Asia', 'Africa', 'Oceania', 'Americas' ], [ 119, 33, 3, 6, 67 ], );

$Chart->plot( \@data );

MainLoop();
