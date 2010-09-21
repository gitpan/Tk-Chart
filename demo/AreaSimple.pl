#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Areas;

my $mw = new MainWindow(
  -title      => 'Tk::Chart::Areas example',
  -background => 'white',
);

my $Chart = $mw->Areas(
  -title      => 'Tk::Chart::Areas',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -linewidth  => 1,
  -background => 'snow',
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 5,     12,    24,    33,    19,    8,     6,     15,    21 ],
  [ -1,    -2,    -5,    -6,    -3,    1.5,   1,     1.3,   2 ]
);

# Add a legend to the graph
my @Legends = ( 'legend 1', 'legend 2', );
$Chart->set_legend(
  -title       => 'Title legend',
  -data        => \@Legends,
  -titlecolors => 'blue',
);

# Add help identification
$Chart->set_balloon();

# Create the graph
$Chart->plot( \@data );

MainLoop();
