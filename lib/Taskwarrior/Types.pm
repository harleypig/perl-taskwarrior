package Taskwarrior::Types;

use utf8;
use Taskwarrior qw( :all );

use Type::Library-base;

use Log::Any qw( $log );
use Type::Tiny ();
use Type::Tiny::Class;
use Type::Utils-all;
use Types::Standard-all;
use Types::Common::Numeric qw( PositiveInt PositiveOrZeroInt );
use Types::Common::String qw( NonEmptySimpleStr );
use Types::Numbers qw( PerlSafeFloat );

sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }

my @datetypes = qw( Due End Entry Modified Scheduled Start Until Wait );
my @types     = qw( Annotation Depends Description Id Imask Mask Numeric Parent Project Recur Status Tags Urgency Uuid );

my %udas = do {
  $log->debug( '[Taskwarrior::Types] getting udas' );
  my @udas;
  for my $line ( qx{task _show} ) {

    next unless $line =~ /^uda\.(.*?)\.type=(.*)$/;
    my ( $name, $type ) = ( $1, $2 );

    # XXX: Need to move priority type here since it is a uda.
    next if $name eq 'priority';

    push @udas, ( $name, $type );

  }

  $log->debugf( 'Found udas: %s', \@udas ) if @udas;
  $log->debug( 'Found no udas' ) unless @udas;

  @udas;
};

our @EXPORT = ();
our %deflate;

my $meta = __PACKAGE__->meta;

################################################################
# Task has four basic types. We'll be using these mainly for date types and
# udas, but it's good to have these up front.
#
# NonEmptySimpleStr for the string type.
# http://taskwarrior.org/docs/design/task.html#type_string

$log->debug( 'Creating String type' );
my $_String = $meta->add_type(
  name   => 'String',
  parent => NonEmptySimpleStr,
);

$deflate{'String'} = sub { return $_[0] };

# Fixed strings should probably be handled on a case by case basis, see
# Priority below.
# http://taskwarrior.org/docs/design/task.html#type_fixedstring

# UUID type is also the name of a type below. Just make that type the parent
# of a type that needs to be UUID.
# http://taskwarrior.org/docs/design/task.html#type_uuid

# Int for the numeric type.
# http://taskwarrior.org/docs/design/task.html#type_int

$log->debug( 'Creating Numeric type' );
my $_Numeric = $meta->add_type(
  name   => 'Numeric',
  parent => Int,
);

$deflate{Numeric} = sub { return $_[0] };

# Date for the date type.
# http://taskwarrior.org/docs/design/task.html#type_date

#class_type Date, { class => 'Time::Piece' };
#my $_Date = $meta->class_type( 'Date', { class => 'Time::Piece' } );
my $_Date = Type::Tiny::Class->new( class => 'Time::Piece' );

$deflate{Date} = sub { return $_[0]->strftime( '%Y%m%dT%H%M%SZ' ) };

# Duration for the duration type.
# http://taskwarrior.org/docs/design/task.html#type_duration

my @durations = qw(

  annual biannual bimonthly biweekly biyearly daily days day d fortnight hours
  hour hrs hr h minutes mins min monthly months month mnths mths mth mos mo
  quarterly quarters qrtrs qtrs qtr q seconds secs sec s semiannual sennight
  weekdays weekly weeks week wks wk w yearly years year yrs yr y

);

my $durations_join = join '|', @durations;
my $durations_rx = qr/-?\d*($durations_join)/;

$log->debug( 'Creating Duration type' );
my $_Duration = $meta->add_type(
  name       => 'Duration',
  parent     => NonEmptySimpleStr,
  constraint => sub { $_ =~ /$durations_rx/ },
);

$deflate{Duration} = sub { return $_[0] };

# End of basic types
################################################################

$log->debug( 'Creating Id type' );
my $_Id = $meta->add_type(
  name   => 'Id',
  parent => PositiveInt,
);

$deflate{Id} = $deflate{Numeric};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_due
# http://taskwarrior.org/docs/design/task.html#attr_end
# http://taskwarrior.org/docs/design/task.html#attr_entry
# http://taskwarrior.org/docs/design/task.html#attr_modified
# http://taskwarrior.org/docs/design/task.html#attr_scheduled
# http://taskwarrior.org/docs/design/task.html#attr_start
# http://taskwarrior.org/docs/design/task.html#attr_until
# http://taskwarrior.org/docs/design/task.html#attr_wait

for my $datetype ( @datetypes ) {

  my $dt = "_$datetype";

  $log->debugf( 'Creating %s type', $dt );

  no strict 'refs';

  $$dt = $meta->add_type(
    name   => $datetype,
    parent => $_Date,
  );

  $log->debugf( 'Creating coercion for %s', $dt );

  coerce $$dt,
    from Undef, via { 'Time::Piece::localtime'->() },
    from Int,   via { 'Time::Piece'->strptime( $_, '%s' ) },
    from Str,   via { 'Time::Piece'->strptime( $_, '%Y%m%dT%H%M%SZ' ) };

  $deflate{$datetype} = $deflate{Date};

} ## end for my $datetype ( @datetypes)

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_status
my @statuses = qw( pending deleted completed waiting recurring );

$log->debug( 'Creating Status type' );
my $_Status = $meta->add_type(
  name    => 'Status',
  parent  => Enum [@statuses],
  message => "status may only contain @statuses",
);

$deflate{Status} = sub { return $_[0] };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_uuid
my $uuid_rx = qr/[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}/i;

$log->debug( 'Creating Uuid type' );
my $_Uuid = $meta->add_type(
  name       => 'Uuid',
  parent     => NonEmptySimpleStr,
  constraint => sub { $_ =~ $uuid_rx },
);

$deflate{Uuid} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_description
$log->debug( 'Creating Description type' );
my $_Description = $meta->add_type(
  name   => 'Description',
  parent => NonEmptySimpleStr,
);

$deflate{Description} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_recur
$log->debug( 'Creating Recur type' );
my $_Recur = $meta->add_type(
  name   => 'Recur',
  parent => $_Duration,
  message =>
    "recur may only contain an optional dash (-), an optional number and a unit (see http://taskwarrior.org/docs/design/task.html#type_duration )",
);

$deflate{Recur} = $deflate{Duration};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_mask
$log->debug( 'Creating Mask type' );
my $_Mask = $meta->add_type(
  name    => 'Mask',
  parent  => StrMatch [qr/^[WX+-]+$/],
  message => 'mask may only have one or more characters matching W, X, + or -',
);

$deflate{Mask} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_imask
$log->debug( 'Creating Imask type' );
my $_Imask = $meta->add_type(
  name   => 'Imask',
  parent => PositiveOrZeroInt,
);

$deflate{Imask} = $deflate{Numeric};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_parent
$log->debug( 'Creating Parent type' );
my $_Parent = $meta->add_type(
  name   => 'Parent',
  parent => $_Uuid,
);

$deflate{Parent} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_annotation
# XXX: annotation needs to handle sub object.
$log->debug( 'Creating Annotation type' );
my $_Annotation = $meta->add_type(
  name   => 'Annotation',
  parent => ArrayRef [NonEmptySimpleStr],
);

$deflate{Annotation} = sub { return 'annotation to json not supported yet' };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_project
$log->debug( 'Creating Project type' );
my $_Project = $meta->add_type(
  name   => 'Project',
  parent => NonEmptySimpleStr,
);

$deflate{Project} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_tags
$log->debug( 'Creating Tags type' );
my $_Tags = $meta->add_type(
  name   => 'Tags',
  parent => ArrayRef [ StrMatch [qr/^\w+$/] ],
);

$deflate{Tags} = sub { return @{ $_[0] } };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_priority
$log->debug( 'Creating Priority type' );
my $_Priority = $meta->add_type(
  name    => 'Priority',
  parent  => Enum [qw( H M L )],
  message => 'priority may only contain H, M or L',
);

$deflate{Priority} = sub { return $_[0] };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_depends
$log->debug( 'Creating Depends type' );
my $_Depends = $meta->add_type(
  name   => 'Depends',
  parent => ArrayRef [$_Uuid],
);

$log->debug( 'Creating coercion for Depends' );
coerce $_Depends, from Str, via { [ split /,/ ] };

$deflate{Depends} = sub { return @{ $_[0] } };

################################################################
$log->debug( 'Creating Urgency type' );
my $_Urgency = $meta->add_type(
  name   => 'Urgency',
  parent => PerlSafeFloat,
);

$deflate{Urgency} = sub { return $_[0] };

################################################################
# Add udas
for my $uda ( keys %udas ) {

  my $name     = ucfirst $uda;
  my $name_var = "_$name";

  #my $parent   = sprintf '_%s', ucfirst $udas{$uda}

  no strict 'refs';

  #  $$name_var = $meta->add_type(
  #  name   => $name,
  #  parent => "$parent",
  #);

  if ( $udas{$uda} eq 'string' ) {

    $log->debugf( 'Creating %s String type', $name );
    $$name_var = $meta->add_type( name => $name, parent => $_String );
    $deflate{$name} = $deflate{String};

  } elsif ( $udas{$uda} eq 'numeric' ) {

    $log->debugf( 'Creating %s Numeric type', $name );
    $$name_var = $meta->add_type( name => $name, parent => $_Numeric );
    $deflate{$name} = $deflate{Numeric};

  } elsif ( $udas{$uda} eq 'date' ) {

    $log->debugf( 'Creating %s Date type', $name );
    $$name_var = $meta->add_type( name => $name, parent => $_Date );
    $deflate{$name} = $deflate{Date};

  } elsif ( $udas{$uda} eq 'duration' ) {

    $log->debugf( 'Creating %s Duration type', $name );
    $$name_var = $meta->add_type( name => $name, parent => $_Duration );
    $deflate{$name} = $deflate{String};

  } else {

    _croak "Unknown uda type $udas{$uda}";

  }
} ## end for my $uda ( keys %udas)

1;
