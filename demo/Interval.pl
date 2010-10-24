#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Lines;

my $mw = new MainWindow(
  -title      => '-interval, -yminvalue and -ymaxvalue options',
  -background => 'white',
);
$mw->Label(
  -text => "3 charts using Tk::Chart::Bars with short interval data\n"
    . "data : 29.9, 30, 29.95, 29.99, 29.92, 29.91, 29.97, 30.1",
  -background => 'white',
)->pack(qw / -side top /);

my $Chart = $mw->Lines( -title => 'No Interval', )->pack(qw / -side left -fill both -expand 1 /);
my $Chart2 = $mw->Lines(
  -title     => "Using -yminvalue and -ymaxvalue options",
  -yminvalue => 29.5,
  -ymaxvalue => 30.5,
)->pack(qw / -side left -fill both -expand 1/);
my $Chart3 = $mw->Lines(
  -title    => "Using -interval option",
  -interval => 1,
)->pack(qw / -side left -fill both -expand 1/);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th' ],
  [ 29.9,  30,    29.95, 29.99, 29.92, 29.91, 29.97, 30.1 ],

);

foreach my $Chart ( $Chart, $Chart2, $Chart3 ) {
  $Chart->enabled_gradientcolor();
  $Chart->configure(
    -xlabel      => 'X Label',
    -ylabel      => 'Y Label',
    -background  => 'snow',
    -linewidth   => 2,
    -yticknumber => 10,
    -ylongticks  => 1,
  );

  # Add a legend to the graph
  my @Legends = ('data 1');
  $Chart->set_legend(
    -title => 'Legend',
    -data  => \@Legends,
  );

  # Add help identification
  $Chart->set_balloon();

  # Create the graph
  $Chart->plot( \@data );
}

MainLoop();
