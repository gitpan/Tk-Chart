package Tk::Chart::Lines;

use warnings;
use strict;
use Carp;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 24/10/2010 12:45:29
# AIM       : Create line graph
#==================================================================

use vars qw($VERSION);
$VERSION = '1.02';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES :DISPLAY /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Lines';

sub Populate {

  my ( $CompositeWidget, $RefParameters ) = @_;

  # Get initial parameters
  $CompositeWidget->{RefChart} = _InitConfig();

  $CompositeWidget->SUPER::Populate($RefParameters);

  $CompositeWidget->Advertise( 'GradientColor' => $CompositeWidget->SUPER::GradientColor );
  $CompositeWidget->Advertise( 'canvas'        => $CompositeWidget->SUPER::Canvas );
  $CompositeWidget->Advertise( 'Canvas'        => $CompositeWidget->SUPER::Canvas );

  # remove highlightthickness if necessary
  unless ( exists $RefParameters->{-highlightthickness} ) {
    $CompositeWidget->configure( -highlightthickness => 0 );
  }

  my $RefConfigCommon = _get_ConfigSpecs();

  # ConfigSpecs
  $CompositeWidget->ConfigSpecs(

    # Common options
    %{$RefConfigCommon},

    -dash => [ 'PASSIVE', 'Dash', 'Dash', undef ],

    # splined
    -bezier => [ 'PASSIVE', 'Bezier', 'Bezier', 0 ],
    -spline => [ 'PASSIVE', 'Spline', 'Spline', 0 ],

    # points
    -pointline  => [ 'PASSIVE', 'Pointline',  'PointLine',  0 ],
    -markersize => [ 'PASSIVE', 'Markersize', 'MarkerSize', 8 ],
    -markers => [ 'PASSIVE', 'Markers', 'Markers', [ 1 .. 8 ] ],
  );

  $CompositeWidget->Delegates( DEFAULT => $CompositeWidget, );

  # recreate graph after widget resize
  $CompositeWidget->enabled_automatic_redraw();
  $CompositeWidget->disabled_gradientcolor();
}

sub _Balloon {
  my ($CompositeWidget) = @_;

  # balloon defined and user want to stop it
  if ( defined $CompositeWidget->{RefChart}->{Balloon}{Obj}
    and $CompositeWidget->{RefChart}->{Balloon}{State} == 0 )
  {
    $CompositeWidget->_DestroyBalloonAndBind();
    return;
  }

  # balloon not defined and user want to stop it
  elsif ( $CompositeWidget->{RefChart}->{Balloon}{State} == 0 ) {
    return;
  }

  # balloon defined and user want to start it again (may be new option)
  elsif ( defined $CompositeWidget->{RefChart}->{Balloon}{Obj}
    and $CompositeWidget->{RefChart}->{Balloon}{State} == 1 )
  {

    # destroy the balloon, it will be re create above
    $CompositeWidget->_DestroyBalloonAndBind();
  }

  # Balloon creation
  $CompositeWidget->{RefChart}->{Balloon}{Obj} = $CompositeWidget->Balloon(
    -statusbar  => $CompositeWidget,
    -background => $CompositeWidget->{RefChart}->{Balloon}{Background},
  );
  $CompositeWidget->{RefChart}->{Balloon}{Obj}->attach(
    $CompositeWidget,
    -balloonposition => 'mouse',
    -msg             => $CompositeWidget->{RefChart}->{Legend}{MsgBalloon},
  );

  # no legend, no bind
  unless ( my $LegendTextNumber = $CompositeWidget->{RefChart}->{Legend}{NbrLegend} ) {
    return;
  }

  # bind legend and lines
  for my $IndexLegend ( 1 .. $CompositeWidget->{RefChart}->{Legend}{NbrLegend} ) {

    my $LegendTag = $IndexLegend . $CompositeWidget->{RefChart}->{TAGS}{Legend};
    my $LineTag   = $IndexLegend . $CompositeWidget->{RefChart}->{TAGS}{Line};

    $CompositeWidget->bind(
      $LegendTag,
      '<Enter>',
      sub {
        my $OtherColor = $CompositeWidget->{RefChart}->{Balloon}{ColorData}->[0];

        # Change color if line have the same color
        if ( $OtherColor eq $CompositeWidget->{RefChart}{Line}{$LineTag}{color} ) {
          $OtherColor = $CompositeWidget->{RefChart}->{Balloon}{ColorData}->[1];
        }

        # if -fill enabled
        if ( $CompositeWidget->itemcget( $LineTag, -fill ) ) {
          $CompositeWidget->itemconfigure( $LineTag, -fill => $OtherColor, );
        }
        $CompositeWidget->itemconfigure( $LineTag,
          -width => $CompositeWidget->cget( -linewidth )
            + $CompositeWidget->{RefChart}->{Balloon}{MorePixelSelected}, );

        # if -outline enabled
        eval {
          if ( $CompositeWidget->itemcget( $LineTag, -outline ) )
          {
            $CompositeWidget->itemconfigure( $LineTag, -outline => $OtherColor, );
          }
        };
      }
    );

    $CompositeWidget->bind(
      $LegendTag,
      '<Leave>',
      sub {
        if ( $CompositeWidget->itemcget( $LineTag, -fill ) ) {
          $CompositeWidget->itemconfigure( $LineTag,
            -fill => $CompositeWidget->{RefChart}{Line}{$LineTag}{color}, );
        }
        $CompositeWidget->itemconfigure( $LineTag, -width => $CompositeWidget->cget( -linewidth ), );

        eval {
          if ( $CompositeWidget->itemcget( $LineTag, -outline ) )
          {
            $CompositeWidget->itemconfigure( $LineTag,
              -outline => $CompositeWidget->{RefChart}{Line}{$LineTag}{color}, );
          }
        };
      }
    );
  }

  return;
}

sub set_legend {
  my ( $CompositeWidget, %InfoLegend ) = @_;

  my $RefLegend = $InfoLegend{-data};
  unless ( defined $RefLegend ) {
    $CompositeWidget->_error(
      "Can't set -data in set_legend method. "
        . "May be you forgot to set the value\n"
        . "Ex : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  unless ( defined $RefLegend and ref($RefLegend) eq 'ARRAY' ) {
    $CompositeWidget->_error(
      "Can't set -data in set_legend method. Bad data\n"
        . "Ex : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  if ( defined $InfoLegend{-title} ) {
    $CompositeWidget->{RefChart}->{Legend}{title} = $InfoLegend{-title};
  }
  else {
    undef $CompositeWidget->{RefChart}->{Legend}{title};
    $CompositeWidget->{RefChart}->{Legend}{HeightTitle} = 5;
  }
  $CompositeWidget->{RefChart}->{Legend}{titlefont} = $InfoLegend{-titlefont}
    || $CompositeWidget->{RefChart}->{Font}{DefaultLegendTitle};
  $CompositeWidget->{RefChart}->{Legend}{legendfont} = $InfoLegend{-legendfont}
    || $CompositeWidget->{RefChart}->{Font}{DefaultLegendTitle};

  if ( defined $InfoLegend{-box} and $InfoLegend{-box} =~ m{^\d+$} ) {
    $CompositeWidget->{RefChart}->{Legend}{box} = $InfoLegend{-box};
  }
  if ( defined $InfoLegend{-titlecolors} ) {
    $CompositeWidget->{RefChart}->{Legend}{titlecolors} = $InfoLegend{-titlecolors};
  }

  # text color
  if ( defined $InfoLegend{-legendcolor} ) {
    $CompositeWidget->{RefChart}->{Legend}{legendcolor} = $InfoLegend{-legendcolor};
  }

  if ( defined $InfoLegend{-legendmarkerheight}
    and $InfoLegend{-legendmarkerheight} =~ m{^\d+$} )
  {
    $CompositeWidget->{RefChart}->{Legend}{HCube} = $InfoLegend{-legendmarkerheight};
  }
  if ( defined $InfoLegend{-legendmarkerwidth}
    and $InfoLegend{-legendmarkerwidth} =~ m{^\d+$} )
  {
    $CompositeWidget->{RefChart}->{Legend}{WCube} = $InfoLegend{-legendmarkerwidth};
  }
  if ( defined $InfoLegend{-heighttitle}
    and $InfoLegend{-heighttitle} =~ m{^\d+$} )
  {
    $CompositeWidget->{RefChart}->{Legend}{HeightTitle} = $InfoLegend{-heighttitle};
  }

  # Check legend and data size
  if ( my $RefData = $CompositeWidget->{RefChart}->{Data}{RefAllData} ) {
    $CompositeWidget->_CheckSizeLengendAndData( $RefData, $RefLegend );
  }

  # Get the biggest length of legend text
  my @LengthLegend = map { length; } @{$RefLegend};
  my $BiggestLegend = _MaxArray( \@LengthLegend );

  # 100 pixel =>  13 characters, 1 pixel =>  0.13 pixels then 1 character = 7.69 pixels
  $CompositeWidget->{RefChart}->{Legend}{WidthOneCaracter} = 7.69;

  # Max pixel width for a legend text for us
  $CompositeWidget->{RefChart}->{Legend}{LengthTextMax}
    = int( $CompositeWidget->{RefChart}->{Legend}{WidthText}
      / $CompositeWidget->{RefChart}->{Legend}{WidthOneCaracter} );

  # We have free space
  my $Diff = $CompositeWidget->{RefChart}->{Legend}{LengthTextMax} - $BiggestLegend;

  # Get new size width for a legend text with one pixel security
  $CompositeWidget->{RefChart}->{Legend}{WidthText}
    -= ( $Diff - 1 ) * $CompositeWidget->{RefChart}->{Legend}{WidthOneCaracter};

  # Store Reference data
  $CompositeWidget->{RefChart}->{Legend}{DataLegend} = $RefLegend;
  $CompositeWidget->{RefChart}->{Legend}{NbrLegend}  = scalar @{$RefLegend};

  return 1;
}

sub _Legend {
  my ( $CompositeWidget, $RefLegend ) = @_;

  # One legend width
  $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend}
    = +$CompositeWidget->{RefChart}->{Legend}{SpaceBeforeCube}    # space between each legend
    + $CompositeWidget->{RefChart}->{Legend}{WCube}               # width legend marker
    + $CompositeWidget->{RefChart}->{Legend}{SpaceAfterCube}      # space after marker
    + $CompositeWidget->{RefChart}->{Legend}{WidthText}           # legend text width allowed
    ;

  # Number of legends per line
  $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} = int( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width}
      / $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend} );
  $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} = 1
    if ( $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} == 0 );

  # How many legend we will have
  $CompositeWidget->{RefChart}->{Legend}{NbrLegend}
    = scalar @{ $CompositeWidget->{RefChart}->{Data}{RefAllData} } - 1;

=for NumberLines:
  We calculate the number of lines set for the legend graph.
  It can set 11 legends per line, then for 3 legend, we will need one line
  and for 12 legends, we will need 2 lines
  If NbrLeg / NbrPerLine = integer => get number of lines
  If NbrLeg / NbrPerLine = float => int(float) + 1 = get number of lines

=cut

  $CompositeWidget->{RefChart}->{Legend}{NbrLine}
    = $CompositeWidget->{RefChart}->{Legend}{NbrLegend} / $CompositeWidget->{RefChart}->{Legend}{NbrPerLine};
  unless (
    int( $CompositeWidget->{RefChart}->{Legend}{NbrLine} )
    == $CompositeWidget->{RefChart}->{Legend}{NbrLine} )
  {
    $CompositeWidget->{RefChart}->{Legend}{NbrLine}
      = int( $CompositeWidget->{RefChart}->{Legend}{NbrLine} ) + 1;
  }

  # Total Height of Legend
  $CompositeWidget->{RefChart}->{Legend}{Height}
    = $CompositeWidget->{RefChart}->{Legend}{HeightTitle}    # Hauteur Titre légende
    + $CompositeWidget->{RefChart}->{Legend}{NbrLine} * $CompositeWidget->{RefChart}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  if (
    $CompositeWidget->{RefChart}->{Legend}{NbrLegend} < $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} )
  {
    $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} = $CompositeWidget->{RefChart}->{Legend}{NbrLegend};
  }

  return;
}

sub _ViewLegend {
  my ($CompositeWidget) = @_;

  # legend option
  my $LegendTitle = $CompositeWidget->{RefChart}->{Legend}{title};

  my $legendmarkercolors = $CompositeWidget->cget( -colordata );
  my $legendfont         = $CompositeWidget->{RefChart}->{Legend}{legendfont};
  my $titlecolor         = $CompositeWidget->{RefChart}->{Legend}{titlecolors};
  my $titlefont          = $CompositeWidget->{RefChart}->{Legend}{titlefont};
  my $axiscolor          = $CompositeWidget->cget( -axiscolor );

  if ( defined $LegendTitle ) {
    my $xLegendTitle
      = $CompositeWidget->{RefChart}->{Axis}{CxMin} + $CompositeWidget->{RefChart}->{Legend}{SpaceBeforeCube};
    my $yLegendTitle
      = $CompositeWidget->{RefChart}->{Axis}{CyMin} 
      + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight}
      + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
      + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight};

    $CompositeWidget->createText(
      $xLegendTitle,
      $yLegendTitle,
      -text   => $LegendTitle,
      -anchor => 'nw',
      -font   => $titlefont,
      -fill   => $titlecolor,
      -width  => $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width},
      -tags   => [
        $CompositeWidget->{RefChart}->{TAGS}{TitleLegend},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  # Display legend
  my $IndexColor  = 0;
  my $IndexLegend = 0;
  my $IndexMarker = 0;
  $CompositeWidget->{RefChart}->{Legend}{GetIdLeg} = {};

  for my $NumberLine ( 0 .. $CompositeWidget->{RefChart}->{Legend}{NbrLine} - 1 ) {
    my $x1Cube
      = $CompositeWidget->{RefChart}->{Axis}{CxMin} + $CompositeWidget->{RefChart}->{Legend}{SpaceBeforeCube};
    my $y1Cube
      = ( $CompositeWidget->{RefChart}->{Axis}{CyMin} 
        + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight}
        + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
        + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight}
        + $CompositeWidget->{RefChart}->{Legend}{HeightTitle}
        + $CompositeWidget->{RefChart}->{Legend}{HLine} / 2 )
      + $NumberLine * $CompositeWidget->{RefChart}->{Legend}{HLine};

    my $x2Cube    = $x1Cube + $CompositeWidget->{RefChart}->{Legend}{WCube};
    my $y2Cube    = $y1Cube - $CompositeWidget->{RefChart}->{Legend}{HCube};
    my $xText     = $x2Cube + $CompositeWidget->{RefChart}->{Legend}{SpaceAfterCube};
    my $yText     = $y2Cube;
    my $MaxLength = $CompositeWidget->{RefChart}->{Legend}{LengthTextMax};

  LEGEND:
    for my $NumberLegInLine ( 0 .. $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} - 1 ) {

      my $LineColor = $legendmarkercolors->[$IndexColor];
      unless ( defined $LineColor ) {
        $IndexColor = 0;
        $LineColor  = $legendmarkercolors->[$IndexColor];
      }

      # Cut legend text if too long
      my $Legende = $CompositeWidget->{RefChart}->{Legend}{DataLegend}->[$IndexLegend];
      next unless ( defined $Legende );
      my $NewLegend = $Legende;

      if ( length $NewLegend > $MaxLength ) {
        $MaxLength -= 3;
        $NewLegend =~ s/^(.{$MaxLength}).*/$1/;
        $NewLegend .= '...';
      }

      my $Tag = ( $IndexLegend + 1 ) . $CompositeWidget->{RefChart}->{TAGS}{Legend};

      if ( $CompositeWidget->cget( -pointline ) == 1 ) {
        my $markersize = $CompositeWidget->cget( -markersize );
        my $markers    = $CompositeWidget->cget( -markers );
        my $NumMarker  = $markers->[$IndexMarker];
        unless ( defined $NumMarker ) {
          $IndexMarker = 0;
          $NumMarker   = $markers->[$IndexMarker];
        }
        my $RefType = $CompositeWidget->_GetMarkerType($NumMarker);
        my %Option;
        if ( $RefType->[1] == 1 ) {
          $Option{-fill} = $LineColor;
        }
        if ( $NumMarker =~ m{^[125678]$} ) {
          $Option{-outline} = $LineColor;
        }
        my $x = $x1Cube + ( ( $x2Cube - $x1Cube ) / 2 );
        my $y = $y1Cube + ( ( $y2Cube - $y1Cube ) / 2 );
        $Option{-tags} = [ $Tag, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ];
        $CompositeWidget->_CreateType(
          x      => $x,
          y      => $y,
          pixel  => 10,
          type   => $RefType->[0],
          option => \%Option,
        );
        $IndexMarker++;
      }
      else {
        $CompositeWidget->createRectangle(
          $x1Cube, $y1Cube, $x2Cube, $y2Cube,
          -fill    => $LineColor,
          -outline => $LineColor,
          -tags    => [ $Tag, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
        );
      }

      my $Id = $CompositeWidget->createText(
        $xText, $yText,
        -text   => $NewLegend,
        -anchor => 'nw',
        -tags   => [ $Tag, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
        -fill   => $CompositeWidget->{RefChart}->{Legend}{legendcolor},
      );
      if ($legendfont) {
        $CompositeWidget->itemconfigure( $Id, -font => $legendfont, );
      }
      $CompositeWidget->{RefChart}->{Legend}{GetIdLeg}{$Tag} = $IndexLegend;
      $CompositeWidget->{RefChart}->{Legend}{GetIdLeg}{$Tag} = $IndexLegend;

      $IndexColor++;
      $IndexLegend++;

      # cube
      $x1Cube += $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend};
      $x2Cube += $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend};

      # Text
      $xText += $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend};

      my $LineTag = $IndexLegend . $CompositeWidget->{RefChart}->{TAGS}{Line};
      $CompositeWidget->{RefChart}->{Legend}{MsgBalloon}->{$Tag}     = $Legende;
      $CompositeWidget->{RefChart}->{Legend}{MsgBalloon}->{$LineTag} = $Legende;

      if ( $IndexLegend == $CompositeWidget->{RefChart}->{Legend}{NbrLegend} ) {
        last LEGEND;
      }
    }
  }

  # box legend
  my $x1Box = $CompositeWidget->{RefChart}->{Axis}{CxMin};
  my $y1Box
    = $CompositeWidget->{RefChart}->{Axis}{CyMin} 
    + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight}
    + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
    + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight};
  my $x2Box
    = $x1Box
    + ( $CompositeWidget->{RefChart}->{Legend}{NbrPerLine}
      * $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend} );

  # Reajuste box if width box < legend title text
  my @InfoLegendTitle = $CompositeWidget->bbox( $CompositeWidget->{RefChart}->{TAGS}{TitleLegend} );
  if ( $InfoLegendTitle[2] and $x2Box <= $InfoLegendTitle[2] ) {
    $x2Box = $InfoLegendTitle[2] + 2;
  }
  my $y2Box = $y1Box + $CompositeWidget->{RefChart}->{Legend}{Height};
  $CompositeWidget->createRectangle(
    $x1Box, $y1Box, $x2Box, $y2Box,
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{BoxLegend}, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -outline => $axiscolor,
  );

  return;
}

sub _axis {
  my ($CompositeWidget) = @_;

  my $axiscolor = $CompositeWidget->cget( -axiscolor );

  # x-axis width
  $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width}
    = $CompositeWidget->{RefChart}->{Canvas}{Width}
    - ( 2 * $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}
      + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
      + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
      + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth} );

  # get Height legend
  if ( $CompositeWidget->{RefChart}->{Legend}{DataLegend} ) {
    $CompositeWidget->_Legend( $CompositeWidget->{RefChart}->{Legend}{DataLegend} );
  }

  # Height y-axis
  $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Height}
    = $CompositeWidget->{RefChart}->{Canvas}{Height}    # Largeur canvas
    - (
    2 * $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}          # 2 fois les espace vides
      + $CompositeWidget->{RefChart}->{Title}{Height}                     # Hauteur du titre
      + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight}           # Hauteur tick (axe x)
      + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}    # Hauteur valeurs axe
      + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight}         # Hauteur x label
      + $CompositeWidget->{RefChart}->{Legend}{Height}                    # Hauteur légende
    );

  #===========================
  # Y axis
  # Set 2 points (CxMin, CyMin) et (CxMin, CyMax)
  $CompositeWidget->{RefChart}->{Axis}{CxMin}                             # Coordonnées CxMin
    = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}             # Largeur vide
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth}            # Largeur label y
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}       # Largeur valeur axe y
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth};             # Largeur tick axe y

  $CompositeWidget->{RefChart}->{Axis}{CyMax}                             # Coordonnées CyMax
    = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}            # Hauteur vide
    + $CompositeWidget->{RefChart}->{Title}{Height}                       # Hauteur titre
    ;

  $CompositeWidget->{RefChart}->{Axis}{CyMin}                             # Coordonnées CyMin
    = $CompositeWidget->{RefChart}->{Axis}{CyMax}                         # Coordonnées CyMax (haut)
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Height}                 # Hauteur axe Y
    ;

  # display Y axis
  $CompositeWidget->createLine(
    $CompositeWidget->{RefChart}->{Axis}{CxMin},
    $CompositeWidget->{RefChart}->{Axis}{CyMin},
    $CompositeWidget->{RefChart}->{Axis}{CxMin},
    $CompositeWidget->{RefChart}->{Axis}{CyMax},
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{yAxis}, $CompositeWidget->{RefChart}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  #===========================
  # X axis
  # Set 2 points (CxMin,CyMin) et (CxMax,CyMin)
  # ou (Cx0,Cy0) et (CxMax,Cy0)
  $CompositeWidget->{RefChart}->{Axis}{CxMax}               # Coordonnées CxMax
    = $CompositeWidget->{RefChart}->{Axis}{CxMin}           # Coordonnées CxMin
    + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width}    # Largeur axe x
    ;

  # Bottom x-axis
  $CompositeWidget->createLine(
    $CompositeWidget->{RefChart}->{Axis}{CxMin},
    $CompositeWidget->{RefChart}->{Axis}{CyMin},
    $CompositeWidget->{RefChart}->{Axis}{CxMax},
    $CompositeWidget->{RefChart}->{Axis}{CyMin},
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{xAxis}, $CompositeWidget->{RefChart}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # POINT (0,0)
  # HeightUnit
  $CompositeWidget->{RefChart}->{Axis}{Yaxis}{HeightUnit}
    = $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Height}
    / ( $CompositeWidget->{RefChart}->{Data}{MaxYValue} - $CompositeWidget->{RefChart}->{Data}{MinYValue} );

  # min positive value >= 0
  if ( $CompositeWidget->{RefChart}->{Data}{MinYValue} >= 0 ) {
    $CompositeWidget->{RefChart}->{Axis}{Cx0} = $CompositeWidget->{RefChart}->{Axis}{CxMin};
    $CompositeWidget->{RefChart}->{Axis}{Cy0} = $CompositeWidget->{RefChart}->{Axis}{CyMin};
  }

  # min positive value < 0
  else {
    $CompositeWidget->{RefChart}->{Axis}{Cx0} = $CompositeWidget->{RefChart}->{Axis}{CxMin};
    $CompositeWidget->{RefChart}->{Axis}{Cy0}
      = $CompositeWidget->{RefChart}->{Axis}{CyMin}
      + ( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{HeightUnit}
        * $CompositeWidget->{RefChart}->{Data}{MinYValue} );

    # X Axis (0,0)
    $CompositeWidget->createLine(
      $CompositeWidget->{RefChart}->{Axis}{Cx0},
      $CompositeWidget->{RefChart}->{Axis}{Cy0},
      $CompositeWidget->{RefChart}->{Axis}{CxMax},
      $CompositeWidget->{RefChart}->{Axis}{Cy0},
      -tags => [
        $CompositeWidget->{RefChart}->{TAGS}{xAxis0}, $CompositeWidget->{RefChart}->{TAGS}{AllAXIS},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $axiscolor,
    );
  }

  return;
}

sub _xtick {
  my ($CompositeWidget) = @_;

  my $xvaluecolor = $CompositeWidget->cget( -xvaluecolor );
  my $longticks   = $CompositeWidget->cget( -longticks );

  # x coordinates y ticks on bottom x-axis
  my $Xtickx1 = $CompositeWidget->{RefChart}->{Axis}{CxMin};
  my $Xticky1 = $CompositeWidget->{RefChart}->{Axis}{CyMin};

  # x coordinates y ticks on 0,0 x-axis if the graph have only y value < 0
  if (  $CompositeWidget->cget( -zeroaxisonly ) == 1
    and $CompositeWidget->{RefChart}->{Data}{MaxYValue} > 0 )
  {
    $Xticky1 = $CompositeWidget->{RefChart}->{Axis}{Cy0};
  }

  my $Xtickx2 = $Xtickx1;
  my $Xticky2 = $Xticky1 + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight};

  # Coordinates of x values (first value)
  my $XtickxValue = $CompositeWidget->{RefChart}->{Axis}{CxMin};
  my $XtickyValue = $Xticky2 + ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} / 2 );
  my $NbrLeg      = scalar( @{ $CompositeWidget->{RefChart}->{Data}{RefXLegend} } );

  my $xlabelskip = $CompositeWidget->cget( -xlabelskip );

  # index of tick and vlaues that will be skip
  my %IndiceToSkip;
  if ( defined $xlabelskip ) {
    for ( my $i = 1; $i <= $NbrLeg; $i++ ) {
      $IndiceToSkip{$i} = 1;
      $i += $xlabelskip;
    }
  }

  for ( my $Indice = 1; $Indice <= $NbrLeg; $Indice++ ) {
    my $data = $CompositeWidget->{RefChart}->{Data}{RefXLegend}->[ $Indice - 1 ];

    # tick
    $Xtickx1 += $CompositeWidget->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    $Xtickx2 = $Xtickx1;

    # tick legend
    $XtickxValue += $CompositeWidget->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    my $RegexXtickselect = $CompositeWidget->cget( -xvaluesregex );

    if ( $data =~ m{$RegexXtickselect} ) {
      next unless ( defined $IndiceToSkip{$Indice} );

      # Display xticks short or long
      $CompositeWidget->_DisplayxTicks( $Xtickx1, $Xticky1, $Xtickx2, $Xticky2 );

      $CompositeWidget->createText(
        $XtickxValue,
        $XtickyValue,
        -text => $data,
        -fill => $xvaluecolor,
        -tags => [
          $CompositeWidget->{RefChart}->{TAGS}{xValues},
          $CompositeWidget->{RefChart}->{TAGS}{AllValues},
          $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
        ],
      );
    }
  }

  return;
}

sub _ViewDataLines {
  my ($CompositeWidget) = @_;

  my $legendmarkercolors = $CompositeWidget->cget( -colordata );
  my $bezier             = $CompositeWidget->cget( -bezier );
  my $spline             = $CompositeWidget->cget( -spline );
  my $dash               = $CompositeWidget->cget( -dash );

  # number of value for x-axis
  $CompositeWidget->{RefChart}->{Data}{xtickNumber} = $CompositeWidget->{RefChart}->{Data}{NumberXValues};

  # Space between x ticks
  $CompositeWidget->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width}
    / ( $CompositeWidget->{RefChart}->{Data}{xtickNumber} + 1 );

  my $IdData     = 0;
  my $IndexColor = 0;
  foreach my $RefArrayData ( @{ $CompositeWidget->{RefChart}->{Data}{RefAllData} } ) {
    if ( $IdData == 0 ) {
      $IdData++;
      next;
    }
    my $NumberData = 1;    # Number of data
    my @PointsData;        # coordinate x and y
    foreach my $data ( @{$RefArrayData} ) {
      unless ( defined $data ) {
        $NumberData++;
        next;
      }

      # coordinates x and y values
      my $x = $CompositeWidget->{RefChart}->{Axis}{Cx0}
        + $NumberData * $CompositeWidget->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
      my $y = $CompositeWidget->{RefChart}->{Axis}{Cy0}
        - ( $data * $CompositeWidget->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

      #update=
      if ( $CompositeWidget->{RefChart}->{Data}{MinYValue} > 0 ) {
        $y += ( $CompositeWidget->{RefChart}->{Data}{MinYValue}
            * $CompositeWidget->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
      }

      push( @PointsData, ( $x, $y ) );
      $NumberData++;
    }
    my $LineColor = $legendmarkercolors->[$IndexColor];
    unless ( defined $LineColor ) {
      $IndexColor = 0;
      $LineColor  = $legendmarkercolors->[$IndexColor];
    }
    my $tag = $IdData . $CompositeWidget->{RefChart}->{TAGS}{Line};

    # Add control points
    my @PointsDataWithoutControlPoints;
    if ( $spline == 1 and $bezier == 1 ) {
      @PointsDataWithoutControlPoints = @PointsData;
      my $RefPointsData = $CompositeWidget->_GetControlPoints( \@PointsData );
      @PointsData = @{$RefPointsData};
    }

    $CompositeWidget->createLine(
      @PointsData,
      -fill => $LineColor,
      -tags => [
        $tag, $CompositeWidget->{RefChart}->{TAGS}{AllData},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -width  => $CompositeWidget->cget( -linewidth ),
      -smooth => $bezier,
      -dash   => $dash,
    );

    # Display values above each points of lines
    my $LineNumber = $IdData - 1;
    if (@PointsDataWithoutControlPoints) {
      @PointsData                     = @PointsDataWithoutControlPoints;
      @PointsDataWithoutControlPoints = ();
      undef @PointsDataWithoutControlPoints;
    }

    if ( !( $spline == 0 and $bezier == 1 ) ) {
      $CompositeWidget->_display_line( \@PointsData, $LineNumber );
    }

    $CompositeWidget->{RefChart}{Line}{$tag}{color} = $LineColor;

    $IdData++;
    $IndexColor++;
  }

  if ( $spline == 0 and $bezier == 1 and $CompositeWidget->{RefChart}->{Data}{RefDataToDisplay} ) {
    $CompositeWidget->_error(
      'The values are not displayed because the curve crosses only by the extreme points.');
  }

  return 1;
}

sub _ViewDataPoints {
  my ($CompositeWidget) = @_;

  my $legendmarkercolors = $CompositeWidget->cget( -colordata );
  my $markersize         = $CompositeWidget->cget( -markersize );
  my $markers            = $CompositeWidget->cget( -markers );

  # number of value for x-axis
  $CompositeWidget->{RefChart}->{Data}{xtickNumber} = $CompositeWidget->{RefChart}->{Data}{NumberXValues};

  # Space between x ticks
  $CompositeWidget->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width}
    / ( $CompositeWidget->{RefChart}->{Data}{xtickNumber} + 1 );

  my $IdData      = 0;
  my $IndexColor  = 0;
  my $IndexMarker = 0;
  foreach my $RefArrayData ( @{ $CompositeWidget->{RefChart}->{Data}{RefAllData} } ) {
    if ( $IdData == 0 ) {
      $IdData++;
      next;
    }

    my $LineColor = $legendmarkercolors->[$IndexColor];
    my $NumMarker = $markers->[$IndexMarker];
    unless ( defined $LineColor ) {
      $IndexColor = 0;
      $LineColor  = $legendmarkercolors->[$IndexColor];
    }
    unless ( defined $NumMarker ) {
      $IndexMarker = 0;
      $NumMarker   = $markers->[$IndexMarker];
    }
    my $tag = $IdData . $CompositeWidget->{RefChart}->{TAGS}{Line};
    $CompositeWidget->{RefChart}{Line}{$tag}{color} = $LineColor;

    my $NumberData = 1;    # Number of data
    my @PointsData;        # coordinate x and y
    foreach my $data ( @{$RefArrayData} ) {
      unless ( defined $data ) {
        $NumberData++;
        next;
      }

      # coordinates x and y values
      my $x = $CompositeWidget->{RefChart}->{Axis}{Cx0}
        + $NumberData * $CompositeWidget->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
      my $y = $CompositeWidget->{RefChart}->{Axis}{Cy0}
        - ( $data * $CompositeWidget->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

      # allow reajustment
      if ( $CompositeWidget->{RefChart}->{Data}{MinYValue} > 0 ) {
        $y += ( $CompositeWidget->{RefChart}->{Data}{MinYValue}
            * $CompositeWidget->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
      }

      my %Option = (
        -tags => [
          $tag, $CompositeWidget->{RefChart}->{TAGS}{AllData},
          $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
        ],
        -width => $CompositeWidget->cget( -linewidth ),
      );
      my $RefType = $CompositeWidget->_GetMarkerType($NumMarker);
      if ( $RefType->[1] == 1 ) {
        $Option{-fill} = $LineColor;
      }
      if ( $NumMarker =~ m{^[125678]$} ) {
        $Option{-outline} = $LineColor;
      }

      $CompositeWidget->_CreateType(
        x      => $x,
        y      => $y,
        pixel  => $markersize,
        type   => $RefType->[0],
        option => \%Option,
      );
      $NumberData++;
      push( @PointsData, ( $x, $y ) );
    }

    # Display values above each points of lines
    my $LineNumber = $IdData - 1;
    $CompositeWidget->_display_line( \@PointsData, $LineNumber );

    $IdData++;
    $IndexColor++;
    $IndexMarker++;
  }

  return 1;
}

sub plot {
  my ( $CompositeWidget, $RefData, %option ) = @_;

  my $yticknumber = $CompositeWidget->cget( -yticknumber );
  my $yminvalue   = $CompositeWidget->cget( -yminvalue );
  my $ymaxvalue   = $CompositeWidget->cget( -ymaxvalue );
  my $interval    = $CompositeWidget->cget( -interval );

  if ( defined $option{-substitutionvalue}
    and _isANumber( $option{-substitutionvalue} ) )
  {
    $CompositeWidget->{RefChart}->{Data}{SubstitutionValue} = $option{-substitutionvalue};
  }

  unless ( defined $RefData ) {
    $CompositeWidget->_error('data not defined');
    return;
  }

  unless ( scalar @{$RefData} > 1 ) {
    $CompositeWidget->_error('You must have at least 2 arrays');
    return;
  }

  # Check legend and data size
  if ( my $RefLegend = $CompositeWidget->{RefChart}->{Legend}{DataLegend} ) {
    $CompositeWidget->_CheckSizeLengendAndData( $RefData, $RefLegend );
  }

  # Check array size
  $CompositeWidget->{RefChart}->{Data}{NumberXValues} = scalar @{ $RefData->[0] };
  my $i = 0;
  foreach my $RefArray ( @{$RefData} ) {
    unless ( scalar @{$RefArray} == $CompositeWidget->{RefChart}->{Data}{NumberXValues} ) {
      $CompositeWidget->_error( 'Make sure that every array has the same size in plot data method', 1 );
      return;
    }

    # Get min and max size
    if ( $i != 0 ) {

      # substitute none real value
      foreach my $data ( @{$RefArray} ) {
        if ( defined $data and !_isANumber($data) ) {
          $data = $CompositeWidget->{RefChart}->{Data}{SubstitutionValue};
        }
      }

      $CompositeWidget->{RefChart}->{Data}{MaxYValue}
        = _MaxArray( [ $CompositeWidget->{RefChart}->{Data}{MaxYValue}, _MaxArray($RefArray) ] );
      $CompositeWidget->{RefChart}->{Data}{MinYValue}
        = _MinArray( [ $CompositeWidget->{RefChart}->{Data}{MinYValue}, _MinArray($RefArray) ] );
    }
    $i++;
  }

  $CompositeWidget->{RefChart}->{Data}{RefXLegend}  = $RefData->[0];
  $CompositeWidget->{RefChart}->{Data}{RefAllData}  = $RefData;
  $CompositeWidget->{RefChart}->{Data}{PlotDefined} = 1;

  $CompositeWidget->_ManageMinMaxValues($yticknumber);
  $CompositeWidget->_ChartConstruction;

  return 1;
}

1;

__END__


=head1 NAME

Tk::Chart::Lines - Extension of Canvas widget to create a line graph. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::Chart::Lines;

  my $mw = new MainWindow(
    -title      => 'Tk::Chart::Lines example',
    -background => 'white',
  );
  my $Chart = $mw->Lines(
    -title  => 'My graph title',
    -xlabel => 'X Label',
    -ylabel => 'Y Label',
  )->pack(qw / -fill both -expand 1 /);

  my @data = (
    [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
    [ 1,     2,     5,     6,     3,     1.5,   1,     3,     4 ],
    [ 4,     2,     5,     2,     3,     5.5,   7,     9,     4 ],
    [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
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

=head1 DESCRIPTION

Tk::Chart::Lines is an extension of the Canvas widget. It is an easy way to build an 
interactive line graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

You can change the color, font of title, labels (x and y) of the graph.
You can set an interactive legend.  
The axes can be automatically scaled or set by the code. 
With this module it is possible to plot quantitative variables according to qualitative variables.

When the mouse cursor passes over a plotted line or its entry in the legend, 
the line and its entry will be turned to a color (that you can change) to help identify it. 

You can use 3 methods to zoom (vertically, horizontally or both).

=head1 BACKGROUND GRADIENT COLOR

You can set a background gradient color by using all methods of L<Tk::Canvas::GradientColor>. By 
default, it is not enabled.

To enabled background gradient color the first time, you firstly have to call B<enabled_gradientcolor> method and configure 
your color and type of gradient with B<set_gradientcolor>.

  $Chart->enabled_gradientcolor();
  $Chart->set_gradientcolor(
      -start_color => '#6585ED',
      -end_color   => '#FFFFFF',
  );

Please, read L<Tk::Canvas::GradientColor/"WIDGET-SPECIFIC METHODS"> documentation to know all available configurations.

=head1 STANDARD OPTIONS

B<-background>          B<-borderwidth>	      B<-closeenough>	         B<-confine>
B<-cursor>	            B<-height>	          B<-highlightbackground>	 B<-highlightcolor>
B<-highlightthickness>	B<-insertbackground>  B<-insertborderwidth>    B<-insertofftime>	
B<-insertontime>        B<-insertwidth>       B<-relief>               B<-scrollregion> 
B<-selectbackground>    B<-selectborderwidth> B<-selectforeground>     B<-takefocus> 
B<-width>               B<-xscrollcommand>    B<-xscrollincrement>     B<-yscrollcommand> 
B<-yscrollincrement>

=head1 WIDGET-SPECIFIC OPTIONS 

Many options allow you to configure your graph as you want. 
The default configuration is already OK, but you can change it.

=head2 Options for all lines graph

=over 4

=item Name:	B<Title>

=item Class: B<Title>

=item Switch:	B<-title>

Title of your graph.

 -title => 'My graph title',

Default : B<undef>

=item Name:	B<Titleposition>

=item Class:	B<TitlePosition>

=item Switch:	B<-titleposition>

Position of title : B<center>, B<left> or B<right>
  
 -titleposition => 'left',

Default : B<center>

=item Name:	B<Titlecolor>

=item Class: B<TitleColor>

=item Switch:	B<-titlecolor>

Title color of your graph.

 -titlecolor => 'red',

Default : B<black>

=item Name:	B<Titlefont>

=item Class: B<TitleFont>

=item Switch:	B<-titlefont>

Set the font for the title text. See also textfont option. 

 -titlefont => 'Times 15 {normal}',

Default : B<{Times} 12 {bold}>

=item Name:	B<Titleheight>

=item Class: B<TitleHeight>

=item Switch:	B<-titleheight>

Height for title graph space.

 -titleheight => 100,

Default : B<40>

=item Name:	B<Xlabel>

=item Class: B<XLabel>

=item Switch:	B<-xlabel>

The label to be printed just below the x-axis.

 -xlabel => 'X label',

Default : B<undef>

=item Name:	B<Xlabelcolor>

=item Class:	B<XLabelColor>

=item Switch:	B<-xlabelcolor>

Set x label color. See also textcolor option.

 -xlabelcolor => 'red',

Default : B<black>

=item Name:	B<Xlabelfont>

=item Class: B<XLabelFont>

=item Switch:	B<-xlabelfont>

Set the font for the x label text. See also textfont option.

 -xlabelfont => 'Times 15 {normal}',

Default : B<{Times} 10 {bold}>

=item Name:	B<Xlabelheight>

=item Class: B<XLabelHeight>

=item Switch:	B<-xlabelheight>

Height for x label space.

 -xlabelheight => 50,

Default : B<30>

=item Name:	B<Xlabelskip>

=item Class: B<XLabelSkip>

=item Switch:	B<-xlabelskip>

Print every xlabelskip number under the tick on the x-axis. If you have a 
dataset wich contain many points, the tick and x values will be overwrite 
on the graph. This option can help you to clarify your graph.
Eg: 

  # ['leg1', 'leg2', ...'leg1000', 'leg1001', ... 'leg2000'] => There are 2000 ticks and text values on x-axis.
  -xlabelskip => 1 => ['leg1', 'leg3', 'leg5', ...]        # => 1000 ticks will be display.

See also -xvaluesregex option.

 -xlabelskip => 2,

Default : B<0>

=item Name:	B<Xvaluecolor>

=item Class: B<XValueColor>

=item Switch:	B<-xvaluecolor>

Set x values colors. See also textcolor option.

 -xvaluecolor => 'red',

Default : B<black>

=item Name:	B<Xvaluespace>

=item Class:	B<XValueSpace>

=item Switch:	B<-xvaluespace>

Width for x values space.

 -xvaluespace => 50,

Default : B<30>

=item Name:	B<Xvalueview>

=item Class:	B<XvalueView>

=item Switch:	B<-xvalueview>

View values on x-axis.
 
 -xvalueview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Xvaluesregex>

=item Class:	B<XValuesRegex>

=item Switch:	B<-xvaluesregex>

View the x values which will match with regex. It allows you to display tick on x-axis and values 
that you want. You can combine it with -xlabelskip to display many dataset.

 ...
 ['leg1', 'leg2', 'data1', 'data2', 'symb1', 'symb2']
 ...

 -xvaluesregex => qr/leg/i,

On the graph, just leg1 and leg2 will be display.

Default : B<qr/.+/>

=item Name:	B<Ylabel>

=item Class:	B<YLabel>

=item Switch:	B<-ylabel>

The label to be printed next to y-axis.

 -ylabel => 'Y label',

Default : B<undef>

=item Name:	B<Ylabelcolor>

=item Class:	B<YLabelColor>

=item Switch:	B<-ylabelcolor>

Set the color of y label. See also textcolor option. 

 -ylabelcolor => 'red',

Default : B<black>

=item Name:	B<Ylabelfont>

=item Class:	B<YLabelFont>

=item Switch:	B<-ylabelfont>

Set the font for the y label text. See also textfont option. 

 -ylabelfont => 'Times 15 {normal}',

Default : B<{Times} 10 {bold}>

=item Name:	B<Ylabelwidth>

=item Class:	B<YLabelWidth>

=item Switch:	B<-ylabelwidth>

Width of space for y label.

 -ylabelwidth => 30,

Default : B<5>

=item Name:	B<Yvaluecolor>

=item Class:	B<YValueColor>

=item Switch:	B<-yvaluecolor>

Set the color of y values. See also valuecolor option.

 -yvaluecolor => 'red',

Default : B<black>

=item Name:	B<Yvalueview>

=item Class:	B<YvalueView>

=item Switch:	B<-yvalueview>

View values on y-axis.
 
 -yvalueview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Yminvalue>

=item Class:	B<YMinValue>

=item Switch:	B<-yminvalue>

Minimum value displayed on the y-axis. See also -interval option.
 
 -yminvalue => 10.12,

Default : B<0>

=item Name:	B<Ymaxvalue>

=item Class:	B<YMaxValue>

=item Switch:	B<-ymaxvalue>

Maximum value displayed on the y-axis. See also -interval option.
 
 -ymaxvalue => 5,

Default : B<Computed from data sets>

=item Name:	B<interval>

=item Class:	B<Interval>

=item Switch:	B<-interval>

If set to a true value, -yminvalue and -ymaxvalue will be fixed to minimum and maximum values of data sets. 
It overwrites -yminvalue and -ymaxvalue options.
 
 -interval => 1, # 0 or 1

Default : B<0>

=item Name:	B<Labelscolor>

=item Class: B<LabelsColor>

=item Switch:	B<-labelscolor>

Combine xlabelcolor and ylabelcolor options. See also textcolor option.

 -labelscolor => 'red',

Default : B<undef>

=item Name:	B<Valuescolor>

=item Class: B<ValuesColor>

=item Switch:	B<-valuescolor>

Set the color of x, y values in axes. It combines xvaluecolor 
and yvaluecolor options.

 -valuescolor => 'red',

Default : B<undef>

=item Name:	B<Textcolor>

=item Class: B<TextColor>

=item Switch:	B<-textcolor>

Set the color of x, y labels and title text. 
It combines titlecolor, xlabelcolor and ylabelcolor options.

 -textcolor => 'red',

Default : B<undef>

=item Name:	B<Textfont>

=item Class: B<TextFont>

=item Switch:	B<-textfont>

Set the font of x, y labels and title text. It combines titlefont, 
xlabelfont and ylabelfont options.

 -textfont => 'Times 15 {normal}',

Default : B<undef>

=item Name:	B<Longticks>

=item Class: B<LongTicks>

=item Switch:	B<-longticks>

If longticks is a true value, x and y ticks will be drawn with the same length as the axes. See also -xlongticks and -ylongticks options. 

 -longticks => 1, #  0 or 1

Default : B<0>

=item Name:	B<Longtickscolor>

=item Class: B<LongTicksColor>

=item Switch:	B<-longtickscolor>

Set the color of x and y ticks that will be drawn with the same length as the axes. See also -xlongtickscolor and -ylongtickscolor options.

  -longtickscolor => 'red',

Default : B<undef>

=item Name:	B<XLongticks>

=item Class: B<XLongTicks>

=item Switch:	B<-xlongticks>

If xlongticks is a true value, x ticks will be drawn with the same length as the x-axis. See also -longticks.

 -xlongticks => 1, #  0 or 1

Default : B<0>

=item Name:	B<YLongticks>

=item Class: B<YLongTicks>

=item Switch:	B<-ylongticks>

If ylongticks is a true value, y ticks will be drawn with the same length as the axes. See also -longticks.

 -ylongticks => 1, #  0 or 1

Default : B<0>

=item Name:	B<XLongtickscolor>

=item Class: B<XLongTicksColor>

=item Switch:	B<-xlongtickscolor>

Set the color of xlongticks. See also -xlongtickscolor.

  -xlongtickscolor => 'red',

Default : B<#B3B3B3>

=item Name:	B<YLongtickscolor>

=item Class: B<YLongTicksColor>

=item Switch:	B<-ylongtickscolor>

Set the color of ylongticks. See also -ylongtickscolor.

  -ylongtickscolor => 'red',

Default : B<#B3B3B3>

=item Name:	B<Boxaxis>

=item Class: B<BoxAxis>

=item Switch:	B<-boxaxis>

Draw the axes as a box.

 -boxaxis => 1, #  0 or 1

Default : B<0>

=item Name:	B<Noaxis>

=item Class: B<NoAxis>

=item Switch:	B<-noaxis>

Hide the axes with ticks and values ticks.

 -noaxis => 1, # 0 or 1

Default : B<0>

=item Name:	B<Zeroaxis>

=item Class: B<ZeroAxis>

=item Switch:	B<-zeroaxis>

If set to a true value, the axes for y values will only be drawn. 
This might be useful in case your graph contains negative values, 
but you want it to be clear where the zero value is
(see also zeroaxisonly and boxaxis).

 -zeroaxis => 1, # 0 or 1

Default : B<0>

=item Name:	B<Zeroaxisonly>

=item Class:	B<ZeroAxisOnly>

=item Switch:	B<-zeroaxisonly>

If set to a true value, the zero x-axis will be drawn and no axes 
at the bottom of the graph will be drawn. 
The labels for X values will be placed on the zero x-axis.
This works if there is at least one negative value in dataset.

 -zeroaxisonly => 1, # 0 or 1

Default : B<0>

=item Name:	B<Axiscolor>

=item Class: B<AxisColor>

=item Switch:	B<-axiscolor>

Color of the axes.

 -axiscolor => 'red',

Default : B<black>

=item Name:	B<Xtickheight>

=item Class:	B<XTickHeight>

=item Switch:	B<-xtickheight>

Set height of all x ticks.

 -xtickheight => 10,

Default : B<5>

=item Name:	B<Xtickview>

=item Class:	B<XTickView>

=item Switch:	B<-xtickview>

View x ticks of graph.

 -xtickview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Yticknumber>

=item Class: B<YTickNumber>

=item Switch:	B<-yticknumber>

Number of ticks to print for the y-axis.

 -yticknumber => 10,

Default : B<4>

=item Name:	B<Ytickwidth>

=item Class: B<YtickWidth>

=item Switch:	B<-ytickwidth>

Set width of all y ticks.
 
 -ytickwidth => 10,

Default : B<5>

=item Name:	B<Ytickview>

=item Class: B<YTickView>

=item Switch:	B<-ytickview>

View y ticks of graph.

 -ytickview => 0, # 0 or 1

Default : B<1>

=item Name:	B<Alltickview>

=item Class: B<AllTickView>

=item Switch:	B<-alltickview>

View all ticks of graph. Combines xtickview and ytickview options.

 -alltickview => 0, # 0 or 1

Default : B<undef>

=item Name:	B<Linewidth>

=item Class: B<LineWidth>

=item Switch:	B<-linewidth>

Set width of all lines graph of dataset.

 -linewidth => 10,

Default : B<1>

=item Name:	B<Colordata>

=item Class: B<ColorData>

=item Switch:	B<-colordata>

This controls the colors of the lines. This should be a reference 
to an array of color names.

 -colordata => [ qw(green pink blue cyan) ],

Default : 

  [ 'red',     'green',   'blue',    'yellow',  'purple',  'cyan',
    '#996600', '#99A6CC', '#669933', '#929292', '#006600', '#FFE100',
    '#00A6FF', '#009060', '#B000E0', '#A08000', 'orange',  'brown',
    'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
  ],

The default array contains 24 colors. If you have more than 24 samples, the next line 
will have the color of the first array case (red).

=item Name:	B<verbose>

=item Class:	B<Verbose>

=item Switch:	B<-verbose>

Warning will be print if necessary.
 
 -verbose => 0,

Default : B<1>

=back

=head2 Options for spline lines graph

=over 4

=item Name:	B<Bezier>

=item Class:	B<Bezier>

=item Switch:	B<-bezier>

To create lines graph as BE<eacute>zier curve. The curve crosses only by the 
extreme points (the first and the last).

 -bezier => 1, # 0 or 1

Default : B<0>

=item Name:	B<Spline>

=item Class:	B<Spline>

=item Switch:	B<-spline>

To create lines graph as BE<eacute>zier curve. The curve crosses by all points. 
The B<-bezier> option has to be set to B<1>.
 
 -spline => 1, # 0 or 1

Default : B<0>

=back


=head2 Options for point lines graph

These options are specific to point lines graph creation.

=over 4

=item Name:	B<Pointline>

=item Class:	B<PointLine>

=item Switch:	B<-pointline>

Set a true value to create point lines graph.  

 -pointline => 1, # 0 or 1

Default : B<0>

=item Name:	B<Markersize>

=item Class:	B<MarkerSize>

=item Switch:	B<-markersize>

The size of the markers used in points graphs, in pixels. 

 -markersize => 10, # integer

Default : B<8>

=item Name:	B<Markers>

=item Class:	B<Markers>

=item Switch:	B<-markers>

This controls the order of markers in points graphs. 
This should be a reference to an array of numbers:

 -markers => [3, 5, 6],

  Available markers are: 
  
  1:  filled square 
  2:  open square 
  3:  horizontal cross
  4:  diagonal cross
  5:  filled diamond
  6:  open diamond
  7:  filled circle
  8:  open circle
  9:  horizontal line
  10: vertical line

Default : B<[1,2,3,4,5,6,7,8]>
Note that the last two are not part of the default list.

=back

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 add_data

=over 4

=item I<$Chart>->B<add_data>(I<\@NewData, ?$legend>)

This method allows you to add data in your graph. If you have already plot data using plot method and 
if you want to add new data, you can use this method.
Your graph will be updade.

=back

=over 8

=item *

I<Data array reference>

Fill an array of arrays with the values of the datasets (I<\@data>). 
Make sure that every array has the same size, otherwise Tk::Chart::Lines 
will complain and refuse to compile the graph.

 my @NewData = (1,10,12,5,4);
 $Chart->add_data(\@NewData);

If your last graph has a legend, you have to add a legend entry for the new dataset. Otherwise, 
the legend graph will not be display (see below).

=item *

I<$legend>

 my @NewData = (1,10,12,5,4);
 my $legend = 'New data set';
 $Chart->add_data(\@NewData, $legend);

=back

=head2 clearchart

=over 4

=item I<$Chart>->B<clearchart>

This method allows you to clear the graph. The canvas 
will not be destroy. It's possible to I<redraw> your 
last graph using the I<redraw method>.

=back

=head2 delete_balloon

=over 4

=item I<$Chart>->B<delete_balloon>

If you call this method, you disable help identification which has been enabled with set_balloon method.

=back

=head2 disabled_automatic_redraw

=over 4

=item I<$Chart>->B<disabled_automatic_redraw>

When the graph is created and the widget size changes, the graph is automatically re-created. Call this method to avoid resizing.

  $Chart->disabled_automatic_redraw;  

=back

=head2 display_values

=over 4

=item I<$Chart>->B<display_values>(I<\@data_point_value>)

To plot the value of data near the points line graph, call this method to control in a generic manner.

  my @data_point_value = (
    [ 9,   2,   5,     6,   3,   1,   1,   3,   4 ],        # The first line data
    undef,                                                  # The second line data
    [ 'A', 'B', undef, 'D', 'E', 'F', 'G', 'H', undef ],    # The third line data
  );
  $Chart->display_values( \@data_point_value );

In this example, values are added above each point of the first and third lines. 
The second line is undef, no values are printed in the graph. 
B value is printed above the second point of the third line data.

=back

=head2 enabled_automatic_redraw

=over 4

=item I<$Chart>->B<enabled_automatic_redraw>

Use this method to allow your graph to be recreated automatically when the widget size change. When the graph 
is created for the first time, this method is called. 

  $Chart->enabled_automatic_redraw;  

=back

=head2 plot

=over 4

=item I<$Chart>->B<plot>(I<\@data, ?arg>)

To display your graph the first time, plot the graph by using this method.

=back

=over 8

=item *

I<\@data>

Fill an array of arrays with the x values and the values of the datasets (I<\@data>). 
Make sure that every array have the same size, otherwise Tk::Chart::Lines 
will complain and refuse to compile the graph.

 my @data = (
     [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
     [ 1,     2,     5,     6,     3,     1.5,   1,     3,     4  ],
     [ 4,     2,     5,     2,     3,     5.5,   7,     9,     4  ],
     [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
 );

@data have to contain a least two arrays, the x values and the values of the datasets.

If you don't have a value for a point in a dataset, you can use undef, 
and the point will be skipped.

 [ 1,     undef,     5,     6,     3,     1.5,   undef,     3,     4 ]


=item *

-substitutionvalue => I<real number>,

If you have a no real number value in a dataset, it will be replaced by a constant value.

Default : B<0>


 my @data = (
      [     '1st',   '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
      [         1,    '--',     5,     6,     3,   1.5,     1,     3,     4 ],
      [ 'mistake',       2,     5,     2,     3,  'NA',     7,     9,     4 ],
      [         1,       2,    52,     6,     3,  17.5,     1,    43,     4 ],
 );
 $Chart->plot( \@data,
   -substitutionvalue => '12',
 );
  # mistake, -- and NA will be replace by 12

-substitutionvalue have to be a real number (ex : 12, .25, 02.25, 5.2e+11, etc ...) 
  

=back

=over 8

=item *

I<\@data_to_display>

Fill an array of arrays with the values of the data to display (I<\@data_to_display>). 

  my @data_to_display = (
    [ 10, 30, 20, 30, 5, 41, 1, 23 ],
    [ 'A', 'B',    'C', 'D', 'E', 5.5,  'F', 'G', 4 ],
    [ 4,   'CPAN', 52,  6,   3,   17.5, 1,   43,  10 ]
  );

If you does not want to display a value for a point, you can use undef, 
and the point value will be skipped.

 [ 1,     undef,     5,     6,     3,     1.5,   undef,     3,     4 ]


=item *

-foreground => I<color>,

Set color of text value.

Default : B<black>

=item *

-font => I<string>,

Set the font to text value.

  -font  => 'Times 12 {bold}', 

=back

=head2 redraw

Redraw the graph. 

If you have used cleargraph for any reason, it is possible to redraw the graph.
Tk::Chart::Lines supports the configure and cget methods described in the L<Tk::options> manpage.
If you use configure method to change a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, call B<redraw> method to 
resolv the bug.

 ...
 $fenetre->Button(-text => 'Change xlabel', -command => sub { 
   $Chart->configure(-xlabel => 'red'); 
   } 
 )->pack;
 ...
 # xlabel will be changed but not displayed if you not resize the widget.
  
 ...
 $fenetre->Button(
   -text    => 'Change xlabel', 
   -command => sub { 
     $Chart->configure( -xlabel => 'red' ); 
     $Chart->redraw; 
   }, 
 )->pack;
 ...
 # OK, xlabel will be changed and displayed without resize the widget.

=head2 set_balloon

=over 4

=item I<$Chart>->B<set_balloon>(I<? %Options>)

If you call this method, you enable help identification.
When the mouse cursor passes over a plotted line or its entry in the legend, 
the line and its entry will be turn into a color (that you can change) to help the identification. 
B<set_legend> method must be set if you want to enabled identification.

=back

=over 8

=item *

-background => I<string>

Set a background color for the balloon.

 -background => 'red',

Default : B<snow>

=item *

-colordatamouse => I<Array reference>

Specify an array reference wich contains 2 colors. The first color specifies 
the color of the line when mouse cursor passes over an entry in the legend. If the line 
has the same color, the second color will be used.

 -colordatamouse => ['blue', 'green'],

Default : -colordatamouse => B<[ '#7F9010', '#CB89D3' ]>

=item *

-morepixelselected => I<integer>

When the mouse cursor passes over an entry in the legend, 
the line width increase. 

 -morepixelselected => 5,

Default : B<2>


=back

=head2 set_legend

=over 4

=item I<$Chart>->B<set_legend>(I<? %Options>)

View a legend for the graph and allow to enabled identification help by using B<set_balloon> method.

=back

=over 8

=item *

-title => I<string>

Set a title legend.

 -title => 'My title',

Default : B<undef>

=item *

-titlecolors => I<string>

Set a color to legend text.

 -titlecolors => 'red',

Default : B<black>

=item *

-titlefont => I<string>

Set the font to legend title text.

 -titlefont => '{Arial} 8 {normal}',

Default : B<{Times} 8 {bold}>

=item *

-legendcolor => I<color>

Color of legend text.

 -legendcolor => 'white',

Default : B<'black'>

=item *

-legendfont => I<string>

Set the font to legend text.

 -legendfont => '{Arial} 8 {normal}',

Default : B<{Times} 8 {normal}>

=item *

-box => I<boolean>

Set a box around all legend.

 -box => 1, # or 0

Default : B<0>

=item *

-legendmarkerheight => I<integer>

Change the heigth of marker for each legend entry. 

 -legendmarkerheight => 5,

Default : B<10>

=item *

-legendmarkerwidth => I<integer>

Change the width of marker for each legend entry. 

 -legendmarkerwidth => 5,

Default : B<10>

=item *

-heighttitle => I<integer>

Change the height title legend space. 

 -heighttitle => 75,

Default : B<30>

=back

=head2 zoom

Zoom the graph. The x-axis and y-axis will be zoomed. If your graph has a 300*300 
size, after a zoom(200), the graph will have a 600*600 size.

$Chart->zoom(I<$zoom>);

$zoom must be an integer great than 0.

 $Chart->zoom(50); # size divide by 2 => 150*150
 ...
 $Chart->zoom(200); # size multiplie by 2 => 600*600
 ...
 $Chart->zoom(120); # 20% add in each axis => 360*360
 ...
 $Chart->zoom(100); # original resize 300*300. 


=head2 zoomx

Zoom the graph the x-axis.

 # original canvas size 300*300
 $Chart->zoomx(50); # new size : 150*300
 ...
 $Chart->zoom(100); # new size : 300*300

=head2 zoomy

Zoom the graph the y-axis.

 # original canvas size 300*300
 $Chart->zoomy(50); # new size : 300*150
 ...
 $Chart->zoom(100); # new size : 300*300

=head1 EXAMPLES

In the B<demo> directory, you have a lot of script examples with their screenshot. 
See also the L<http://search.cpan.org/dist/Tk-Chart/MANIFEST> web page of L<Tk::Chart>.

=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

See L<Tk::Chart>, L<Tk::Chart::FAQ>, L<GD::Graph>, L<Tk::Graph>, L<Tk::LineGraph>, L<Tk::PlotDataset>

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Tk-Chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart::Lines


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Chart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Chart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Chart>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Chart/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
