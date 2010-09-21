#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::Chart::Bars;

my $mw = new MainWindow(
  -title      => 'Tk::Chart::Bars - cumulate + zoom menu',
  -background => 'white',
);

my $Chart = $mw->Bars(
  -title        => 'Tk::Chart::Bars - cumulate + zoom menu',
  -xlabel       => 'X Label',
  -background   => 'snow',
  -ylabel       => 'Y Label',
  -linewidth    => 2,
  -zeroaxisonly => 1,
  -cumulate     => 1,
  -showvalues   => 1,
  -outlinebar   => 'blue'
)->pack(qw / -fill both -expand 1 /);

my @data = (
  [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
  [ 1,     2,     5,     6,     3,     1.5,   1,     3,     4 ],
  [ 4,     0,     16,    2,     3,     5.5,   7,     5,     02 ],
  [ 1,     2,     4,     6,     3,     17.5,  1,     20,    10 ]
);

# Add a legend to our graph
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

$Chart->add_data( [ 1 .. 9 ], 'legend 4' );

my $menu = Menu( $Chart, [qw/30 50 80 100 150 200/] );

MainLoop();

sub CanvasMenu {
  my ( $Canvas, $x, $y, $CanvasMenu ) = @_;
  $CanvasMenu->post( $x, $y );

  return;
}

sub Menu {
  my ( $Chart, $RefData ) = @_;
  my %MenuConfig = (
    -tearoff    => 0,
    -takefocus  => 1,
    -background => 'white',
    -menuitems  => [],
  );
  my $Menu = $Chart->Menu(%MenuConfig);
  $Menu->add( 'cascade', -label => 'Zoom' );
  $Menu->add( 'cascade', -label => 'Zoom X-axis' );
  $Menu->add( 'cascade', -label => 'Zoom Y-axis' );

  my $SsMenuZoomX = $Menu->Menu(%MenuConfig);
  my $SsMenuZoomY = $Menu->Menu(%MenuConfig);
  my $SsMenuZoom  = $Menu->Menu(%MenuConfig);

  for my $Zoom ( @{$RefData} ) {
    $SsMenuZoom->add(
      'command',
      -label   => "$Zoom \%",
      -command => sub { $Chart->zoom($Zoom); }
    );
    $SsMenuZoomX->add(
      'command',
      -label   => "$Zoom \%",
      -command => sub { $Chart->zoomx($Zoom); }
    );
    $SsMenuZoomY->add(
      'command',
      -label   => "$Zoom \%",
      -command => sub { $Chart->zoomy($Zoom); }
    );

  }

  $Menu->entryconfigure( 'Zoom X-axis', -menu => $SsMenuZoomX );
  $Menu->entryconfigure( 'Zoom Y-axis', -menu => $SsMenuZoomY );
  $Menu->entryconfigure( 'Zoom',        -menu => $SsMenuZoom );

  $Chart->Tk::bind( '<ButtonPress-3>', [ \&CanvasMenu, Ev('X'), Ev('Y'), $Menu, $Chart ] );

  return $Menu;
}
