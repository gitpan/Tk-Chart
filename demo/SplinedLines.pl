#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Lines;

my $mw = new MainWindow(
  -title      => 'Tk::Chart::Lines - Spline',
  -background => 'white',
);
my $Chart = $mw->Lines(
  -title      => 'bezier curve examples',
  -xlabel     => 'X Label',
  -ylabel     => 'Y Label',
  -background => 'snow',
  -spline     => 1,
  -bezier     => 1,
  -linewidth  => 2,
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th' ],
  [ 10,    30,    20,    30,    5,     41,    1,     23 ],
  [ 10,    5,     10,    0,     17,    2,     40,    23 ],
  [ 20,    10,    12,    20,    30,    10,    35,    12 ],

);

# Add a legend to the graph
my @Legends = ( 'legend 1', 'legend 2', 'legend 3' );
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
