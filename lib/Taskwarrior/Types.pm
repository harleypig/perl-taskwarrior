package Taskwarrior::Types;

# ABSTRACT: The various data types for the Taskwarrior package.

## no critic qw( References::ProhibitDoubleSigils )
## no critic qw( TestingAndDebugging::ProhibitNoStrict )
## no critic qw( TestingAndDebugging::ProhibitProlongedStrictureOverride )

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

# VERSION

{
  ## no critic qw( Subroutines::ProhibitSubroutinePrototypes )
  ## no critic qw( Subroutines::ProhibitUnusedPrivateSubroutines )
  sub _croak ($;@) { require Error::TypeTiny; goto \&Error::TypeTiny::croak }
};

my @datetypes = qw( Due End Entry Modified Scheduled Start Until Wait );
my @types     = qw( Annotation Depends Description Id Imask Mask Numeric Parent Project Recur Status Tags Urgency Uuid );

our @EXPORT = ();
my %deflate;

my $meta = __PACKAGE__->meta;

################################################################
# Task has four basic types. We'll be using these mainly for date types and
# udas, but it's good to have these up front.

# NonEmptySimpleStr for the string type.
# http://taskwarrior.org/docs/design/task.html#type_string

debug( 'Creating String type' );
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

debug( 'Creating Numeric type' );
my $_Numeric = $meta->add_type(
  name   => 'Numeric',
  parent => Int,
);

$deflate{Numeric} = sub { return $_[0] };

# Date for the date type.
# http://taskwarrior.org/docs/design/task.html#type_date

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

debug( 'Creating Duration type' );
my $_Duration = $meta->add_type(
  name       => 'Duration',
  parent     => NonEmptySimpleStr,
  constraint => sub { $_[0] =~ /$durations_rx/ },
);

$deflate{Duration} = sub { return $_[0] };

# End of basic types
################################################################

debug( 'Creating Id type' );
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

  debug( 'Creating %s type', $dt );

  no strict 'refs';

  $$dt = $meta->add_type(
    name   => $datetype,
    parent => $_Date,
  );

  debug( 'Creating coercion for %s', $dt );

  coerce $$dt,
    from Undef, via { 'Time::Piece::localtime'->() },
    from Int,   via { 'Time::Piece'->strptime( $_, '%s' ) },
    from Str,   via { 'Time::Piece'->strptime( $_, '%Y%m%dT%H%M%SZ' ) };

  $deflate{$datetype} = $deflate{Date};

} ## end for my $datetype ( @datetypes)

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_status
my @statuses = qw( pending deleted completed waiting recurring );

debug( 'Creating Status type' );
my $_Status = $meta->add_type(
  name    => 'Status',
  parent  => Enum [@statuses],
  message => "status may only contain @statuses",
);

$deflate{Status} = sub { return $_[0] };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_uuid
my $uuid_rx = qr/[a-f\d]{8}(?:-[a-f\d]{4}){3}-[a-f\d]{12}/i;

debug( 'Creating Uuid type' );
my $_Uuid = $meta->add_type(
  name       => 'Uuid',
  parent     => NonEmptySimpleStr,
  constraint => sub { $_ =~ $uuid_rx },
);

$deflate{Uuid} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_description
debug( 'Creating Description type' );
my $_Description = $meta->add_type(
  name   => 'Description',
  parent => NonEmptySimpleStr,
);

$deflate{Description} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_recur
debug( 'Creating Recur type' );
my $_Recur = $meta->add_type(
  name   => 'Recur',
  parent => $_Duration,
  message =>
    'recur may only contain an optional dash (-), an optional number and a unit (see http://taskwarrior.org/docs/design/task.html#type_duration )',
);

$deflate{Recur} = $deflate{Duration};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_mask
debug( 'Creating Mask type' );
my $_Mask = $meta->add_type(
  name    => 'Mask',
  parent  => StrMatch [qr/^[WX+-]+$/],
  message => 'mask may only have one or more characters matching W, X, + or -',
);

$deflate{Mask} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_imask
debug( 'Creating Imask type' );
my $_Imask = $meta->add_type(
  name   => 'Imask',
  parent => PositiveOrZeroInt,
);

$deflate{Imask} = $deflate{Numeric};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_parent
debug( 'Creating Parent type' );
my $_Parent = $meta->add_type(
  name   => 'Parent',
  parent => $_Uuid,
);

$deflate{Parent} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_annotation
# XXX: annotation needs to handle sub object.
debug( 'Creating Annotation type' );
my $_Annotation = $meta->add_type(
  name   => 'Annotation',
  parent => ArrayRef [NonEmptySimpleStr],
);

$deflate{Annotation} = sub { return 'annotation to json not supported yet' };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_project
debug( 'Creating Project type' );
my $_Project = $meta->add_type(
  name   => 'Project',
  parent => NonEmptySimpleStr,
);

$deflate{Project} = $deflate{String};

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_tags
debug( 'Creating Tags type' );
my $_Tags = $meta->add_type(
  name   => 'Tags',
  parent => ArrayRef [ StrMatch [qr/^\w+$/] ],
);

$deflate{Tags} = sub { return @{ $_[0] } };

#################################################################
#debug( 'Creating Priority type' );
#my $_Priority = $meta->add_type(
#  name    => 'Priority',
#  parent  => Enum [qw( H M L )],
##  message => 'priority may only contain H, M or L',
#);
#
#$deflate{Priority} = sub { return $_[0] };

################################################################
# http://taskwarrior.org/docs/design/task.html#attr_depends
debug( 'Creating Depends type' );
my $_Depends = $meta->add_type(
  name   => 'Depends',
  parent => ArrayRef [$_Uuid],
);

debug( 'Creating coercion for Depends' );
coerce $_Depends, from Str, via { [ split /,/ ] };

$deflate{Depends} = sub { return @{ $_[0] } };

################################################################
debug( 'Creating Urgency type' );
my $_Urgency = $meta->add_type(
  name   => 'Urgency',
  parent => PerlSafeFloat,
);

$deflate{Urgency} = sub { return $_[0] };

################################################################
# Add udas

# http://taskwarrior.org/docs/design/task.html#attr_priority

debug( 'getting udas' );

my %uda;

## no critic qw( InputOutput::ProhibitBacktickOperators )
for my $line ( qx{task _show} ) {

  next unless $line =~ /^uda\.(.*?)\.(.*?)=(.*)$/;
  my ( $uda, $attr, $value ) = ( $1, $2, $3 );

  #next unless $attr eq 'type' || ( $attr eq 'values' && $value ne '' );
  next if ( $attr eq 'values' && $value eq '' ) || $attr ne 'type';

  my $name     = ucfirst $uda;
  my $name_var = "_$name";

  my $add_type = $uda{$name_var} ||= {};

  if ( $attr eq 'type' ) {

    my $deflate_type = ucfirst $value;
    my $parent_type  = "_$deflate_type";

    $add_type->{name} = $name;

    no strict 'refs';
    $add_type->{parent} = $$parent_type;
    $deflate{$deflate_type} = $deflate{$deflate_type};

  }

  if ( $attr eq 'values' ) {

    my @values = split /,/, $value;
    $add_type->{constraint} = Enum [@values];
    $add_type->{message} = "$name must be one of @values";

  }
} ## end for my $line ( qx{task _show})

### no critic qw( InputOutput::ProhibitBacktickOperators )
#for my $line ( sort qx{task _show} ) {
#
#  next unless $line =~ /^uda\.(.*?)\.(.*?)=(.*)$/;
#  my ( $uda, $attr, $type ) = ( $1, $2 );
#
#  my $name = ucfirst $uda;
#
#  _croak "$uda type was not defined before values"
#    if !exists $deflate{$name} && $attr eq 'values';
#
#  _croak "Don't know how to handle value for non-string type in $uda"
#    if $attr eq 'values' && "$deflate{$name}" ne "$deflate{String}";
#
#  next if $type eq '';
#
#  my $name_var = "_$name";
#
#  no strict 'refs';
#
#  if ( $attr eq 'values' ) {
#
#    debug( "Creating constraint for uda $name" );
#    next;
#
#  }
#
#  if ( $type eq 'string' ) {
#
#    debug( "Creating $name String type" );
#    $$name_var = $meta->add_type( name => $name, parent => $_String );
#    $deflate{$name} = $deflate{String};
#    next;
#
#  }
#
#  if ( $type eq 'numeric' ) {
#
#    debug( "Creating $name Numeric type" );
#    $$name_var = $meta->add_type( name => $name, parent => $_Numeric );
#    $deflate{$name} = $deflate{Numeric};
#    next;
#
#  }
#
#  if ( $type eq 'date' ) {
#
#    debug( "Creating $name Date type" );
#    $$name_var = $meta->add_type( name => $name, parent => $_Date );
#    $deflate{$name} = $deflate{Date};
#    next;
#
#  }
#
#  if ( $type eq 'duration' ) {
#
#    debug( "Creating $name Duration type" );
#    $$name_var = $meta->add_type( name => $name, parent => $_Duration );
#    $deflate{$name} = $deflate{String};
#    next;
#
#  }
#
#  _croak "Unknown uda type $type"
#    unless exists $deflate{$name};
#
#} ## end for my $line ( sort qx{task _show})

################################################################
# Return code ref for specified attribute that deflates object
# to string value for json.

sub deflate {

  my ( $self, $attribute ) = @_;

  croak "Unknown type ($attribute)"
    unless exists $deflate{$attribute};

  return $deflate{$attribute};

}

1;
