package Tk::Chart::Pie;

use warnings;
use strict;
use Carp;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 21/09/2010 16:11:01
# AIM       : Create pie graph
#==================================================================

use vars qw($VERSION);
$VERSION = '1.00';

use base qw/ Tk::Derived Tk::Canvas::GradientColor /;
use Tk::Balloon;

use Tk::Chart::Utils qw / :DUMMIES /;
use Tk::Chart qw / :DUMMIES /;

Construct Tk::Widget 'Pie';

sub Populate {

  my ( $CompositeWidget, $RefParameters ) = @_;

  # Get initial parameters
  $CompositeWidget->{RefChart} = $CompositeWidget->_InitConfig();

  $CompositeWidget->SUPER::Populate($RefParameters);

  $CompositeWidget->Advertise( 'GradientColor' => $CompositeWidget );
  $CompositeWidget->Advertise( 'canvas'        => $CompositeWidget->SUPER::Canvas );
  $CompositeWidget->Advertise( 'Canvas'        => $CompositeWidget->SUPER::Canvas );

  # remove highlightthickness if necessary
  unless ( exists $RefParameters->{-highlightthickness} ) {
    $CompositeWidget->configure( -highlightthickness => 0 );
  }

  $CompositeWidget->ConfigSpecs(
    -title      => [ 'PASSIVE', 'Title',      'Title',      undef ],
    -titlecolor => [ 'PASSIVE', 'Titlecolor', 'TitleColor', 'black' ],
    -titlefont => [ 'PASSIVE', 'Titlefont', 'TitleFont', $CompositeWidget->{RefChart}->{Font}{DefaultTitle} ],
    -titleposition => [ 'PASSIVE', 'Titleposition', 'TitlePosition', 'center' ],
    -width  => [ 'SELF', 'width',  'Width',  $CompositeWidget->{RefChart}->{Canvas}{Width} ],
    -height => [ 'SELF', 'height', 'Height', $CompositeWidget->{RefChart}->{Canvas}{Height} ],

    -linewidth  => [ 'PASSIVE', 'Linewidth',  'LineWidth',  2 ],
    -startangle => [ 'PASSIVE', 'Startangle', 'StartAngle', 0 ],
    -colordata  => [ 'PASSIVE', 'Colordata',  'ColorData',  $CompositeWidget->{RefChart}->{Legend}{Colors} ],
  );

  $CompositeWidget->Delegates( DEFAULT => $CompositeWidget, );

  # recreate graph after widget resize
  $CompositeWidget->enabled_automatic_redraw();
  $CompositeWidget->disabled_gradientcolor();
}

sub plot {
  my ( $CompositeWidget, $RefData ) = @_;

  unless ( defined $RefData ) {
    $CompositeWidget->_error('data not defined');
    return;
  }

  unless ( scalar @{$RefData} == 2 ) {
    $CompositeWidget->_error('You must have 2 arrays in data array');
    return;
  }

  # Check array size
  $CompositeWidget->{RefChart}->{Data}{NumberXValues} = scalar @{ $RefData->[0] };
  foreach my $RefArray ( @{$RefData} ) {
    unless ( scalar @{$RefArray} == $CompositeWidget->{RefChart}->{Data}{NumberXValues} ) {
      $CompositeWidget->_error( 'Make sure that every array has the same size in plot data method', 1 );
      return;
    }
  }

  # Check array size
  foreach my $data ( @{ $RefData->[1] } ) {
    if ( defined $data and !_isANumber($data) ) {
      $data = $CompositeWidget->{RefChart}->{Data}{SubstitutionValue};
    }
  }

  $CompositeWidget->{RefChart}->{Data}{MaxValue}    = _MaxArray( $RefData->[1] );
  $CompositeWidget->{RefChart}->{Data}{NbrSlice}    = scalar @{ $RefData->[0] };
  $CompositeWidget->{RefChart}->{Data}{RefAllData}  = $RefData;
  $CompositeWidget->{RefChart}->{Data}{PlotDefined} = 1;

  $CompositeWidget->_ChartConstruction;

  return;
}

sub _titlepie {
  my ($CompositeWidget) = @_;

  my $Title         = $CompositeWidget->cget( -title );
  my $TitleColor    = $CompositeWidget->cget( -titlecolor );
  my $TitleFont     = $CompositeWidget->cget( -titlefont );
  my $titleposition = $CompositeWidget->cget( -titleposition );

  # Title verification
  unless ($Title) {
    $CompositeWidget->{RefChart}->{Title}{Height} = 0;
    return;
  }

  # Space before the title
  my $WidthEmptyBeforeTitle = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace};

  # Coordinates title
  $CompositeWidget->{RefChart}->{Title}{Ctitrex} = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}
    + ( $CompositeWidget->{RefChart}->{Pie}{Width} / 2 );
  $CompositeWidget->{RefChart}->{Title}{Ctitrey} = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}
    + ( $CompositeWidget->{RefChart}->{Title}{Height} / 2 );

  # display title
  my $anchor;
  if ( $titleposition eq 'left' ) {
    $CompositeWidget->{RefChart}->{Title}{Ctitrex}  = $WidthEmptyBeforeTitle;
    $anchor                                         = 'nw';
    $CompositeWidget->{RefChart}->{Title}{'-width'} = 0;
  }
  elsif ( $titleposition eq 'right' ) {
    $CompositeWidget->{RefChart}->{Title}{Ctitrex}
      = $WidthEmptyBeforeTitle + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width};
    $CompositeWidget->{RefChart}->{Title}{'-width'} = 0;
    $anchor = 'ne';
  }
  else {
    $anchor = 'center';
  }
  $CompositeWidget->{RefChart}->{Title}{IdTitre} = $CompositeWidget->createText(
    $CompositeWidget->{RefChart}->{Title}{Ctitrex},
    $CompositeWidget->{RefChart}->{Title}{Ctitrey},
    -text   => $Title,
    -width  => $CompositeWidget->{RefChart}->{Pie}{Width},
    -anchor => $anchor,
    -tags   => [ $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
  );
  return if ( $anchor =~ m{^left|right$} );

  # get title information
  my ($Height);
  ( $CompositeWidget->{RefChart}->{Title}{Ctitrex},
    $CompositeWidget->{RefChart}->{Title}{Ctitrey},
    $CompositeWidget->{RefChart}->{Title}{Width}, $Height
  ) = $CompositeWidget->bbox( $CompositeWidget->{RefChart}->{Title}{IdTitre} );

  # Title too long
  if ( $CompositeWidget->{RefChart}->{Title}{Ctitrey}
    < $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} )
  {

    # delete title
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{Title}{IdTitre} );

    $CompositeWidget->{RefChart}->{Title}{Ctitrex} = $WidthEmptyBeforeTitle;
    $CompositeWidget->{RefChart}->{Title}{Ctitrey} = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}
      + ( $CompositeWidget->{RefChart}->{Title}{Height} / 2 );

    # cut title
    $CompositeWidget->{RefChart}->{Title}{'-width'} = 0;

    # display title
    $CompositeWidget->{RefChart}->{Title}{IdTitre} = $CompositeWidget->createText(
      $CompositeWidget->{RefChart}->{Title}{Ctitrex},
      $CompositeWidget->{RefChart}->{Title}{Ctitrey},
      -text   => $Title,
      -width  => $CompositeWidget->{RefChart}->{Title}{'-width'},
      -anchor => 'nw',
      -tags   => [ $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
    );
  }

  $CompositeWidget->itemconfigure(
    $CompositeWidget->{RefChart}->{Title}{IdTitre},
    -font => $TitleFont,
    -fill => $TitleColor,
  );

  return;
}

sub _ViewData {
  my ($CompositeWidget) = @_;

  my $legendmarkercolors = $CompositeWidget->cget( -colordata );

  # Height legend
  $CompositeWidget->_Legend();

  # Coordinates for rectangle pie
  $CompositeWidget->{RefChart}->{Pie}{x1} = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace};
  $CompositeWidget->{RefChart}->{Pie}{y1}
    = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $CompositeWidget->{RefChart}->{Title}{Height}
    + $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace};

  $CompositeWidget->{RefChart}->{Pie}{x2}
    = $CompositeWidget->{RefChart}->{Pie}{x1} + $CompositeWidget->{RefChart}->{Pie}{Width};

  $CompositeWidget->{RefChart}->{Pie}{y2}
    = $CompositeWidget->{RefChart}->{Canvas}{Height}
    - ( 2 * $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace} )
    - $CompositeWidget->{RefChart}->{Legend}{Height};

  # Calculate the number of degrees for value = 1
  my $Somme = 0;
  foreach my $data ( @{ $CompositeWidget->{RefChart}->{Data}{RefAllData}->[1] } ) {
    $Somme += $data;
  }
  $CompositeWidget->{RefChart}->{Pie}{DegreeOneValue} = 360 / $Somme;

  # pie
  my ( $degrees, $start ) = ( 0, $CompositeWidget->cget( -startangle ) );
  my $IndiceColor = 0;
  my $IndexLegend = 0;
  for my $Indice ( 0 .. $CompositeWidget->{RefChart}->{Data}{NbrSlice} - 1 ) {
    my $Value = $CompositeWidget->{RefChart}->{Data}{RefAllData}->[1]->[$Indice];
    $degrees = $CompositeWidget->{RefChart}->{Pie}{DegreeOneValue} * $Value;

    my $Color = $legendmarkercolors->[$IndiceColor];
    unless ( defined $Color ) {
      $IndiceColor = 0;
      $Color       = $legendmarkercolors->[$IndiceColor];
    }
    my $tag
      = $IndexLegend
      . $CompositeWidget->{RefChart}->{TAGS}{Legend}
      . $CompositeWidget->{RefChart}->{TAGS}{Pie};
    $CompositeWidget->createArc(
      $CompositeWidget->{RefChart}->{Pie}{x1},
      $CompositeWidget->{RefChart}->{Pie}{y1},
      $CompositeWidget->{RefChart}->{Pie}{x2},
      $CompositeWidget->{RefChart}->{Pie}{y2},
      -extent => $degrees,
      -fill   => $Color,
      -start  => $start,
      -tags   => [ $tag, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
      -width  => $CompositeWidget->cget( -linewidth ),
    );

    $CompositeWidget->{RefChart}{Pie}{$tag}{color} = $Color;
    $CompositeWidget->{RefChart}{Pie}{$tag}{percent}
      = "$Value (" . _roundValue( ( $Value * 100 ) / $Somme ) . '%)';

    $start += $degrees;
    $IndiceColor++;
    $IndexLegend++;

  }

  return 1;
}

sub _CheckHeightPie {
  my ($CompositeWidget) = @_;

  my $total
    = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $CompositeWidget->{RefChart}->{Title}{Height}
    + ( 2 * $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} )
    + $CompositeWidget->{RefChart}->{Legend}{Height}
    + $CompositeWidget->{RefChart}->{Title}{Height};
  while ( $total > $CompositeWidget->{RefChart}->{Canvas}{Height} ) {
    $CompositeWidget->{RefChart}->{Canvas}{Height} += $CompositeWidget->{RefChart}->{Legend}{Height};

    $CompositeWidget->configure( -height => $CompositeWidget->{RefChart}->{Canvas}{Height} );
  }

  return;
}

sub _Legend {
  my ($CompositeWidget) = @_;

SETLEGEND:

  # One legend width
  $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend}
    = +$CompositeWidget->{RefChart}->{Legend}{SpaceBeforeCube}    # Espace entre chaque légende
    + $CompositeWidget->{RefChart}->{Legend}{WCube}               # Cube (largeur)
    + $CompositeWidget->{RefChart}->{Legend}{SpaceAfterCube}      # Espace apres cube
    + $CompositeWidget->{RefChart}->{Legend}{WidthText}           # longueur du texte de la légende
    ;

  # Number of legends per line
  $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} = int(
    $CompositeWidget->{RefChart}->{Pie}{Width} / $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend} );

  if ( $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} == 0 ) {
    $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} = 1;
  }

  # Number of legends (total)
  $CompositeWidget->{RefChart}->{Legend}{NbrLegend}
    = scalar @{ $CompositeWidget->{RefChart}->{Data}{RefAllData}->[0] };

=for NumberLines:
  We calculate the number of lines set for the legend graph.
  If wa can set 11 legends per line, then for 3 legend, we will need one line
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
    = $CompositeWidget->{RefChart}->{Legend}{NbrLine} * $CompositeWidget->{RefChart}->{Legend}{HLine};

  # Get number legend text max per line to reajust our graph
  $CompositeWidget->{RefChart}->{Legend}{CurrentNbrPerLine}
    = $CompositeWidget->{RefChart}->{Legend}{NbrPerLine};
  if (
    $CompositeWidget->{RefChart}->{Legend}{NbrLegend} < $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} )
  {
    $CompositeWidget->{RefChart}->{Legend}{CurrentNbrPerLine}
      = $CompositeWidget->{RefChart}->{Legend}{NbrLegend};

  }

  # Get the biggest length of legend text
  my @LengthLegend = map { length; } @{ $CompositeWidget->{RefChart}->{Data}{RefAllData}->[0] };
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
  if ( $Diff > 1 ) {
    $CompositeWidget->{RefChart}->{Legend}{WidthText}
      -= ( $Diff - 1 ) * $CompositeWidget->{RefChart}->{Legend}{WidthOneCaracter};
    goto SETLEGEND;
  }

  $CompositeWidget->_CheckHeightPie();

  return;
}

sub _ViewLegend {
  my ($CompositeWidget) = @_;

  my $legendmarkercolors = $CompositeWidget->cget( -colordata );

  my $IndexColor  = 0;
  my $IndexLegend = 0;

  # Balloon
  my %MsgBalloon;

  for my $NumberLine ( 0 .. $CompositeWidget->{RefChart}->{Legend}{NbrLine} ) {
    my $x1Cube = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}
      + $CompositeWidget->{RefChart}->{Legend}{SpaceBeforeCube};

    my $y1Cube
      = $CompositeWidget->{RefChart}->{Pie}{y2} 
      + $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}
      + ( $NumberLine * $CompositeWidget->{RefChart}->{Legend}{HLine} );

    my $x2Cube    = $x1Cube + $CompositeWidget->{RefChart}->{Legend}{WCube};
    my $y2Cube    = $y1Cube - $CompositeWidget->{RefChart}->{Legend}{HCube};
    my $xText     = $x2Cube + $CompositeWidget->{RefChart}->{Legend}{SpaceAfterCube};
    my $yText     = $y2Cube;
    my $MaxLength = $CompositeWidget->{RefChart}->{Legend}{LengthTextMax};

  LEGEND:
    for my $NumberLegInLine ( 0 .. $CompositeWidget->{RefChart}->{Legend}{NbrPerLine} - 1 ) {
      last LEGEND
        unless ( defined $CompositeWidget->{RefChart}->{Data}{RefAllData}->[0]->[$IndexLegend] );
      my $LineColor = $legendmarkercolors->[$IndexColor];
      unless ( defined $LineColor ) {
        $IndexColor = 0;
        $LineColor  = $legendmarkercolors->[$IndexColor];
      }
      my $Tag = $IndexLegend . $CompositeWidget->{RefChart}->{TAGS}{Legend};

      $CompositeWidget->createRectangle(
        $x1Cube, $y1Cube, $x2Cube, $y2Cube,
        -fill    => $LineColor,
        -outline => $LineColor,
        -tags    => [ $Tag, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
      );

      # Cut legend text if too long
      my $Legende   = $CompositeWidget->{RefChart}->{Data}{RefAllData}->[0]->[$IndexLegend];
      my $NewLegend = $Legende;
      if ( length $NewLegend > $MaxLength ) {
        $MaxLength -= 3;
        $NewLegend =~ s/^(.{$MaxLength}).*/$1/;
        $NewLegend .= '...';
      }

      my $Id = $CompositeWidget->createText(
        $xText, $yText,
        -text   => $NewLegend,
        -anchor => 'nw',
        -tags   => [ $Tag, $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
      );

      $IndexColor++;
      $IndexLegend++;

      # cube
      $x1Cube += $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend};
      $x2Cube += $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend};

      # Text
      $xText += $CompositeWidget->{RefChart}->{Legend}{LengthOneLegend};

      my $PieTag = $Tag . $CompositeWidget->{RefChart}->{TAGS}{Pie};
      $CompositeWidget->bind(
        $Tag,
        '<Enter>',
        sub {
          my $OtherColor = $CompositeWidget->{RefChart}->{Balloon}{ColorData}->[0];
          if ( $OtherColor eq $CompositeWidget->{RefChart}{Pie}{$PieTag}{color} ) {
            $OtherColor = $CompositeWidget->{RefChart}->{Balloon}{ColorData}->[1];
          }
          $CompositeWidget->itemconfigure( $PieTag, -fill => $OtherColor, );
        }
      );

      $CompositeWidget->bind(
        $Tag,
        '<Leave>',
        sub {
          $CompositeWidget->itemconfigure( $PieTag,
            -fill => $CompositeWidget->{RefChart}{Pie}{$PieTag}{color}, );
        }
      );

      $MsgBalloon{$Tag}    = "$Legende - " . $CompositeWidget->{RefChart}{Pie}{$PieTag}{percent};
      $MsgBalloon{$PieTag} = "$Legende - " . $CompositeWidget->{RefChart}{Pie}{$PieTag}{percent};

    }
  }

  #Balloon
  unless ( defined $CompositeWidget->{RefChart}->{Balloon}{Obj} ) {
    $CompositeWidget->{RefChart}->{Balloon}{Obj} = $CompositeWidget->Balloon(
      -statusbar  => $CompositeWidget,
      -background => $CompositeWidget->{RefChart}->{Balloon}{Background},
    );

    $CompositeWidget->{RefChart}->{Balloon}{Obj}->attach(
      $CompositeWidget,
      -balloonposition => 'mouse',
      -msg             => \%MsgBalloon,
    );
  }

  return;
}

1;

__END__

=head1 NAME

Tk::Chart::Pie - Extension of Canvas widget to create a pie graph. 

=head1 DESCRIPTION

Tk::Chart::Pie is an extension of the Canvas widget. It is an easy way to build an 
interactive pie graph into your Perl Tk widget. The module is written entirely in Perl/Tk.

You can set a background gradient color.

When the mouse cursor passes over a pie slice or its entry in the legend, 
the pie slice turn to a color (that you can change) and a balloon box display to help identify it. 

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

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Tk;
  use Tk::Chart::Pie;
  my $mw = new MainWindow( -title => 'Tk::Chart::Pie example', );

  my $Chart = $mw->Pie(
    -title      => 'CPAN mirrors around the World',
    -background => 'white',
    -linewidth  => 2,
  )->pack(qw / -fill both -expand 1 /);

  my @data = (
    [ 'Europe', 'Asia', 'Africa', 'Oceania', 'Americas' ],
    [ 97,       33,     3,        6,         61 ],
  );

  $Chart->plot( \@data );

  MainLoop();

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

=over 4

=item Name:	B<Title>

=item Class:	B<Title>

=item Switch:	B<-title>

Title of your graph.
  
 -title => 'My pie graph title',

Default : B<undef>

=item Name:	B<Titleposition>

=item Class:	B<TitlePosition>

=item Switch:	B<-titleposition>

Position of title : B<center>, B<left> or B<right>
  
 -titleposition => 'left',

Default : B<center>

=item Name:	B<Titlecolor>

=item Class:	B<TitleColor>

=item Switch:	B<-titlecolor>

Title color of your graph.
  
 -titlecolor => 'red',

Default : B<black>

=item Name:	B<Titlefont>

=item Class:	B<TitleFont>

=item Switch:	B<-titlefont>

Set the font for the title text. See also textfont option. 
  
 -titlefont => 'Times 15 {normal}',

Default : B<{Times} 12 {bold}>

=item Name:	B<Titleheight>

=item Class:	B<TitleHeight>

=item Switch:	B<-titleheight>

Height for title graph space.
  
 -titleheight => 100,

Default : B<40>

=item Name:	B<Linewidth>

=item Class:	B<LineWidth>

=item Switch:	B<-linewidth>

Set width of all lines slice pie inthe graph.
 
 -linewidth => 10,

Default : B<1>

=item Name:	B<Colordata>

=item Class:	B<ColorData>

=item Switch:	B<-colordata>

This controls the colors of the lines. This should be a reference to an array of color names.
 
 -colordata => [ qw(green pink blue cyan) ],

Default : 

  [ 'red',     'green',   'blue',    'yellow',  'purple',  'cyan',
    '#996600', '#99A6CC', '#669933', '#929292', '#006600', '#FFE100',
    '#00A6FF', '#009060', '#B000E0', '#A08000', 'orange',  'brown',
    'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
  ],

The default array contain 24 colors. If you have more than 24 samples, the next line 
will have the color of the first array case (red).

=item Name:	B<Startangle>

=item Class:	B<StartAngle>

=item Switch:	B<-startangle>

The angle at which the first data slice will be displayed, with 0 degrees being "3 o'clock".

 -startangle => 90,

Default : B<0>

=back

=head1 WIDGET METHODS

The Canvas method creates a widget object. This object supports the 
configure and cget methods described in Tk::options which can be used 
to enquire and modify the options described above. 

=head2 disabled_automatic_redraw

=over 4

=item I<$Chart>->B<disabled_automatic_redraw>

When the graph is created and the widget size changes, the graph is automatically re-created. Call this method to avoid resizing.

  $Chart->disabled_automatic_redraw;  

=back

=head2 enabled_automatic_redraw

=over 4

=item I<$Chart>->B<enabled_automatic_redraw>

Use this method to allow your graph to be recreated automatically when the widget size change. When the graph 
is created for the first time, this method is called. 

  $Chart->enabled_automatic_redraw;  

=back

=head2 clearchart

=over 4

=item I<$PieChart>->B<clearchart>

This method allows you to clear the graph. The canvas 
will not be destroy. It's possible to I<redraw> your 
last graph using the I<redraw method>.

=back

=head2 plot

=over 4

=item I<$PieChart>->B<plot>(I<\@data, ?arg>)

Use this method to create your pie graph.

=back

=over 8

=item *

I<\@data>

Fill an array of arrays with the legend values and the values of the datasets (I<\@data>). 
Make sure that every array have the same size, otherwise Tk::Chart::Pie 
will complain and refuse to compile the graph.

 my @data = (
     [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
     [ 1,     2,     52,    6,     3,     17.5,  1,     43,    10 ]
 );

@data have to contain two arrays, the legend values and the values of the datasets.

If you don't have a value for a point in a dataset, you can use undef, 
and the point will be skipped.

 [ 1,     undef,     5,     6,     3,     1.5,   undef,     3,     4 ]


=item *

-substitutionvalue => I<real number>,

If you have a no real number value in a dataset, it will be replaced by a constant value.

Default : B<0>


 my @data = (
      [ '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th' ],
      [ 1,     '--',     5,     6,     3,     1.5,   1,     3,     4 ],
 );
 $PieChart->plot( \@data,
   -substitutionvalue => '12',
 );
  # mistake, -- and NA will be replace by 12

-substitutionvalue have to be a real number (ex : 12, .25, 02.25, 5.2e+11, etc ...) 
  

=back

=head2 redraw

Redraw the graph. 

If you have used clearchart for any reason, it is possible to redraw the graph.
Tk::Chart::Pie supports the configure and cget methods described in the L<Tk::options> manpage.
If you use configure method to change a widget specific option, the modification will not be display. 
If the graph was already displayed and if you not resize the widget, call B<redraw> method to 
resolv the bug.

 ...
 $fenetre->Button(-text => 'Change title', -command => sub { 
   $PieChart->configure(-title => 'other title'); 
   } 
 )->pack;
 ...
 # title will be changed but not displayed if you not resize the widget.
  
 ...
 $fenetre->Button(-text => 'Change title', -command => sub { 
   $PieChart->configure(-title => 'other title'); 
   $PieChart->redraw; 
   } 
 )->pack;
 ...
 # OK, title will be changed and displayed without resize the widget.

=head2 zoom

zoom the graph (vertical and horizontal zoom).

$PieChart->zoom(I<$zoom>);

$zoom must be an integer great than 0.

 Ex : 300*300 size
 $PieChart->zoom(50); # size divide by 2 => 150*150
 ...
 $PieChart->zoom(200); # size multiplie by 2 => 600*600
 ...
 $PieChart->zoom(120); # 20% add in each axis => 360*360
 ...
 $PieChart->zoom(100); # original resize 300*300. 


=head2 zoomx

Horizontal zoom.

 # original canvas size 300*300
 $PieChart->zoomx(50); # new size : 150*300
 ...
 $PieChart->zoom(100); # new size : 300*300

=head2 zoomy

Vertical zoom.

 # original canvas size 300*300
 $PieChart->zoomy(50); # new size : 300*150
 ...
 $PieChart->zoom(100); # new size : 300*300

=head1 SEE ALSO

See L<Tk::Canvas> for details of the standard options.

See L<Tk::Chart>, L<Tk::Chart::FAQ>, L<GD::Graph>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart::Pie


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

1; # End of Tk::Chart::Pie
