package Taskwarrior::Task;

# ABSTRACT: The main task handling module for the Taskwarrior package.

use strict;
use warnings;

use Log::Any qw( $log );

use Carp;
use Time::Piece;
use Types::Standard qw( Str );

use Taskwarrior::Types -all;

# VERSION

my @known_attributes = qx{task _columns};
chomp @known_attributes;

# Annotations are not considered to be columns, so we have to manually include
# it here.
push @known_attributes, 'annotation';

_build_methods();

sub _build_methods {

  $log->debug( '[_build_methods] creating methods' );

  for my $attribute ( sort @known_attributes ) {

    my $type = ucfirst $attribute;

    croak "[_build_methods] no type handler for $attribute"
      unless __PACKAGE__->can( $type );

    my $has_attribute   = "has_$attribute";
    my $set_attribute   = "set_$attribute";
    my $unset_attribute = "un$set_attribute";

    # # no critic qw( TestingAndDebugging::ProhibitNoStrict )
    ## no critic qw( TestingAndDebugging::ProhibitProlongedStrictureOverride )
    no strict 'refs';

    $log->debugf( '[_build_methods] creating %s', $set_attribute );
    *$set_attribute = sub {
      my ( $self, $value ) = @_;

      $value = $self->$type->assert_coerce( $value )
        if $self->$type->has_coercion;

      my $invalid = $self->$type->validate( $value );

      if ( $invalid ) {
        carp $invalid;
        return;
      }

      return $self->{data}{$attribute} = $value;

    };

    $log->debugf( '[_build_methods] creating %s', $unset_attribute );
    *$unset_attribute = sub { return delete $_[0]->{data}{$attribute} };

    $log->debugf( '[_build_methods] creating %s', $has_attribute );
    *$has_attribute = sub { return exists $_[0]->{data}{$attribute} };

    $log->debugf( '[_build_methods] creating %s', $attribute );
    *$attribute = sub { return $_[0]->{data}{$attribute} };

  } ## end for my $attribute ( @attributes)

  return;

} ## end sub _build_methods

sub new {

  my ( $class, $args ) = @_;

  croak 'new is expecting a hashref'
    unless defined $args && ref $args eq 'HASH';

  my $self = bless {}, $class;

  for my $arg ( keys %$args ) {

    my $set_attribute = "set_$arg";
    $self->$set_attribute( $args->{ $arg } );

  }

  return $self;

}

sub check_required {

  my ( $self ) = @_;

  my @required_attributes = qw( status uuid entry description );

  push @required_attributes, 'end'
    if $self->is_deleted || $self->is_completed;

  push @required_attributes, 'due'
    if $self->is_parent;

  push @required_attributes, 'wait'
    if $self->is_waiting;

  push @required_attributes, 'recur'
    if $self->is_recurring;

  # parent is required if this is a child task, but the only way to tell if
  # it's a child task is if it has a parent field. There's no real way to test
  # for this here.

  my @missing_required;

  for my $required_attribute ( @required_attributes ) {

    my $has_attribute = "has_$required_attribute";

    push @missing_required, $required_attribute
      unless $self->$has_attribute;

  }

  return @missing_required ? \@missing_required : undef;

}

sub is_pending   { return $_[0]->status eq 'pending' }
sub is_deleted   { return $_[0]->status eq 'deleted' }
sub is_completed { return $_[0]->status eq 'completed' }
sub is_waiting   { return $_[0]->status eq 'waiting' }
sub is_recurring { return $_[0]->status eq 'recurring' }

sub is_parent { return $_[0]->status eq 'recurring' && !$_[0]->has_parent }
sub is_child  { return $_[0]->status eq 'recurring' && $_[0]->has_parent }

sub is_new_recurrence {

  my ( $self ) = @_;

  return unless $self->is_child;

  # New recurrence entries modified field is copied from parent, so it will
  # have an earlier date than the entry field.

  return $self->modified - $self->entry <= 0;

}

sub TO_JSON {

  my ( $self ) = @_;

  my %json_data;

  $json_data{$_} = $Taskwarrior::Types::deflate->{ $_ }->( $self->_ )
    for keys %$self;

  return \%json_data;

}

1;
