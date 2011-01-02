package Tk::Chart::Bars;

use warnings;
use strict;
use Carp;

#==================================================================
# $Author    : Djibril Ousmanou                                   $
# $Copyright : 2011                                               $
# $Update    : 01/01/2011 00:00:00                                $
# $AIM       : Create bars graph                                  $
#==================================================================

use vars qw($VERSION);
$VERSION = '1.03';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Bars';

sub Populate {

  my ( $cw, $ref_parameters ) = @_;

  # Get initial parameters
  $cw->{RefChart} = _initconfig();

  $cw->SUPER::Populate($ref_parameters);

  $cw->Advertise( 'GradientColor' => $cw );
  $cw->Advertise( 'canvas'        => $cw->SUPER::Canvas );
  $cw->Advertise( 'Canvas'        => $cw->SUPER::Canvas );

  # remove highlightthickness if necessary
  if ( !exists $ref_parameters->{-highlightthickness} ) {
    $cw->configure( -highlightthickness => 0 );
  }

  my $ref_configcommon = _get_configspecs();

  # ConfigSpecs
  $cw->ConfigSpecs(

    # Common options
    %{$ref_configcommon},

    -overwrite       => [ 'PASSIVE', 'Overwrite',       'OverWrite',       0 ],
    -cumulate        => [ 'PASSIVE', 'Cumulate',        'Cumulate',        0 ],
    -spacingbar      => [ 'PASSIVE', 'Spacingbar',      'SpacingBar',      1 ],
    -showvalues      => [ 'PASSIVE', 'Showvalues',      'ShowValues',      0 ],
    -barsvaluescolor => [ 'PASSIVE', 'BarsValuescolor', 'BarsValuesColor', 'black' ],
    -outlinebar      => [ 'PASSIVE', 'Outlinebar',      'OutlineBar',      'black' ],
  );

  $cw->Delegates( DEFAULT => $cw, );

  # recreate graph after widget resize
  $cw->enabled_automatic_redraw();
  $cw->disabled_gradientcolor();
  return;
}

sub _balloon {
  my ($cw) = @_;

  # balloon defined and user want to stop it
  if ( defined $cw->{RefChart}->{Balloon}{Obj}
    and $cw->{RefChart}->{Balloon}{State} == 0 )
  {
    $cw->_destroyballoon_bind();
    return;
  }

  # balloon not defined and user want to stop it
  elsif ( $cw->{RefChart}->{Balloon}{State} == 0 ) {
    return;
  }

  # balloon defined and user want to start it again (may be new option)
  elsif ( defined $cw->{RefChart}->{Balloon}{Obj}
    and $cw->{RefChart}->{Balloon}{State} == 1 )
  {

    # destroy the balloon, it will be re create above
    $cw->_destroyballoon_bind();
  }

  # Balloon creation
  $cw->{RefChart}->{Balloon}{Obj} = $cw->Balloon(
    -statusbar  => $cw,
    -background => $cw->{RefChart}->{Balloon}{Background},
  );
  $cw->{RefChart}->{Balloon}{Obj}->attach(
    $cw,
    -balloonposition => 'mouse',
    -msg             => $cw->{RefChart}->{Legend}{MsgBalloon},
  );

  # no legend, no bind
  if ( !$cw->{RefChart}->{Legend}{LegendTextNumber} ) {
    return;
  }

  # bind legend and bars
  for my $index_legend ( 1 .. $cw->{RefChart}->{Legend}{LegendTextNumber} ) {

    my $legend_tag = $index_legend . $cw->{RefChart}->{TAGS}{Legend};
    my $bar_tag    = $index_legend . $cw->{RefChart}->{TAGS}{Bar};

    $cw->bind(
      $legend_tag,
      '<Enter>',
      sub {
        my $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[0];

        # Change color if bar have the same color
        if ( $other_color eq $cw->{RefChart}{Bar}{$bar_tag}{color} ) {
          $other_color = $cw->{RefChart}->{Balloon}{ColorData}->[1];
        }
        $cw->itemconfigure( $bar_tag, -fill => $other_color, );

        # Allow value bar to display
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{BarValues}, -fill => $cw->cget( -barsvaluescolor ), );
      }
    );

    $cw->bind(
      $legend_tag,
      '<Leave>',
      sub {
        $cw->itemconfigure( $bar_tag, -fill => $cw->{RefChart}{Bar}{$bar_tag}{color}, );

        # Allow value bar to display
        $cw->itemconfigure( $cw->{RefChart}->{TAGS}{BarValues}, -fill => $cw->cget( -barsvaluescolor ), );
      }
    );
  }

  return;
}

sub set_legend {
  my ( $cw, %info_legend ) = @_;

  my $ref_legend = $info_legend{-data};
  if ( not defined $ref_legend ) {
    $cw->_error(
      "Can't set -data in set_legend method. May be you forgot to set the value\nEg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  if ( not defined $ref_legend or ref $ref_legend ne 'ARRAY' ) {
    $cw->_error(
      "Can't set -data in set_legend method. Bad data\nEg : set_legend( -data => ['legend1', 'legend2', ...] );",
      1
    );
  }

  my @legend_option = qw / -box -legendmarkerheight -legendmarkerwidth -heighttitle /;
  foreach my $option_name (@legend_option) {
    if ( defined $info_legend{$option_name} and (! _isainteger( $info_legend{$option_name} ) ) ) {
      $cw->_error(
        "'Can't set $option_name to "
          . "'$info_legend{$option_name}', $info_legend{$option_name}' isn't numeric",
        1
      );
    }
  }

  # Check legend and data size
  if ( my $ref_data = $cw->{RefChart}->{Data}{RefAllData} ) {
    if ( !$cw->_checksizelegend_data( $ref_data, $ref_legend ) ) {
      undef $cw->{RefChart}->{Legend}{DataLegend};
      return;
    }
  }

  # Get Legend options
  # Title
  if ( defined $info_legend{-title} ) {
    $cw->{RefChart}->{Legend}{title} = $info_legend{-title};
  }
  else {
    undef $cw->{RefChart}->{Legend}{title};
    $cw->{RefChart}->{Legend}{HeightTitle} = 0;
  }

  # Title and legend font
  if ( defined $info_legend{-titlefont} ) {
    $cw->{RefChart}->{Legend}{titlefont} = $info_legend{-titlefont};
  }
  if ( defined $info_legend{-legendfont} ) {
    $cw->{RefChart}->{Legend}{legendfont} = $info_legend{-legendfont};
  }

  # box legend
  if ( defined $info_legend{-box} ) {
    $cw->{RefChart}->{Legend}{box} = $info_legend{-box};
  }

  # title color
  if ( defined $info_legend{-titlecolors} ) {
    $cw->{RefChart}->{Legend}{titlecolors} = $info_legend{-titlecolors};
  }

  # text color
  if ( defined $info_legend{-legendcolor} ) {
    $cw->{RefChart}->{Legend}{legendcolor} = $info_legend{-legendcolor};
  }

  # legendmarkerheight
  if ( defined $info_legend{-legendmarkerheight} ) {
    $cw->{RefChart}->{Legend}{HCube} = $info_legend{-legendmarkerheight};
  }

  # legendmarkerwidth
  if ( defined $info_legend{-legendmarkerwidth} ) {
    $cw->{RefChart}->{Legend}{WCube} = $info_legend{-legendmarkerwidth};
  }

  # heighttitle
  if ( defined $info_legend{-heighttitle} ) {
    $cw->{RefChart}->{Legend}{HeightTitle} = $info_legend{-heighttitle};
  }

  # Get the biggest length of legend text
  my @length_legend = map { length; } @{$ref_legend};
  my $biggest_legend = _maxarray( \@length_legend );

  # 100 pixel =>  13 characters, 1 pixel =>  0.13 pixels then 1 character = 7.69 pixels
  $cw->{RefChart}->{Legend}{WidthOneCaracter} = 7.69;

  # Max pixel width for a legend text for us
  $cw->{RefChart}->{Legend}{LengthTextMax}
    = int( $cw->{RefChart}->{Legend}{WidthText} / $cw->{RefChart}->{Legend}{WidthOneCaracter} );

  # We have free space
  my $diff = $cw->{RefChart}->{Legend}{LengthTextMax} - $biggest_legend;

  # Get new size width for a legend text with one pixel security
  $cw->{RefChart}->{Legend}{WidthText} -= ( $diff - 1 ) * $cw->{RefChart}->{Legend}{WidthOneCaracter};

  # Store Reference data
  $cw->{RefChart}->{Legend}{DataLegend} = $ref_legend;
  $cw->{RefChart}->{Legend}{NbrLegend}  = scalar @{$ref_legend};

  return 1;
}

sub _legend {
  my ( $cw, $ref_legend ) = @_;

  # One legend width
  $cw->{RefChart}->{Legend}{LengthOneLegend}
    = +$cw->{RefChart}->{Legend}{SpaceBeforeCube}    # space between each legend
    + $cw->{RefChart}->{Legend}{WCube}               # width legend marker
    + $cw->{RefChart}->{Legend}{SpaceAfterCube}      # space after marker
    + $cw->{RefChart}->{Legend}{WidthText}           # legend text width allowed
    ;

  # Number of legends per line
  $cw->{RefChart}->{Legend}{NbrPerLine}
    = int( $cw->{RefChart}->{Axis}{Xaxis}{Width} / $cw->{RefChart}->{Legend}{LengthOneLegend} );
  if ( $cw->{RefChart}->{Legend}{NbrPerLine} == 0 ) { $cw->{RefChart}->{Legend}{NbrPerLine} = 1; }

  # How many legend we will have
  $cw->{RefChart}->{Legend}{LegendTextNumber} = scalar @{ $cw->{RefChart}->{Data}{RefAllData} } - 1;

=for NumberLines:
  We calculate the number of lines set for the legend graph.
  If wa can set 11 legends per line, then for 3 legend, we will need one line
  and for 12 legends, we will need 2 lines
  If NbrLeg / NbrPerLine = integer => get number of lines
  If NbrLeg / NbrPerLine = float => int(float) + 1 = get number of lines

=cut

  $cw->{RefChart}->{Legend}{NbrLine}
    = $cw->{RefChart}->{Legend}{LegendTextNumber} / $cw->{RefChart}->{Legend}{NbrPerLine};
  if ( int( $cw->{RefChart}->{Legend}{NbrLine} ) != $cw->{RefChart}->{Legend}{NbrLine} ) {
    $cw->{RefChart}->{Legend}{NbrLine} = int( $cw->{RefChart}->{Legend}{NbrLine} ) + 1;
  }

  # Total Height of Legend
  $cw->{RefChart}->{Legend}{Height} = $cw->{RefChart}->{Legend}{HeightTitle}    # Hauteur Titre lÃ©gende
    + $cw->{RefChart}->{Legend}{NbrLine} * $cw->{RefChart}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  if ( $cw->{RefChart}->{Legend}{LegendTextNumber} < $cw->{RefChart}->{Legend}{NbrPerLine} ) {
    $cw->{RefChart}->{Legend}{NbrPerLine} = $cw->{RefChart}->{Legend}{LegendTextNumber};
  }

  return;
}

sub _viewlegend {
  my ($cw) = @_;

  # legend option
  my $legend_title       = $cw->{RefChart}->{Legend}{title};
  my $legendmarkercolors = $cw->cget( -colordata );
  my $legendfont         = $cw->{RefChart}->{Legend}{legendfont};
  my $titlecolor         = $cw->{RefChart}->{Legend}{titlecolors};
  my $titlefont          = $cw->{RefChart}->{Legend}{titlefont};
  my $axiscolor          = $cw->cget( -axiscolor );

  # display legend title
  if ( defined $legend_title ) {
    my $x_legend_title = $cw->{RefChart}->{Axis}{CxMin} + $cw->{RefChart}->{Legend}{SpaceBeforeCube};
    my $y_legend_title
      = $cw->{RefChart}->{Axis}{CyMin} 
      + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
      + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
      + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight};

    $cw->createText(
      $x_legend_title,
      $y_legend_title,
      -text   => $legend_title,
      -anchor => 'nw',
      -font   => $titlefont,
      -fill   => $titlecolor,
      -width  => $cw->{RefChart}->{Axis}{Xaxis}{Width},
      -tags   => [ $cw->{RefChart}->{TAGS}{TitleLegend}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    );
  }

  # Display legend
  my $index_color  = 0;
  my $index_legend = 0;

  # initialisation of balloon message
  #$cw->{RefChart}->{Legend}{MsgBalloon} = {};
  for my $number_line ( 0 .. $cw->{RefChart}->{Legend}{NbrLine} - 1 ) {
    my $x1_cube = $cw->{RefChart}->{Axis}{CxMin} + $cw->{RefChart}->{Legend}{SpaceBeforeCube};
    my $y1_cube
      = ( $cw->{RefChart}->{Axis}{CyMin} 
        + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
        + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
        + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight}
        + $cw->{RefChart}->{Legend}{HeightTitle}
        + $cw->{RefChart}->{Legend}{HLine} / 2 )
      + $number_line * $cw->{RefChart}->{Legend}{HLine};

    my $x2_cube    = $x1_cube + $cw->{RefChart}->{Legend}{WCube};
    my $y2_cube    = $y1_cube - $cw->{RefChart}->{Legend}{HCube};
    my $xtext      = $x2_cube + $cw->{RefChart}->{Legend}{SpaceAfterCube};
    my $ytext      = $y2_cube;
    my $max_length = $cw->{RefChart}->{Legend}{LengthTextMax};

  LEGEND:
    for my $number_leg_in_line ( 0 .. $cw->{RefChart}->{Legend}{NbrPerLine} - 1 ) {

      my $line_color = $legendmarkercolors->[$index_color];
      if ( not defined $line_color ) {
        $index_color = 0;
        $line_color  = $legendmarkercolors->[$index_color];
      }

      # Cut legend text if too long
      my $legend = $cw->{RefChart}->{Legend}{DataLegend}->[$index_legend];
      next if ( not defined $legend );
      my $new_legend = $legend;

      if ( length $new_legend > $max_length ) {
        $max_length -= 3;
        $new_legend =~ s/^(.{$max_length}).*/$1/;
        $new_legend .= '...';
      }

      my $tag = ( $index_legend + 1 ) . $cw->{RefChart}->{TAGS}{Legend};
      $cw->createRectangle(
        $x1_cube, $y1_cube, $x2_cube, $y2_cube,
        -fill    => $line_color,
        -outline => $line_color,
        -tags    => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
      );

      my $id = $cw->createText(
        $xtext, $ytext,
        -text   => $new_legend,
        -anchor => 'nw',
        -tags   => [ $tag, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
        -fill   => $cw->{RefChart}->{Legend}{legendcolor},
      );
      if ($legendfont) {
        $cw->itemconfigure( $id, -font => $legendfont, );
      }

      $index_color++;
      $index_legend++;

      # cube
      $x1_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};
      $x2_cube += $cw->{RefChart}->{Legend}{LengthOneLegend};

      # Text
      $xtext += $cw->{RefChart}->{Legend}{LengthOneLegend};
      my $bar_tag = $index_legend . $cw->{RefChart}->{TAGS}{Bar};
      $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag} = $legend;

      #$cw->{RefChart}->{Legend}{MsgBalloon}->{$bar_tag}        = $legend;

      if ( $index_legend == $cw->{RefChart}->{Legend}{LegendTextNumber} ) {
        last LEGEND;
      }
    }
  }

  # box legend
  my $x1box = $cw->{RefChart}->{Axis}{CxMin};
  my $y1box
    = $cw->{RefChart}->{Axis}{CyMin} 
    + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}
    + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}
    + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight};
  my $x2box = $x1box + ( $cw->{RefChart}->{Legend}{NbrPerLine} * $cw->{RefChart}->{Legend}{LengthOneLegend} );

  # Reajuste box if width box < legend title text
  my @info_legend_title = $cw->bbox( $cw->{RefChart}->{TAGS}{TitleLegend} );
  if ( $info_legend_title[2] and $x2box <= $info_legend_title[2] ) {
    $x2box = $info_legend_title[2] + 2;
  }
  my $y2box = $y1box + $cw->{RefChart}->{Legend}{Height};
  $cw->createRectangle(
    $x1box, $y1box, $x2box, $y2box,
    -tags    => [ $cw->{RefChart}->{TAGS}{BoxLegend}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
    -outline => $axiscolor,
  );

  return;
}

sub _axis {
  my ($cw) = @_;

  my $axiscolor = $cw->cget( -axiscolor );

  # x-axis width
  $cw->{RefChart}->{Axis}{Xaxis}{Width}
    = $cw->{RefChart}->{Canvas}{Width}
    - ( 2 * $cw->{RefChart}->{Canvas}{WidthEmptySpace} 
      + $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
      + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
      + $cw->{RefChart}->{Axis}{Yaxis}{TickWidth} );

  # get Height legend
  if ( $cw->{RefChart}->{Legend}{NbrLegend} > 0 ) {
    $cw->_legend( $cw->{RefChart}->{Legend}{DataLegend} );
  }

  # Height y-axis
  $cw->{RefChart}->{Axis}{Yaxis}{Height} = $cw->{RefChart}->{Canvas}{Height}    # Largeur canvas
    - (
    2 * $cw->{RefChart}->{Canvas}{HeightEmptySpace}                             # 2 fois les espace vides
      + $cw->{RefChart}->{Title}{Height}                                        # Hauteur du titre
      + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight}                              # Hauteur tick (axe x)
      + $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight}                       # Hauteur valeurs axe
      + $cw->{RefChart}->{Axis}{Xaxis}{xlabelHeight}                            # Hauteur x label
      + $cw->{RefChart}->{Legend}{Height}                                       # Hauteur lÃ©gende
    );

  #===========================
  # Y axis
  # Set 2 points (CxMin, CyMin) et (CxMin, CyMax)
  $cw->{RefChart}->{Axis}{CxMin}                                                # CoordonnÃ©es CxMin
    = $cw->{RefChart}->{Canvas}{WidthEmptySpace}                                # Largeur vide
    + $cw->{RefChart}->{Axis}{Yaxis}{ylabelWidth}                               # Largeur label y
    + $cw->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}                          # Largeur valeur axe y
    + $cw->{RefChart}->{Axis}{Yaxis}{TickWidth};                                # Largeur tick axe y

  $cw->{RefChart}->{Axis}{CyMax}                                                # CoordonnÃ©es CyMax
    = $cw->{RefChart}->{Canvas}{HeightEmptySpace}                               # Hauteur vide
    + $cw->{RefChart}->{Title}{Height}                                          # Hauteur titre
    ;

  $cw->{RefChart}->{Axis}{CyMin}                                                # CoordonnÃ©es CyMin
    = $cw->{RefChart}->{Axis}{CyMax}                                            # CoordonnÃ©es CyMax (haut)
    + $cw->{RefChart}->{Axis}{Yaxis}{Height}                                    # Hauteur axe Y
    ;

  # display Y axis
  $cw->createLine(
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMin},
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMax},
    -tags => [
      $cw->{RefChart}->{TAGS}{yAxis}, $cw->{RefChart}->{TAGS}{AllAXIS},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  #===========================
  # X axis
  # Set 2 points (CxMin,CyMin) et (CxMax,CyMin)
  # ou (Cx0,Cy0) et (CxMax,Cy0)
  $cw->{RefChart}->{Axis}{CxMax} = $cw->{RefChart}->{Axis}{CxMin} + $cw->{RefChart}->{Axis}{Xaxis}{Width};

  # Bottom x-axis
  $cw->createLine(
    $cw->{RefChart}->{Axis}{CxMin},
    $cw->{RefChart}->{Axis}{CyMin},
    $cw->{RefChart}->{Axis}{CxMax},
    $cw->{RefChart}->{Axis}{CyMin},
    -tags => [
      $cw->{RefChart}->{TAGS}{xAxis}, $cw->{RefChart}->{TAGS}{AllAXIS},
      $cw->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # POINT (0,0)
  $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit}    # Height unit for value = 1
    = $cw->{RefChart}->{Axis}{Yaxis}{Height}
    / ( $cw->{RefChart}->{Data}{MaxYValue} - $cw->{RefChart}->{Data}{MinYValue} );

  # min positive value >= 0
  if ( $cw->{RefChart}->{Data}{MinYValue} >= 0 ) {
    $cw->{RefChart}->{Axis}{Cx0} = $cw->{RefChart}->{Axis}{CxMin};
    $cw->{RefChart}->{Axis}{Cy0} = $cw->{RefChart}->{Axis}{CyMin};
  }

  # min positive value < 0
  else {
    $cw->{RefChart}->{Axis}{Cx0} = $cw->{RefChart}->{Axis}{CxMin};
    $cw->{RefChart}->{Axis}{Cy0} = $cw->{RefChart}->{Axis}{CyMin}
      + ( $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} * $cw->{RefChart}->{Data}{MinYValue} );

    # X Axis (0,0)
    $cw->createLine(
      $cw->{RefChart}->{Axis}{Cx0},
      $cw->{RefChart}->{Axis}{Cy0},
      $cw->{RefChart}->{Axis}{CxMax},
      $cw->{RefChart}->{Axis}{Cy0},
      -tags => [
        $cw->{RefChart}->{TAGS}{xAxis0}, $cw->{RefChart}->{TAGS}{AllAXIS},
        $cw->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $axiscolor,
    );
  }

  return;
}

sub _xtick {
  my ($cw) = @_;

  my $xvaluecolor = $cw->cget( -xvaluecolor );
  my $longticks   = $cw->cget( -longticks );

  # x coordinates y ticks on bottom x-axis
  my $x_tickx1 = $cw->{RefChart}->{Axis}{CxMin};
  my $x_ticky1 = $cw->{RefChart}->{Axis}{CyMin};

  # x coordinates y ticks on 0,0 x-axis if the graph have only y value < 0
  if (  $cw->cget( -zeroaxisonly ) == 1
    and $cw->{RefChart}->{Data}{MaxYValue} > 0 )
  {
    $x_ticky1 = $cw->{RefChart}->{Axis}{Cy0};
  }

  my $x_tickx2 = $x_tickx1;
  my $x_ticky2 = $x_ticky1 + $cw->{RefChart}->{Axis}{Xaxis}{TickHeight};

  # Coordinates of x values (first value)
  my $xtick_xvalue
    = $cw->{RefChart}->{Axis}{CxMin} + ( $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 2 );
  my $xtick_yvalue = $x_ticky2 + ( $cw->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} / 2 );
  my $nbrleg = scalar( @{ $cw->{RefChart}->{Data}{RefXLegend} } );

  my $xlabelskip = $cw->cget( -xlabelskip );

  # index of tick and vlaues that will be skip
  my %indice_skip;
  if ( defined $xlabelskip ) {
    for ( my $i = 1; $i <= $nbrleg; $i++ ) {
      $indice_skip{$i} = 1;
      $i += $xlabelskip;
    }
  }

  for ( my $indice = 1; $indice <= $nbrleg; $indice++ ) {
    my $data = $cw->{RefChart}->{Data}{RefXLegend}->[ $indice - 1 ];

    # tick
    $x_tickx1 += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
    $x_tickx2 = $x_tickx1;

    # tick legend
    my $regex_xtickselect = $cw->cget( -xvaluesregex );

    if ( $data =~ m{$regex_xtickselect} ) {
      next if ( not defined $indice_skip{$indice} );

      # Display xticks short or long
      $cw->_display_xticks( $x_tickx1, $x_ticky1, $x_tickx2, $x_ticky2 );

      if (  defined $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
        and defined $cw->{RefChart}->{Legend}{WidthOneCaracter} )
      {
        my $max_length    = $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
        my $width_data    = $cw->{RefChart}->{Legend}{WidthOneCaracter} * length $data;
        my $nbr_character = int( $max_length / $cw->{RefChart}->{Legend}{WidthOneCaracter} );
        if ( defined $max_length and $width_data > $max_length ) {
          $data =~ s/^(.{$nbr_character}).*/$1/;
          $data .= '...';
        }
      }

      $cw->createText(
        $xtick_xvalue,
        $xtick_yvalue,
        -text => $data,
        -fill => $xvaluecolor,
        -tags => [
          $cw->{RefChart}->{TAGS}{xValues}, $cw->{RefChart}->{TAGS}{AllValues},
          $cw->{RefChart}->{TAGS}{AllTagsChart},
        ],
      );
    }
    $xtick_xvalue += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
  }

  return;
}

sub _viewdata {
  my ($cw) = @_;

  my $legendmarkercolors = $cw->cget( -colordata );
  my $overwrite          = $cw->cget( -overwrite );
  my $cumulate           = $cw->cget( -cumulate );
  my $spacingbar         = $cw->cget( -spacingbar );
  my $showvalues         = $cw->cget( -showvalues );
  my $outlinebar         = $cw->cget( -outlinebar );
  my $barsvaluescolor    = $cw->cget( -barsvaluescolor );

  # number of value for x-axis
  $cw->{RefChart}->{Data}{xtickNumber} = $cw->{RefChart}->{Data}{NumberXValues};

  # Space between x ticks
  $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
    = $cw->{RefChart}->{Axis}{Xaxis}{Width} / ( $cw->{RefChart}->{Data}{xtickNumber} + 1 );

  my $id_data     = 0;
  my $index_color = 0;
  my $width_bar = $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / $cw->{RefChart}->{Data}{NumberRealData};

  my @cumulatey = (0) x scalar @{ $cw->{RefChart}->{Data}{RefAllData}->[0] };

  foreach my $ref_array_data ( @{ $cw->{RefChart}->{Data}{RefAllData} } ) {
    if ( $id_data == 0 ) {
      $id_data++;
      next;
    }
    my $number_data = 1;    # Number of data
    foreach my $data ( @{$ref_array_data} ) {
      if ( not defined $data ) {
        push @cumulatey, 0;
        $number_data++;
        next;
      }

      my ( $x, $y, $x0, $y0 ) = ();
      if ( $overwrite == 1 or $cumulate == 1 ) {

        # coordinates x and y values
        $x = $cw->{RefChart}->{Axis}{Cx0} + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
        $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

        # coordinates x0 and y0 values
        $x0 = $x - $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick};
        $y0 = $cw->{RefChart}->{Axis}{Cy0};

        # cumulate bars
        if ( $cumulate == 1 ) {

          $y -= $cumulatey[ $number_data - 1 ];
          $y0 = $y + ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

          $cumulatey[ $number_data - 1 ] += ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
        }

        # space between bars
        if ( $spacingbar == 1 ) {
          $x -= $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 4;
          $x0 += $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick} / 4;
        }
      }

      # No overwrite
      else {
        $x
          = $cw->{RefChart}->{Axis}{Cx0} 
          + $number_data * $cw->{RefChart}->{Axis}{Xaxis}{SpaceBetweenTick}
          - ( ( $cw->{RefChart}->{Data}{NumberRealData} - $id_data ) * $width_bar );
        $y = $cw->{RefChart}->{Axis}{Cy0} - ( $data * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );

        #update=
        if ( $cw->{RefChart}->{Data}{MinYValue} > 0 ) {
          $y += ( $cw->{RefChart}->{Data}{MinYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
        }

        # coordinates x0 and y0 values
        $x0 = $x - $width_bar;
        $y0 = $cw->{RefChart}->{Axis}{Cy0};

        # space between bars
        if ( $spacingbar == 1 ) {
          $x -= $width_bar / 4;
          $x0 += $width_bar / 4;
        }
      }

      #update=
      if ( $cw->{RefChart}->{Data}{MaxYValue} < 0 ) {
        $y0 -= ( $cw->{RefChart}->{Data}{MaxYValue} * $cw->{RefChart}->{Axis}{Yaxis}{HeightUnit} );
      }

      my $line_color = $legendmarkercolors->[$index_color];
      if ( not defined $line_color ) {
        $index_color = 0;
        $line_color  = $legendmarkercolors->[$index_color];
      }
      my $tag  = $id_data . $cw->{RefChart}->{TAGS}{Bar};
      my $tag2 = $id_data . "_$number_data" . $cw->{RefChart}->{TAGS}{Bar};
      $cw->{RefChart}->{Legend}{MsgBalloon}->{$tag2}
        = "Sample : $cw->{RefChart}->{Data}{RefAllData}->[0]->[$number_data-1]\n" . "Value : $data";

      $cw->createRectangle(
        $x0, $y0, $x, $y,
        -fill => $line_color,
        -tags => [
          $tag,                             $tag2,
          $cw->{RefChart}->{TAGS}{AllData}, $cw->{RefChart}->{TAGS}{AllTagsChart},
          $cw->{RefChart}->{TAGS}{AllBars},
        ],
        -width   => $cw->cget( -linewidth ),
        -outline => $outlinebar,
      );
      if ( $showvalues == 1 ) {
        $cw->createText(
          $x0 + ( $x - $x0 ) / 2,
          $y - 8,
          -text => $data,
          -font => $cw->{RefChart}->{Font}{DefaultBarValues},
          -tags => [ $tag, $cw->{RefChart}->{TAGS}{BarValues}, $cw->{RefChart}->{TAGS}{AllTagsChart}, ],
          -fill => $barsvaluescolor,
        );
      }

      $cw->{RefChart}{Bar}{$tag}{color} = $line_color;
      $number_data++;
    }

    $id_data++;
    $index_color++;
  }

  return 1;
}

sub plot {
  my ( $cw, $ref_data, %option ) = @_;

  my $overwrite   = $cw->cget( -overwrite );
  my $cumulate    = $cw->cget( -cumulate );
  my $yticknumber = $cw->cget( -yticknumber );
  my $yminvalue   = $cw->cget( -yminvalue );
  my $ymaxvalue   = $cw->cget( -ymaxvalue );
  my $interval    = $cw->cget( -interval );

  if ( defined $option{-substitutionvalue}
    and _isanumber( $option{-substitutionvalue} ) )
  {
    $cw->{RefChart}->{Data}{SubstitutionValue} = $option{-substitutionvalue};
  }

  $cw->{RefChart}->{Data}{NumberRealData} = scalar( @{$ref_data} ) - 1;

  if ( not defined $ref_data ) {
    $cw->_error('data not defined');
    return;
  }

  if ( scalar @{$ref_data} <= 1 ) {
    $cw->_error('You must have at least 2 arrays');
    return;
  }

  # Check legend and data size
  if ( my $ref_legend = $cw->{RefChart}->{Legend}{DataLegend} ) {
    if ( !$cw->_checksizelegend_data( $ref_data, $ref_legend ) ) {
      undef $cw->{RefChart}->{Legend}{DataLegend};
    }
  }

  # Check array size
  $cw->{RefChart}->{Data}{NumberXValues} = scalar @{ $ref_data->[0] };
  my $i         = 0;
  my @arraytemp = (0) x scalar @{ $ref_data->[0] };
  foreach my $ref_array ( @{$ref_data} ) {
    if ( scalar @{$ref_array} != $cw->{RefChart}->{Data}{NumberXValues} ) {
      $cw->_error( 'Make sure that every array has the ' . 'same size in plot data method', 1 );
      return;
    }

    # Get min and max size
    if ( $i != 0 ) {

      # substitute none real value
      my $j = 0;
      foreach my $data ( @{$ref_array} ) {
        if ( ( defined $data ) and ( !_isanumber($data) ) ) {
          $data = $cw->{RefChart}->{Data}{SubstitutionValue};
        }
        $arraytemp[$j] += $data;    # For cumulate option
        $j++;
      }
      $cw->{RefChart}->{Data}{MaxYValue}
        = _maxarray( [ $cw->{RefChart}->{Data}{MaxYValue}, _maxarray($ref_array) ] );
      $cw->{RefChart}->{Data}{MinYValue}
        = _minarray( [ $cw->{RefChart}->{Data}{MinYValue}, _minarray($ref_array) ] );
    }
    $i++;
  }

  $cw->{RefChart}->{Data}{RefXLegend}  = $ref_data->[0];
  $cw->{RefChart}->{Data}{RefAllData}  = $ref_data;
  $cw->{RefChart}->{Data}{PlotDefined} = 1;

  if ( $cumulate == 1 ) {
    $cw->{RefChart}->{Data}{MaxYValue} = _maxarray( \@arraytemp );
    $cw->{RefChart}->{Data}{MinYValue} = _minarray( \@arraytemp );
  }

  $cw->_manage_minmaxvalues( $yticknumber, $cumulate );
  $cw->_chartconstruction;

  return 1;
}

1;
__END__


=head1 NAME

Tk::Chart::Bars - Extension of Canvas widget to create bars graph. 

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::Chart::Bars;

  my $mw = MainWindow->new(
    -title      => 'Tk::Chart::Bars example',
    -background => 'white',
  );
  my $chart = $mw->Bars(
    -title      => 'My graph title',
    -xlabel     => 'X Label',
    -ylabel     => 'Y Label',
    -background => 'snow',
  )->pack(qw / -fill both -expand 1 /);

  my @data = (
    [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
    [ 1,     2,     5,     6,     3,     1,     1,     3,     4 ],
    [ 4,     2,     5,     2,     3,     5,     7,     9,     12 ],
    [ 1,     2,     12,    6,     3,     5,     1,     23,    5 ]
  );

  # Add a legend to the graph
  my @Legends = ( 'legend 1', 'legend 2', 'legend 3' );
  $chart->set_legend(
    -title       => 'Title legend',
    -data        => \@Legends,
    -titlecolors => 'blue',
  );

  # Add help identification
  $chart->set_balloon();

  # Create the graph
  $chart->plot( \@data );

  MainLoop();

=head1 DESCRIPTION

Tk::Chart::Bars is an extension of the Canvas widget. It is an easy way to build an 
interactive bar graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

You can change the color, font of title, labels (x and y) of the graph.
You can set an interactive legend.  
The axes can be automatically scaled or set by the code. 

When the mouse cursor passes over a bar or its entry in the legend, 
the bar and its entry will be turned to a color (that you can change) to help identify it. 

You can use 3 methods to zoom (vertically, horizontally or both).

=head1 BACKGROUND GRADIENT COLOR

You can set a background gradient color by using all methods of L<Tk::Canvas::GradientColor>. By 
default, it is not enabled.

To enabled background gradient color the first time, you firstly have to call B<enabled_gradientcolor> method and configure 
your color and type of gradient with B<set_gradientcolor>.

  $chart->enabled_gradientcolor();
  $chart->set_gradientcolor(
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

=over 4

=item Name:	B<Overwrite>

=item Class:	B<OverWrite>

=item Switch:	B<-overwrite>

If set to 0, bars of different data sets will be drawn next to each other. 
If set to 1, they will be drawn in front of each other.

 -overwrite => 1, # 0 or 1

Default : B<0>

=item Name:	B<Cumulate>

=item Class:	B<Cumulate>

=item Switch:	B<-cumulate>

If this attribute is set to a true value, the data sets will be cumulated. 
This means that they will be stacked on top of each other. 

A side effect of this is that overwrite will be set to a true value.

If you have negative values in your data sets, setting this option might 
produce odd results. Of course, the graph itself would be quite meaningless.

 -cumulate => 1, # 0 or 1

Default : B<0>

=item Name:	B<Showvalues>

=item Class:	B<ShowValues>

=item Switch:	B<-showvalues>

Set this to 1 to display the value of each data point above the point or bar itself. 
No effort is being made to ensure that there is enough space for the text.

If -overwrite or -cumulate set to 1, the values will not be hide by bars.

 -showvalues => 0, # 0 or 1

Default : B<1>

=item Name:	B<BarsValuescolor>

=item Class:	B<BarsValuesColor>

=item Switch:	B<-barsvaluescolor>

Color of each data point above the bar if -showvalues set to 1.

 -barsvaluescolor => 'white',

Default : B<black>

=item Name:	B<Spacingbar>

=item Class:	B<SpacingBar>

=item Switch:	B<-spacingbar>

Set this to 1 to display remove space between each bar. 

 -spacingbar => 0, # 0 or 1

Default : B<1>

=item Name:	B<Outlinebar>

=item Class:	B<OutlineBar>

=item Switch:	B<-outlinebar>

Change color of border bars.

  -outlinebar => 'blue',

Default : B<'black'>

=back

=head1 WIDGET-SPECIFIC OPTIONS like Tk::Chart::Lines

Many options that allow you to configure your graph as you want, but you can skip  
the default configuration.

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

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 add_data

=over 4

=item I<$chart>->B<add_data>(I<\@NewData, ?$legend>)

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
 $chart->add_data(\@NewData);

If your last graph has a legend, you have to add a legend entry for the new dataset. Otherwise, 
the legend graph will not be display (see below).

=item *

I<$legend>

 my @NewData = (1,10,12,5,4);
 my $legend = 'New data set';
 $chart->add_data(\@NewData, $legend);

=back

=head2 clearchart

=over 4

=item I<$chart>->B<clearchart>

This method allows you to clear the graph. The canvas 
will not be destroy. It's possible to I<redraw> your 
last graph using the I<redraw method>.

=back

=head2 disabled_automatic_redraw

=over 4

=item I<$chart>->B<disabled_automatic_redraw>

When the graph is created and the widget size changes, the graph is automatically re-created. Call this method to avoid resizing.

  $chart->disabled_automatic_redraw;  

=back

=head2 delete_balloon

=over 4

=item I<$chart>->B<delete_balloon>

If you call this method, you disable help identification which has been enabled with set_balloon method.

=back

=head2 enabled_automatic_redraw

=over 4

=item I<$chart>->B<enabled_automatic_redraw>

Use this method to allow your graph to be recreated automatically when the widget size change. When the graph 
is created for the first time, this method is called. 

  $chart->enabled_automatic_redraw;  

=back


=head2 plot

=over 4

=item I<$chart>->B<plot>(I<\@data, ?arg>)

To display your graph the first time, plot the graph by using this method.

=back

=over 8

=item *

I<\@data>

Fill an array of arrays with the x values and the values of the datasets (I<\@data>). 
Make sure that every array have the same size, otherwise Tk::Chart::Bars 
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
 $chart->plot( \@data,
   -substitutionvalue => '12',
 );
  # mistake, -- and NA will be replace by 12

-substitutionvalue have to be a real number (Eg : 12, .25, 02.25, 5.2e+11, ...) 
  

=back

=head2 redraw

Redraw the graph. 

If you have used cleargraph for any reason, it is possible to redraw the graph.
Tk::Chart::Bars supports the configure and cget methods described in the L<Tk::options> manpage.
If you use configure method to change a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, call B<redraw> method to 
resolv the bug.

  ...
  $mw->Button(
  -text    => 'Change xlabel', 
  -command => sub { 
      $chart->configure(-xlabel => 'red'); 
    }, 
  )->pack;
  ...
  # xlabel will be changed but not displayed if you not resize the widget.
    
  ...
  $mw->Button(
    -text => 'Change xlabel', 
    -command => sub { 
      $chart->configure(-xlabel => 'red'); 
      $chart->redraw; 
    } 
  )->pack;
  ...
  # OK, xlabel will be changed and displayed without resize the widget.

=head2 set_balloon

=over 4

=item I<$chart>->B<set_balloon>(I<? %Options>)

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
the color of the line when mouse cursor passes over a entry in the legend. If the line 
has the same color, the second color will be used.

 -colordatamouse => ['blue', 'green'],

Default : -colordatamouse => B<[ '#7F9010', '#CB89D3' ]>

=item *

=back

=head2 set_legend

=over 4

=item I<$chart>->B<set_legend>(I<? %Options>)

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

$chart-E<gt>B<zoom>(I<integer>);

Zoom the graph. The x-axis and y-axis will be zoomed. If your graph has 
a 300*300 size, after a zoom(200), the graph will have a 600*600 size.

  $chart->zoom(50); # size divide by 2 => 150*150
  ...
  $chart->zoom(200); # size multiplie by 2 => 600*600
  ...
  $chart->zoom(120); # 20% add in each axis => 360*360
  ...
  $chart->zoom(100); # original resize 300*300. 


=head2 zoomx

Zoom the graph the x-axis.

 # original canvas size 300*300
 $chart->zoomx(50); # new size : 150*300
 ...
 $chart->zoom(100); # new size : 300*300

=head2 zoomy

Zoom the graph the y-axis.

 # original canvas size 300*300
 $chart->zoomy(50); # new size : 300*150
 ...
 $chart->zoom(100); # new size : 300*300

=head1 EXAMPLES

In the B<demo> directory, you have a lot of script examples with their screenshot. 
See also the L<http://search.cpan.org/dist/Tk-Chart/MANIFEST> web page of L<Tk::Chart>.

=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

See L<Tk::Chart>, L<Tk::Chart::FAQ>, L<GD::Graph>, L<Tk::Graph>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Tk-Chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart::Bars


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

=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2011 Djibril Ousmanou, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
