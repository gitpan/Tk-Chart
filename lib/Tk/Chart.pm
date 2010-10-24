package Tk::Chart;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 24/10/2010 01:29:33
# AIM       : Private functions for Tk::Chart modules
#==================================================================
use strict;
use warnings;
use Carp;
use Tk::Chart::Utils qw / :DUMMIES /;
use vars qw($VERSION);
$VERSION = '1.14';

use Exporter;

my @ModuleToExport = qw (
  _TreatParameters         _InitConfig    _error
  _CheckSizeLengendAndData _ZoomCalcul    _DestroyBalloonAndBind
  _CreateType              _GetMarkerType _display_line
  _box                     _title         _XLabelPosition
  _YLabelPosition          _ytick         _ChartConstruction
  _ManageMinMaxValues     _DisplayxTicks  _DisplayyTicks
  _get_ConfigSpecs
);

our @ISA         = qw/ Exporter /;
our @EXPORT_OK   = @ModuleToExport;
our %EXPORT_TAGS = ( DUMMIES => \@ModuleToExport );

sub _get_ConfigSpecs {

  my $RefConfig = _InitConfig();

  my %Configuration = (
    -title         => [ 'PASSIVE', 'Title',         'Title',         undef ],
    -titlecolor    => [ 'PASSIVE', 'Titlecolor',    'TitleColor',    'black' ],
    -titlefont     => [ 'PASSIVE', 'Titlefont',     'TitleFont',     $RefConfig->{Font}{DefaultTitle} ],
    -titleposition => [ 'PASSIVE', 'Titleposition', 'TitlePosition', 'center' ],
    -titleheight   => [ 'PASSIVE', 'Titleheight',   'TitleHeight',   $RefConfig->{Title}{Height} ],

    -xlabel         => [ 'PASSIVE', 'Xlabel',         'XLabel',         undef ],
    -xlabelcolor    => [ 'PASSIVE', 'Xlabelcolor',    'XLabelColor',    'black' ],
    -xlabelfont     => [ 'PASSIVE', 'Xlabelfont',     'XLabelFont',     $RefConfig->{Font}{DefaultLabel} ],
    -xlabelposition => [ 'PASSIVE', 'Xlabelposition', 'XLabelPosition', 'center' ],
    -xlabelheight => [ 'PASSIVE', 'Xlabelheight', 'XLabelHeight', $RefConfig->{Axis}{Xaxis}{xlabelHeight} ],
    -xlabelskip   => [ 'PASSIVE', 'Xlabelskip',   'XLabelSkip',   0 ],

    -xvaluecolor    => [ 'PASSIVE', 'Xvaluecolor',    'XValueColor',    'black' ],
    -xvaluevertical => [ 'PASSIVE', 'Xvaluevertical', 'XValueVertical', 0 ],
    -xvaluespace => [ 'PASSIVE', 'Xvaluespace', 'XValueSpace', $RefConfig->{Axis}{Xaxis}{ScaleValuesHeight} ],
    -xvalueview  => [ 'PASSIVE', 'Xvalueview',  'XValueView',  1 ],
    -yvalueview  => [ 'PASSIVE', 'Yvalueview',  'YValueView',  1 ],
    -xvaluesregex => [ 'PASSIVE', 'Xvaluesregex', 'XValuesRegex', qr/.+/ ],

    -ylabel         => [ 'PASSIVE', 'Ylabel',         'YLabel',         undef ],
    -ylabelcolor    => [ 'PASSIVE', 'Ylabelcolor',    'YLabelColor',    'black' ],
    -ylabelfont     => [ 'PASSIVE', 'Ylabelfont',     'YLabelFont',     $RefConfig->{Font}{DefaultLabel} ],
    -ylabelposition => [ 'PASSIVE', 'Ylabelposition', 'YLabelPosition', 'center' ],
    -ylabelwidth => [ 'PASSIVE', 'Ylabelwidth', 'YLabelWidth', $RefConfig->{Axis}{Yaxis}{ylabelWidth} ],

    -yvaluecolor => [ 'PASSIVE', 'Yvaluecolor', 'YValueColor', 'black' ],

    -labelscolor => [ 'PASSIVE', 'Labelscolor', 'LabelsColor', undef ],
    -valuescolor => [ 'PASSIVE', 'Valuescolor', 'ValuesColor', undef ],
    -textcolor   => [ 'PASSIVE', 'Textcolor',   'TextColor',   undef ],
    -textfont    => [ 'PASSIVE', 'Textfont',    'TextFont',    undef ],

    -boxaxis      => [ 'PASSIVE', 'Boxaxis',      'BoxAxis',      0 ],
    -noaxis       => [ 'PASSIVE', 'Noaxis',       'NoAxis',       0 ],
    -zeroaxisonly => [ 'PASSIVE', 'Zeroaxisonly', 'ZeroAxisOnly', 0 ],
    -zeroaxis     => [ 'PASSIVE', 'Zeroaxis',     'ZeroAxis',     0 ],
    -longticks    => [ 'PASSIVE', 'Longticks',    'LongTicks',    0 ],

    -xlongticks      => [ 'PASSIVE', 'XLongticks',      'XLongTicks',      0 ],
    -ylongticks      => [ 'PASSIVE', 'YLongticks',      'YLongTicks',      0 ],
    -xlongtickscolor => [ 'PASSIVE', 'XLongtickscolor', 'XLongTicksColor', '#B3B3B3' ],
    -ylongtickscolor => [ 'PASSIVE', 'YLongtickscolor', 'YLongTicksColor', '#B3B3B3' ],
    -longtickscolor  => [ 'PASSIVE', 'Longtickscolor',  'LongTicksColor',  undef ],
    -axiscolor       => [ 'PASSIVE', 'Axiscolor',       'AxisColor',       'black' ],

    -xtickheight => [ 'PASSIVE', 'Xtickheight', 'XTickHeight', $RefConfig->{Axis}{Xaxis}{TickHeight} ],
    -xtickview   => [ 'PASSIVE', 'Xtickview',   'XTickView',   1 ],

    -yminvalue => [ 'PASSIVE', 'Yminvalue', 'YMinValue', 0 ],
    -ymaxvalue => [ 'PASSIVE', 'Ymaxvalue', 'YMaxValue', undef ],
    -interval  => [ 'PASSIVE', 'interval',  'Interval',  0 ],

    # image size
    -width  => [ 'SELF', 'width',  'Width',  $RefConfig->{Canvas}{Width} ],
    -height => [ 'SELF', 'height', 'Height', $RefConfig->{Canvas}{Height} ],

    -yticknumber => [ 'PASSIVE', 'Yticknumber', 'YTickNumber', $RefConfig->{Axis}{Yaxis}{TickNumber} ],
    -ytickwidth  => [ 'PASSIVE', 'Ytickwidth',  'YtickWidth',  $RefConfig->{Axis}{Yaxis}{TickWidth} ],
    -ytickview   => [ 'PASSIVE', 'Ytickview',   'YTickView',   1 ],

    -alltickview => [ 'PASSIVE', 'Alltickview', 'AllTickView', 1 ],

    -linewidth => [ 'PASSIVE', 'Linewidth', 'LineWidth', 1 ],
    -colordata => [ 'PASSIVE', 'Colordata', 'ColorData', $RefConfig->{Legend}{Colors} ],

    # verbose mode
    -verbose => [ 'PASSIVE', 'verbose', 'Verbose', 1 ],
  );

  return \%Configuration;
}

sub _InitConfig {
  my $CompositeWidget = shift;
  my %Configuration   = (
    'Axis' => {
      Cx0   => undef,
      Cx0   => undef,
      CxMin => undef,
      CxMax => undef,
      CyMin => undef,
      CyMax => undef,
      Xaxis => {
        Width             => undef,
        Height            => undef,
        xlabelHeight      => 30,
        ScaleValuesHeight => 30,
        TickHeight        => 5,
        CxlabelX          => undef,
        CxlabelY          => undef,
        Idxlabel          => undef,
        IdxTick           => undef,
        TagAxis0          => 'Axe00',
      },
      Yaxis => {
        ylabelWidth      => 5,
        ScaleValuesWidth => 60,
        TickWidth        => 5,
        TickNumber       => 4,
        Width            => undef,
        Height           => undef,
        CylabelX         => undef,
        CylabelY         => undef,
        Idylabel         => undef,
      },
    },
    'Balloon' => {
      Obj               => undef,
      Message           => {},
      State             => 0,
      ColorData         => [ '#000000', '#CB89D3' ],
      MorePixelSelected => 2,
      Background        => 'snow',
      BalloonMsg        => undef,
      IdLegData         => undef,
    },
    'Canvas' => {
      Height           => 400,
      Width            => 400,
      HeightEmptySpace => 20,
      WidthEmptySpace  => 20,
      YTickWidth       => 2,
    },
    'Data' => {
      RefXLegend             => undef,
      RefAllData             => undef,
      PlotDefined            => undef,
      MaxYValue              => undef,
      MinYValue              => undef,
      GetIdData              => {},
      SubstitutionValue      => 0,
      NumberRealData         => undef,
      RefDataToDisplay       => undef,
      RefOptionDataToDisplay => undef,
    },
    'Font' => {
      Default            => '{Times} 10 {normal}',
      DefaultTitle       => '{Times} 12 {bold}',
      DefaultLabel       => '{Times} 10 {bold}',
      DefaultLegend      => '{Times} 8 {normal}',
      DefaultLegendTitle => '{Times} 8 {bold}',
      DefaultBarValues   => '{Times} 8 {normal}',
    },
    'Legend' => {
      HeightTitle     => 30,
      HLine           => 20,
      WCube           => 10,
      HCube           => 10,
      SpaceBeforeCube => 5,
      SpaceAfterCube  => 5,
      WidthText       => 250,
      NbrLegPerLine   => undef,
      '-width'        => undef,
      Height          => 0,
      Width           => undef,
      LengthOneLegend => undef,
      DataLegend      => undef,
      LengthTextMax   => undef,
      GetIdLeg        => {},
      title           => undef,
      titlefont       => '{Times} 12 {bold}',
      titlecolors     => 'black',
      textcolor       => 'black',
      legendcolor     => 'black',
      Colors          => [
        'red',     'green',   'blue',    'yellow',  'purple',  'cyan',    '#996600', '#99A6CC',
        '#669933', '#929292', '#006600', '#FFE100', '#00A6FF', '#009060', '#B000E0', '#A08000',
        'orange',  'brown',   'black',   '#FFCCFF', '#99CCFF', '#FF00CC', '#FF8000', '#006090',
      ],
      NbrLegend => 0,
      box       => 0,
    },
    'TAGS' => {
      AllTagsChart => '_AllTagsChart',
      AllAXIS      => '_AllAXISTag',
      yAxis        => '_yAxisTag',
      xAxis        => '_xAxisTag',
      'xAxis0'     => '_0AxisTag',
      BoxAxis      => '_BoxAxisTag',
      xTick        => '_xTickTag',
      yTick        => '_yTickTag',
      AllTick      => '_AllTickTag',
      'xValue0'    => '_xValue0Tag',
      xValues      => '_xValuesTag',
      yValues      => '_yValuesTag',
      AllValues    => '_AllValuesTag',
      TitleLegend  => '_TitleLegendTag',
      BoxLegend    => '_BoxLegendTag',
      AllData      => '_AllDataTag',
      AllPie       => '_AllPieTag',
      Area         => '_AreaTag',
      Pie          => '_PieTag',
      PointLine    => '_PointLineTag',
      Line         => '_LineTag',
      Point        => '_PointTag',
      Bar          => '_BarTag',
      Mixed        => '_MixedTag',
      Legend       => '_LegendTag',
      DashLines    => '_DashLineTag',
      AllBars      => '_AllBars',
      BarValues    => '_BarValuesTag',
      Boxplot      => '_BoxplotTag',
    },
    'Title' => {
      Ctitrex  => undef,
      Ctitrey  => undef,
      IdTitre  => undef,
      '-width' => undef,
      Width    => undef,
      Height   => 40,
    },
    'Zoom' => {
      CurrentX => 100,
      CurrentY => 100,
    },
    'Mixed' => { DisplayOrder => [qw/ areas bars lines dashlines points /], },
  );

  return \%Configuration;
}

sub _TreatParameters {
  my ($CompositeWidget) = @_;

  my @IntegerOption = qw /
    -xlabelheight -xlabelskip     -xvaluespace  -ylabelwidth
    -boxaxis      -noaxis         -zeroaxisonly -xtickheight
    -xtickview    -yticknumber    -ytickwidth   -linewidth
    -alltickview  -xvaluevertical -titleheight  -gridview
    -ytickview    -overwrite      -cumulate     -spacingbar
    -showvalues   -startangle     -viewsection  -zeroaxis
    -longticks    -markersize     -pointline
    -smoothline   -spline         -bezier
    -interval     -xlongticks     -ylongticks   -setlegend
    /;

  foreach my $OptionName (@IntegerOption) {
    my $data = $CompositeWidget->cget($OptionName);
    if ( defined $data and $data !~ m{^\d+$} ) {
      $CompositeWidget->_error( "'Can't set $OptionName to `$data', $data' isn't numeric", 1 );
      return;
    }
  }

  my $xvaluesregex = $CompositeWidget->cget( -xvaluesregex );
  if ( defined $xvaluesregex and ref($xvaluesregex) !~ m{^Regexp$}i ) {
    $CompositeWidget->_error(
      "'Can't set -xvaluesregex to `$xvaluesregex', "
        . "$xvaluesregex' is not a regex expression\nEx : "
        . "-xvaluesregex => qr/My regex/;",
      1
    );
    return;
  }

  my $gradient = $CompositeWidget->cget( -gradient );
  if ( defined $gradient and ref($gradient) !~ m{^hash$}i ) {
    $CompositeWidget->_error(
      "'Can't set -gradient to `$gradient', " . "$gradient' is not a hash reference expression\n", 1 );
    return;
  }

  my $Colors = $CompositeWidget->cget( -colordata );
  if ( defined $Colors and ref($Colors) ne 'ARRAY' ) {
    $CompositeWidget->_error(
      "'Can't set -colordata to `$Colors', "
        . "$Colors' is not an array reference\nEx : "
        . "-colordata => [\"blue\",\"#2400FF\",...]",
      1
    );
    return;
  }
  my $Markers = $CompositeWidget->cget( -markers );
  if ( defined $Markers and ref($Markers) ne 'ARRAY' ) {
    $CompositeWidget->_error(
      "'Can't set -markers to `$Markers', "
        . "$Markers' is not an array reference\nEx : "
        . "-markers => [5,8,2]",
      1
    );

    return;
  }
  my $Typemixed = $CompositeWidget->cget( -typemixed );
  if ( defined $Typemixed and ref($Typemixed) ne 'ARRAY' ) {
    $CompositeWidget->_error(
      "'Can't set -typemixed to `$Typemixed', "
        . "$Typemixed' is not an array reference\nEx : "
        . "-typemixed => ['bars','lines',...]",
      1
    );

    return;
  }

  if ( my $xtickheight = $CompositeWidget->cget( -xtickheight ) ) {
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight} = $xtickheight;
  }

  # -smoothline deprecated, use -bezier
  if ( my $smoothline = $CompositeWidget->cget( -smoothline ) ) {
    $CompositeWidget->configure( -bezier => $smoothline );
  }

  if ( my $xvaluespace = $CompositeWidget->cget( -xvaluespace ) ) {
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} = $xvaluespace;
  }

  if ( my $noaxis = $CompositeWidget->cget( -noaxis ) and $CompositeWidget->cget( -noaxis ) == 1 ) {
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight} = 0;
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}  = 0;
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth}         = 0;
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight}        = 0;
  }

  if ( my $title = $CompositeWidget->cget( -title ) ) {
    if ( my $titleheight = $CompositeWidget->cget( -titleheight ) ) {
      $CompositeWidget->{RefChart}->{Title}{Height} = $titleheight;
    }
  }
  else {
    $CompositeWidget->{RefChart}->{Title}{Height} = 0;
  }

  if ( my $xlabel = $CompositeWidget->cget( -xlabel ) ) {
    if ( my $xlabelheight = $CompositeWidget->cget( -xlabelheight ) ) {
      $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight} = $xlabelheight;
    }
  }
  else {
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight} = 0;
  }

  if ( my $ylabel = $CompositeWidget->cget( -ylabel ) ) {
    if ( my $ylabelWidth = $CompositeWidget->cget( -ylabelWidth ) ) {
      $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth} = $ylabelWidth;
    }
  }
  else {
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth} = 0;
  }

  if ( my $ytickwidth = $CompositeWidget->cget( -ytickwidth ) ) {
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth} = $ytickwidth;
  }

  if ( my $valuescolor = $CompositeWidget->cget( -valuescolor ) ) {
    $CompositeWidget->configure( -xvaluecolor => $valuescolor );
    $CompositeWidget->configure( -yvaluecolor => $valuescolor );
  }

  if ( my $textcolor = $CompositeWidget->cget( -textcolor ) ) {
    $CompositeWidget->configure( -titlecolor  => $textcolor );
    $CompositeWidget->configure( -xlabelcolor => $textcolor );
    $CompositeWidget->configure( -ylabelcolor => $textcolor );
  }
  elsif ( my $labelscolor = $CompositeWidget->cget( -labelscolor ) ) {
    $CompositeWidget->configure( -xlabelcolor => $labelscolor );
    $CompositeWidget->configure( -ylabelcolor => $labelscolor );
  }

  if ( my $textfont = $CompositeWidget->cget( -textfont ) ) {
    $CompositeWidget->configure( -titlefont  => $textfont );
    $CompositeWidget->configure( -xlabelfont => $textfont );
    $CompositeWidget->configure( -ylabelfont => $textfont );
  }
  if ( my $startangle = $CompositeWidget->cget( -startangle ) ) {
    if ( $startangle < 0 or $startangle > 360 ) {
      $CompositeWidget->configure( -startangle => 0 );
    }
  }

=for borderwidth:
  If user call -borderwidth option, the graph will be trunc.
  Then we will add HeightEmptySpace and WidthEmptySpace.

=cut

  if ( my $borderwidth = $CompositeWidget->cget( -borderwidth ) ) {
    $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} = $borderwidth + 15;
    $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}  = $borderwidth + 15;
  }

  #update=
  my $yminvalue = $CompositeWidget->cget( -yminvalue );
  if ( defined $yminvalue and !_isANumber($yminvalue) ) {
    $CompositeWidget->_error( "-yminvalue option must be a number or real number ($yminvalue)", 1 );
    return;
  }
  my $ymaxvalue = $CompositeWidget->cget( -ymaxvalue );
  if ( defined $ymaxvalue and !_isANumber($ymaxvalue) ) {
    $CompositeWidget->_error( "-ymaxvalue option must be a number or real number", 1 );
    return;
  }

  if ( defined $yminvalue and defined $ymaxvalue ) {
    unless ( $ymaxvalue > $yminvalue ) {
      $CompositeWidget->_error( "-ymaxvalue must be greater than -yminvalue option", 1 );
      return;
    }
  }

  return 1;
}

sub _CheckSizeLengendAndData {
  my ( $CompositeWidget, $RefData, $RefLegend ) = @_;

  # Check legend size
  unless ( defined $RefLegend ) {
    $CompositeWidget->_error('legend not defined');
    return;
  }
  my $SizeLegend = scalar @{$RefLegend};

  # Check size between legend and data
  my $SizeData = scalar @{$RefData} - 1;
  unless ( $SizeLegend == $SizeData ) {
    $CompositeWidget->_error('Legend and array size data are different');
    return;
  }

  return 1;
}

sub _ZoomCalcul {
  my ( $CompositeWidget, $ZoomX, $ZoomY ) = @_;

  if ( ( defined $ZoomX and !( _isANumber($ZoomX) or $ZoomX > 0 ) )
    or ( defined $ZoomY and !( _isANumber($ZoomY) or $ZoomY > 0 ) )
    or ( not defined $ZoomX and not defined $ZoomY ) )
  {
    $CompositeWidget->_error( 'zoom value must be defined, numeric and great than 0', 1 );
    return;
  }

  my $CurrentWidth  = $CompositeWidget->{RefChart}->{Canvas}{Width};
  my $CurrentHeight = $CompositeWidget->{RefChart}->{Canvas}{Height};

  my $CentPercentWidth  = ( 100 / $CompositeWidget->{RefChart}->{Zoom}{CurrentX} ) * $CurrentWidth;
  my $CentPercentHeight = ( 100 / $CompositeWidget->{RefChart}->{Zoom}{CurrentY} ) * $CurrentHeight;
  my $NewWidth          = ( $ZoomX / 100 ) * $CentPercentWidth
    if ( defined $ZoomX );
  my $NewHeight = ( $ZoomY / 100 ) * $CentPercentHeight
    if ( defined $ZoomY );

  $CompositeWidget->{RefChart}->{Zoom}{CurrentX} = $ZoomX
    if ( defined $ZoomX );
  $CompositeWidget->{RefChart}->{Zoom}{CurrentY} = $ZoomY
    if ( defined $ZoomY );

  return ( $NewWidth, $NewHeight );
}

sub _DestroyBalloonAndBind {
  my ($CompositeWidget) = @_;

  # balloon defined and user want to stop it
  if ( $CompositeWidget->{RefChart}->{Balloon}{Obj}
    and Tk::Exists $CompositeWidget->{RefChart}->{Balloon}{Obj} )
  {
    $CompositeWidget->{RefChart}->{Balloon}{Obj}->configure( -state => 'none' );
    $CompositeWidget->{RefChart}->{Balloon}{Obj}->detach($CompositeWidget);

    #$CompositeWidget->{RefChart}->{Balloon}{Obj}->destroy;

    undef $CompositeWidget->{RefChart}->{Balloon}{Obj};
  }

  return;
}

sub _error {
  my ( $CompositeWidget, $ErrorMessage, $Croak ) = @_;

  my $Verbose = $CompositeWidget->cget( -verbose );
  if ( defined $Croak and $Croak == 1 ) {
    croak "[BE CARREFUL] : $ErrorMessage\n";
  }
  else {
    warn "[WARNING] : $ErrorMessage\n" if ( defined $Verbose and $Verbose == 1 );
  }

  return;
}

sub _GetMarkerType {
  my ( $CompositeWidget, $Number ) = @_;
  my %MarkerType = (

    # N°      Type                Filled
    1  => [ 'square',           1 ],
    2  => [ 'square',           0 ],
    3  => [ 'horizontal cross', 1 ],
    4  => [ 'diagonal cross',   1 ],
    5  => [ 'diamond',          1 ],
    6  => [ 'diamond',          0 ],
    7  => [ 'circle',           1 ],
    8  => [ 'circle',           0 ],
    9  => [ 'horizontal line',  1 ],
    10 => [ 'vertical line',    1 ],
  );

  return unless ( defined $MarkerType{$Number} );

  return $MarkerType{$Number};
}

=for _CreateType
  Calculate different points coord to create a rectangle, circle, 
  verticale or horizontal line, a cross, a plus and a diamond 
  from a point coord.
  Arg : Reference of hash
  {
    x      => value,
    y      => value,
    pixel  => value,
    type   => string, (circle, cross, plus, diamond, rectangle, Vline, Hline )
    option => Hash reference ( {-fill => xxx, -outline => yy, ...} )
  }

=cut

sub _CreateType {
  my ( $CompositeWidget, %Refcoord ) = @_;

  if ( $Refcoord{type} eq 'circle' or $Refcoord{type} eq 'square' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x2 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y2 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );

    if ( $Refcoord{type} eq 'circle' ) {
      $CompositeWidget->createOval( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    }
    else {
      $CompositeWidget->createRectangle( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    }
  }
  elsif ( $Refcoord{type} eq 'horizontal cross' ) {
    my $x1 = $Refcoord{x};
    my $y1 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    my $x2 = $x1;
    my $y2 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x3 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y3 = $Refcoord{y};
    my $x4 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y4 = $y3;
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    $CompositeWidget->createLine( $x3, $y3, $x4, $y4, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'diagonal cross' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x2 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y2 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    my $x3 = $x1;
    my $y3 = $y2;
    my $x4 = $x2;
    my $y4 = $y1;
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
    $CompositeWidget->createLine( $x3, $y3, $x4, $y4, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'diamond' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y};
    my $x2 = $Refcoord{x};
    my $y2 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    my $x3 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y3 = $Refcoord{y};
    my $x4 = $Refcoord{x};
    my $y4 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    $CompositeWidget->createPolygon( $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'vertical line' ) {
    my $x1 = $Refcoord{x};
    my $y1 = $Refcoord{y} - ( $Refcoord{pixel} / 2 );
    my $x2 = $Refcoord{x};
    my $y2 = $Refcoord{y} + ( $Refcoord{pixel} / 2 );
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
  }
  elsif ( $Refcoord{type} eq 'horizontal line' ) {
    my $x1 = $Refcoord{x} - ( $Refcoord{pixel} / 2 );
    my $y1 = $Refcoord{y};
    my $x2 = $Refcoord{x} + ( $Refcoord{pixel} / 2 );
    my $y2 = $Refcoord{y};
    $CompositeWidget->createLine( $x1, $y1, $x2, $y2, %{ $Refcoord{option} } );
  }
  else {
    return;
  }

  return 1;
}

=for _display_line
  Dispay point
  Arg : Reference of hash
  {
    x      => value,
    y      => value,
    pixel  => value,
    type   => string, (circle, cross, plus, diamond, rectangle, Vline, Hline )
    option => Hash reference ( {-fill => xxx, -outline => yy, ...} )
  }

=cut

# $CompositeWidget->_display_line($RefPoints, $LineNumber);
sub _display_line {
  my ( $CompositeWidget, $RefPoints, $LineNumber ) = @_;

  my $RefDataToDisplay = $CompositeWidget->{RefChart}->{Data}{RefDataToDisplay};
  return unless ( defined $RefDataToDisplay and defined $RefDataToDisplay->[$LineNumber] );

  my %options;
  my $font  = $CompositeWidget->{RefChart}->{Data}{RefOptionDataToDisplay}{'-font'};
  my $color = $CompositeWidget->{RefChart}->{Data}{RefOptionDataToDisplay}{'-foreground'};
  $options{'-font'} = $font  if ( defined $font );
  $options{'-fill'} = $color if ( defined $color );

  my $indice_point = 0;

DISPLAY:
  foreach my $value ( @{ $RefDataToDisplay->[$LineNumber] } ) {
    if ( defined $value ) {
      my $x = $RefPoints->[$indice_point];
      $indice_point++;
      my $y = $RefPoints->[$indice_point] - 10;
      $CompositeWidget->createText(
        $x, $y,
        -text => $value,
        %options,
      );
      $indice_point++;
      last DISPLAY unless defined $RefPoints->[$indice_point];
      next DISPLAY;
    }
    $indice_point += 2;
  }

  return;
}

sub _box {
  my ($CompositeWidget) = @_;

  my $axiscolor = $CompositeWidget->cget( -axiscolor );
  if ( $CompositeWidget->cget( -boxaxis ) == 0 ) {
    return;
  }

  # close axis
  # X axis 2
  $CompositeWidget->createLine(
    $CompositeWidget->{RefChart}->{Axis}{CxMin},
    $CompositeWidget->{RefChart}->{Axis}{CyMax},
    $CompositeWidget->{RefChart}->{Axis}{CxMax},
    $CompositeWidget->{RefChart}->{Axis}{CyMax},
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{BoxAxis}, $CompositeWidget->{RefChart}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # Y axis 2
  $CompositeWidget->createLine(
    $CompositeWidget->{RefChart}->{Axis}{CxMax},
    $CompositeWidget->{RefChart}->{Axis}{CyMin},
    $CompositeWidget->{RefChart}->{Axis}{CxMax},
    $CompositeWidget->{RefChart}->{Axis}{CyMax},
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{BoxAxis}, $CompositeWidget->{RefChart}->{TAGS}{AllAXIS},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  return;
}

sub _DisplayxTicks {
  my ( $CompositeWidget, $Xtickx1, $Xticky1, $Xtickx2, $Xticky2 ) = @_;

  my $longticks       = $CompositeWidget->cget( -longticks );
  my $xlongticks      = $CompositeWidget->cget( -xlongticks );
  my $xlongtickscolor = $CompositeWidget->cget( -xlongtickscolor );
  my $longtickscolor  = $CompositeWidget->cget( -longtickscolor );
  my $axiscolor       = $CompositeWidget->cget( -axiscolor );

  # Only short xticks
  $CompositeWidget->createLine(
    $Xtickx1, $Xticky1, $Xtickx2, $Xticky2,
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{xTick}, $CompositeWidget->{RefChart}->{TAGS}{AllTick},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # Long xTicks
  if ( ( defined $longticks and $longticks == 1 ) or ( defined $xlongticks and $xlongticks == 1 ) ) {
    $Xticky1 = $CompositeWidget->{RefChart}->{Axis}{CyMax};
    $Xticky2 = $CompositeWidget->{RefChart}->{Axis}{CyMin};
    $CompositeWidget->createLine(
      $Xtickx1, $Xticky1, $Xtickx2, $Xticky2,
      -tags => [
        $CompositeWidget->{RefChart}->{TAGS}{xTick}, $CompositeWidget->{RefChart}->{TAGS}{AllTick},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $longtickscolor || $xlongtickscolor,
      -dash => '.',
    );
  }

  return 1;
}

sub _DisplayyTicks {
  my ( $CompositeWidget, $Ytickx1, $Yticky1, $Ytickx2, $Yticky2 ) = @_;

  my $longticks       = $CompositeWidget->cget( -longticks );
  my $ylongticks      = $CompositeWidget->cget( -ylongticks );
  my $ylongtickscolor = $CompositeWidget->cget( -ylongtickscolor );
  my $longtickscolor  = $CompositeWidget->cget( -longtickscolor );
  my $axiscolor       = $CompositeWidget->cget( -axiscolor );

  # Only short yticks
  $CompositeWidget->createLine(
    $Ytickx1, $Yticky1, $Ytickx2, $Yticky2,
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{yTick}, $CompositeWidget->{RefChart}->{TAGS}{AllTick},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
    -fill => $axiscolor,
  );

  # Long yTicks
  if ( ( defined $longticks and $longticks == 1 ) or ( defined $ylongticks and $ylongticks == 1 ) ) {
    $Ytickx1 = $CompositeWidget->{RefChart}->{Axis}{CxMin};
    $Ytickx2 = $CompositeWidget->{RefChart}->{Axis}{CxMax};
    $CompositeWidget->createLine(
      $Ytickx1, $Yticky1, $Ytickx2, $Yticky2,
      -tags => [
        $CompositeWidget->{RefChart}->{TAGS}{yTick}, $CompositeWidget->{RefChart}->{TAGS}{AllTick},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
      -fill => $longtickscolor || $ylongtickscolor,
      -dash => '.',
    );
  }

  return 1;
}

sub _ytick {
  my ($CompositeWidget) = @_;

  my $yminvalue = $CompositeWidget->cget( -yminvalue );
  my $longticks = $CompositeWidget->cget( -longticks );
  $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickNumber} = $CompositeWidget->cget( -yticknumber );

  # space between y ticks
  my $Space = $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Height}
    / $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickNumber};
  my $UnitValue
    = ( $CompositeWidget->{RefChart}->{Data}{MaxYValue} - $CompositeWidget->{RefChart}->{Data}{MinYValue} )
    / $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickNumber};

  for my $TickNumber ( 1 .. $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickNumber} ) {

    # Display y ticks
    my $Ytickx1 = $CompositeWidget->{RefChart}->{Axis}{Cx0};
    my $Yticky1 = $CompositeWidget->{RefChart}->{Axis}{CyMin} - ( $TickNumber * $Space );
    my $Ytickx2
      = $CompositeWidget->{RefChart}->{Axis}{Cx0} - $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth};
    my $Yticky2 = $CompositeWidget->{RefChart}->{Axis}{CyMin} - ( $TickNumber * $Space );

    my $YValuex
      = $CompositeWidget->{RefChart}->{Axis}{Cx0}
      - ( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth}
        + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth} / 2 );
    my $YValuey = $Yticky1;
    my $Value   = $UnitValue * $TickNumber + $CompositeWidget->{RefChart}->{Data}{MinYValue};
    next if ( $Value == 0 );

    # round value if to long
    $Value = _roundValue($Value);

    # Display yticks short or long
    $CompositeWidget->_DisplayyTicks( $Ytickx1, $Yticky1, $Ytickx2, $Yticky2 );

    $CompositeWidget->createText(
      $YValuex, $YValuey,
      -text => $Value,
      -fill => $CompositeWidget->cget( -yvaluecolor ),
      -tags => [
        $CompositeWidget->{RefChart}->{TAGS}{yValues}, $CompositeWidget->{RefChart}->{TAGS}{AllValues},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  # Display 0 value or not
  unless ( $CompositeWidget->{RefChart}->{Data}{MinYValue} == 0
    or ( defined $yminvalue and $yminvalue > 0 )
    or ( $CompositeWidget->{RefChart}->{Data}{MinYValue} > 0 ) )
  {
    $CompositeWidget->createText(
      $CompositeWidget->{RefChart}->{Axis}{Cx0} - ( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth} ),
      $CompositeWidget->{RefChart}->{Axis}{Cy0},
      -text => 0,
      -tags => [
        $CompositeWidget->{RefChart}->{TAGS}{xValue0}, $CompositeWidget->{RefChart}->{TAGS}{AllValues},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  # Display the minimale value
  $CompositeWidget->createText(
    $CompositeWidget->{RefChart}->{Axis}{CxMin} - (
          $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth}
        + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth} / 2
    ),

    $CompositeWidget->{RefChart}->{Axis}{CyMin},
    -text => _roundValue( $CompositeWidget->{RefChart}->{Data}{MinYValue} ),
    -fill => $CompositeWidget->cget( -yvaluecolor ),
    -tags => [
      $CompositeWidget->{RefChart}->{TAGS}{yValues}, $CompositeWidget->{RefChart}->{TAGS}{AllValues},
      $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
    ],
  );

  # Long tick
  unless ( defined $longticks and $longticks == 1 ) {
    $CompositeWidget->createLine(
      $CompositeWidget->{RefChart}->{Axis}{Cx0},
      $CompositeWidget->{RefChart}->{Axis}{CyMin} - $Space,
      $CompositeWidget->{RefChart}->{Axis}{Cx0} - $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth},
      $CompositeWidget->{RefChart}->{Axis}{CyMin} - $Space,
      -tags => [
        $CompositeWidget->{RefChart}->{TAGS}{yTick}, $CompositeWidget->{RefChart}->{TAGS}{AllTick},
        $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart},
      ],
    );
  }

  return;
}

sub _title {
  my ($CompositeWidget) = @_;

  my $Title         = $CompositeWidget->cget( -title );
  my $TitleColor    = $CompositeWidget->cget( -titlecolor );
  my $TitleFont     = $CompositeWidget->cget( -titlefont );
  my $titleposition = $CompositeWidget->cget( -titleposition );

  # Title verification
  unless ($Title) {
    return;
  }

  # Space before the title
  my $WidthEmptyBeforeTitle
    = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth};

  # Coordinates title
  $CompositeWidget->{RefChart}->{Title}{Ctitrex}
    = ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width} / 2 ) + $WidthEmptyBeforeTitle;
  $CompositeWidget->{RefChart}->{Title}{Ctitrey} = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}
    + ( $CompositeWidget->{RefChart}->{Title}{Height} / 2 );

  # -width to createText
  $CompositeWidget->{RefChart}->{Title}{'-width'} = $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width};

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
    -width  => $CompositeWidget->{RefChart}->{Title}{'-width'},
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

  if ( $CompositeWidget->{RefChart}->{Title}{Ctitrey}
    < $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} )
  {

    # cut title
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{Title}{IdTitre} );

    $CompositeWidget->{RefChart}->{Title}{Ctitrex} = $WidthEmptyBeforeTitle;
    $CompositeWidget->{RefChart}->{Title}{Ctitrey} = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace}
      + ( $CompositeWidget->{RefChart}->{Title}{Height} / 2 );

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

sub _XLabelPosition {
  my ($CompositeWidget) = @_;

  my $xlabel = $CompositeWidget->cget( -xlabel );

  # no x_label
  unless ( defined $xlabel ) {
    return;
  }

  # coordinate (CxlabelX, CxlabelY)
  my $BeforexlabelX
    = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ScaleValuesWidth}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{TickWidth};
  my $BeforexlabelY
    = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $CompositeWidget->{RefChart}->{Title}{Height}
    + $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Height}
    + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{TickHeight}
    + $CompositeWidget->{RefChart}->{Axis}{Xaxis}{ScaleValuesHeight};

  $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelX}
    = $BeforexlabelX + ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width} / 2 );
  $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelY}
    = $BeforexlabelY + ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight} / 2 );

  # display xlabel
  $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Idxlabel} = $CompositeWidget->createText(
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelX},
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelY},
    -text  => $xlabel,
    -width => $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Width},
    -tags  => [ $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
  );

  # get info ylabel xlabel
  my ( $width, $Height );
  ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelX},
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelY},
    $width, $Height
  ) = $CompositeWidget->bbox( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Idxlabel} );

  if ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelY} < $BeforexlabelY ) {

    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Idxlabel} );

    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelX} = $BeforexlabelX;
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelY}
      = $BeforexlabelY + ( $CompositeWidget->{RefChart}->{Axis}{Xaxis}{xlabelHeight} / 2 );

    # display xlabel
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Idxlabel} = $CompositeWidget->createText(
      $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelX},
      $CompositeWidget->{RefChart}->{Axis}{Xaxis}{CxlabelY},
      -text   => $xlabel,
      -width  => 0,
      -anchor => 'nw',
      -tags   => [ $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
    );
  }

  $CompositeWidget->itemconfigure(
    $CompositeWidget->{RefChart}->{Axis}{Xaxis}{Idxlabel},
    -font => $CompositeWidget->cget( -xlabelfont ),
    -fill => $CompositeWidget->cget( -xlabelcolor ),
  );

  return;
}

sub _YLabelPosition {
  my ($CompositeWidget) = @_;

  my $ylabel = $CompositeWidget->cget( -ylabel );

  # no y_label
  unless ( defined $ylabel ) {
    return;
  }

  # coordinate (CylabelX, CylabelY)
  $CompositeWidget->{RefChart}->{Axis}{Yaxis}{CylabelX}
    = $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace}
    + ( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth} / 2 );
  $CompositeWidget->{RefChart}->{Axis}{Yaxis}{CylabelY}
    = $CompositeWidget->{RefChart}->{Canvas}{HeightEmptySpace} 
    + $CompositeWidget->{RefChart}->{Title}{Height}
    + ( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Height} / 2 );

  # display ylabel
  $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Idylabel} = $CompositeWidget->createText(
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{CylabelX},
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{CylabelY},
    -text  => $ylabel,
    -font  => $CompositeWidget->cget( -ylabelfont ),
    -width => $CompositeWidget->{RefChart}->{Axis}{Yaxis}{ylabelWidth},
    -fill  => $CompositeWidget->cget( -ylabelcolor ),
    -tags  => [ $CompositeWidget->{RefChart}->{TAGS}{AllTagsChart}, ],
  );

  # get info ylabel
  my ( $Width, $Height );
  ( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{CylabelX},
    $CompositeWidget->{RefChart}->{Axis}{Yaxis}{CylabelY},
    $Width, $Height
  ) = $CompositeWidget->bbox( $CompositeWidget->{RefChart}->{Axis}{Yaxis}{Idylabel} );

  return;
}

sub _ManageMinMaxValues {
  my ( $CompositeWidget, $yticknumber, $cumulate ) = @_;

  my $yminvalue = $CompositeWidget->cget( -yminvalue );
  my $ymaxvalue = $CompositeWidget->cget( -ymaxvalue );
  my $interval  = $CompositeWidget->cget( -interval );

  if ( defined $yminvalue and defined $ymaxvalue ) {
    unless (
      (     $ymaxvalue >= $CompositeWidget->{RefChart}->{Data}{MaxYValue}
        and $yminvalue <= $CompositeWidget->{RefChart}->{Data}{MinYValue}
      )
      or ( defined $interval and $interval == 1 )
      )
    {
      $CompositeWidget->_error("-yminvalue and -ymaxvalue do not include all data");
    }
  }

  if ( defined $cumulate and $cumulate == 1 and $CompositeWidget->{RefChart}->{Data}{MinYValue} > 0 ) {
    $CompositeWidget->{RefChart}->{Data}{MinYValue} = 0;
  }

  unless ( ( defined $interval and $interval == 1 ) ) {
    if ( $CompositeWidget->{RefChart}->{Data}{MinYValue} > 0 ) {
      $CompositeWidget->{RefChart}->{Data}{MinYValue} = 0;
    }
    while ( ( $CompositeWidget->{RefChart}->{Data}{MaxYValue} / $yticknumber ) % 5 != 0 ) {
      $CompositeWidget->{RefChart}->{Data}{MaxYValue}
        = int( $CompositeWidget->{RefChart}->{Data}{MaxYValue} + 1 );
    }

    if ( defined $yminvalue and $yminvalue != 0 ) {
      $CompositeWidget->{RefChart}->{Data}{MinYValue} = $yminvalue;
    }
    if ( defined $ymaxvalue and $ymaxvalue != 0 ) {
      $CompositeWidget->{RefChart}->{Data}{MaxYValue} = $ymaxvalue;
    }

  }

  return 1;
}

sub _ChartConstruction {
  my ($CompositeWidget) = @_;

  unless ( defined $CompositeWidget->{RefChart}->{Data}{PlotDefined} ) {
    return;
  }

  $CompositeWidget->clearchart();
  $CompositeWidget->_TreatParameters();

  # For background gradient color
  $CompositeWidget->set_gradientcolor;

  # Height and Width canvas
  $CompositeWidget->{RefChart}->{Canvas}{Width}  = $CompositeWidget->width;
  $CompositeWidget->{RefChart}->{Canvas}{Height} = $CompositeWidget->height;

  # Pie graph
  if ( $CompositeWidget->class eq 'Pie' ) {

    # Width Pie
    $CompositeWidget->{RefChart}->{Pie}{Width} = $CompositeWidget->{RefChart}->{Canvas}{Width}
      - ( 2 * $CompositeWidget->{RefChart}->{Canvas}{WidthEmptySpace} );

    if ( $CompositeWidget->{RefChart}->{Data}{RefAllData} ) {
      $CompositeWidget->_titlepie;
      $CompositeWidget->_ViewData;
      $CompositeWidget->_ViewLegend();
    }
    return;
  }

  $CompositeWidget->_axis();
  $CompositeWidget->_box();
  $CompositeWidget->_YLabelPosition();
  $CompositeWidget->_XLabelPosition();
  $CompositeWidget->_title();

  if ( $CompositeWidget->class eq 'Lines' ) {
    if ( $CompositeWidget->cget( -pointline ) == 1 ) {
      $CompositeWidget->_ViewDataPoints();
    }
    else {
      $CompositeWidget->_ViewDataLines();
    }
  }
  else {
    $CompositeWidget->_ViewData();
  }

  #
  unless ( $CompositeWidget->cget( -noaxis ) == 1 ) {
    $CompositeWidget->_xtick();
    $CompositeWidget->_ytick();
  }

  if ( $CompositeWidget->{RefChart}->{Legend}{NbrLegend} > 0 ) {
    $CompositeWidget->_ViewLegend();
    $CompositeWidget->_Balloon();
  }

  # If Y value < 0, don't display O x axis
  if ( $CompositeWidget->{RefChart}->{Data}{MaxYValue} < 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xAxis0} );
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xValue0} );
  }

  # Axis
  if ( $CompositeWidget->cget( -noaxis ) == 1 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{AllAXIS} );
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{AllTick} );
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{AllValues} );
  }
  if (  $CompositeWidget->cget( -zeroaxisonly ) == 1
    and $CompositeWidget->{RefChart}->{Data}{MaxYValue} > 0
    and $CompositeWidget->{RefChart}->{Data}{MinYValue} < 0 )
  {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xAxis} );
  }
  if ( $CompositeWidget->cget( -zeroaxis ) == 1 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xAxis0} );
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xTick} );
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xValues} );
  }
  if ( $CompositeWidget->cget( -xvalueview ) == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xValues} );
  }
  if ( $CompositeWidget->cget( -yvalueview ) == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{yValues} );
  }

  # ticks
  my $alltickview = $CompositeWidget->cget( -alltickview );
  if ( defined $alltickview ) {
    if ( $alltickview == 0 ) {
      $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{AllTick} );
    }
    else {
      $CompositeWidget->configure( -ytickview => 1 );
      $CompositeWidget->configure( -xtickview => 1 );
    }
  }
  else {
    if ( $CompositeWidget->cget( -xtickview ) == 0 ) {
      $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{xTick} );
    }
    if ( $CompositeWidget->cget( -ytickview ) == 0 ) {
      $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{yTick} );
    }
  }

  # Legend
  if ( $CompositeWidget->{RefChart}->{Legend}{box} == 0 ) {
    $CompositeWidget->delete( $CompositeWidget->{RefChart}->{TAGS}{BoxLegend} );
  }

  if ( $CompositeWidget->class eq 'Mixed' ) {

    # Order displaying data
    $CompositeWidget->display_order;
  }

  # Ticks always in background
  $CompositeWidget->raise( $CompositeWidget->{RefChart}->{TAGS}{AllData},
    $CompositeWidget->{RefChart}->{TAGS}{AllTick} );

  # values displayed above the bars must be display over the bars
  my $showvalues = $CompositeWidget->cget( -showvalues );
  if ( defined $showvalues and $showvalues == 1 ) {
    $CompositeWidget->raise( $CompositeWidget->{RefChart}->{TAGS}{BarValues},
      $CompositeWidget->{RefChart}->{TAGS}{AllBars} );
  }
  return 1;
}

1;

__END__

=head1 NAME

Tk::Chart - Extension of Canvas widget to create a graph like GDGraph. 

=head1 SYNOPSIS

use Tk::Chart::B<ModuleName>;

=head1 DESCRIPTION

B<Tk::Chart> is a module to create and display graphs on a Tk widget. 
The module is written entirely in Perl/Tk.

You can set a background gradient color by using L<Tk::Canvas::GradientColor> methods.

You can change the color, font of title, labels (x and y) of graphs.
You can set an interactive legend. The axes can be automatically scaled or set by the code.

When the mouse cursor passes over a plotted line, bars, pie or its entry in the legend, 
its entry will be turned to a color to help identify it. 

You can use 3 methods to zoom (vertically, horizontally or both).

L<Tk::Chart::Lines>, 
Extension of Canvas widget to create lines graph. 
With this module it is possible to plot quantitative variables according to qualitative variables.

L<Tk::Chart::Splines>, 
To create lines graph as B<B>E<eacute>B<zier curve>. 

L<Tk::Chart::Points>, 
Extension of Canvas widget to create point lines graph. 

L<Tk::Chart::Areas>, 
Extension of Canvas widget to create an area lines graph. 

L<Tk::Chart::Bars>,  
Extension of Canvas widget to create bars graph with vertical bars.

L<Tk::Chart::Pie>,  
Extension of Canvas widget to create a pie graph. 

L<Tk::Chart::Mixed>,  
Extension of Canvas widget to create a graph mixed with lines, lines points, splines, bars, points and areas. 

L<Tk::Chart::Boxplots>,  
Extension of Canvas widget to create boxplots graph. 

=head1 EXAMPLES

See the samples directory in the distribution, and read documentations for each modules Tk::Chart::B<ModuleName>.

=head1 SEE ALSO

See L<Tk::Chart::FAQ>, L<Tk::Canvas::GradientColor>, L<GD::Graph>, L<Tk::Graph>, L<Tk::LineGraph>, L<Tk::PlotDataset>, L<Chart::Plot::Canvas>.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::Chart
    perldoc Tk::Chart::Lines
    perldoc Tk::Chart::Splines
    perldoc Tk::Chart::Points
    perldoc Tk::Chart::Bars
    perldoc Tk::Chart::Areas
    perldoc Tk::Chart::Mixed
    perldoc Tk::Chart::Pie
    perldoc Tk::Chart::FAQ
    perldoc Tk::Chart::Boxplots

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
