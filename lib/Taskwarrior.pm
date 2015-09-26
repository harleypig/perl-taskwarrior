package Taskwarrior;

# ABSTRACT: Taskwarrior is a command line task list manager. This package is an interface to that application.

use strict;
use warnings;
use feature ();

use Carp;
use Data::Dumper;
use Log::Any qw( $log );

use parent 'Exporter';

# VERSION

=for stopwords  Taskwarrior namespace unimport logmsg prepends msg

=head1 SYNOPSIS

  use Taskwarrior qw( :all );

=head1 DESCRIPTION

This is the main module for the Taskwarrior project. All modules in the
Taskwarrior namespace should use this module.

Using C<Taskwarrior> is equivalent to the following code.

  use strict;
  use warnings;
  use feature qw( say state );

This module also exports a number of utility methods that make logging easier,
a dumper method that uses Data::Dumper and the
L<Carp|https://metacpan.org/pod/Carp> methods C<carp> and C<croak> are
exported.

=cut

=head1 EXPORT

This module does not export anything automatically.

When C<:all> is included in the use line (see SYNOPSIS) the following methods
are exported into the calling codes namespace.

  alert carp critical croak debug dumper emergency error info notice warning

See the description for each method for details.

I don't know why, but if you include a specific method, e.g. C<use Taskwarrior qw(
alert );> does not work.  You will have to use ':all' until this issue is resolved.

=cut

our %EXPORT_TAGS = (

  all => [qw( alert carp critical croak debug dumper emergency error info notice warning )],

);

Exporter::export_ok_tags( 'all' );

=head1 SUBROUTINES AND METHODS

=head2 import

This method is not exported.

C<import> is called when C<use Taskwarrior> is invoked.

This is equivalent to the following code.

  use strict;
  use warnings;
  use feature qw( say state );

=cut

## no critic qw( Subroutines::RequireArgUnpacking )
## no critic qw( Subroutines::RequireFinalReturn )

sub import {

  warnings->import;
  strict->import;
  feature->import( qw( say state ) );

  __PACKAGE__->export_to_level( 1, @_ );

}

=head2 unimport

This method is not exported.

C<unimport> is called when C<no Taskwarrior> is invoked.

This is equivalent to the following code.

  no strict;
  no warnings;
  no feature;

=cut

## no critic qw( Subroutines::ProhibitBuiltinHomonyms )
## no critic qw( Subroutines::RequireFinalReturn )

sub unimport {

  warnings->unimport;
  strict->unimport;
  feature->unimport;

}

=head2 dumper

This method is exported.

C<dumper> is equivalent to the following code.

  Dumper $somevariable;

=cut

## no critic qw( Subroutines::RequireArgUnpacking )
sub dumper { return Dumper @_ }

#=head2 log
#
#This method is not exported.
#
#C<log> is the base method for the logging methods that are exported.
#
#=cut
#
#sub log {
#
#  my ( $package ) = caller;
#
#  # XXX: It seems wrong to me that this is done this way, but I can't make it
#  # work any other way and I don't have any more time to dink around with it.
#
#  Log::Any::Adapter->set( 'Syslog', facility => LOG_LOCAL6 );
#  return Log::Any->get_logger( category => $package );
#
#}

=head2 logmsg

This method is not exported.

If the value sent to C<logmsg> is a scalar, C<logmsg> figures out some basic
information about the environment of the calling code and prepends it to the
msg being sent to the log.

E.g., the code C<debug( 'Some debugging message' );> will send something like
the following to the log file.

  [Package::Name::method] Some debugging message

If the value sent to C<logmsg> is a reference then dumper will be used to dump
the contents of the variable. The subroutine name will not be prefixed.

C<logmsg> accepts multiple values. The following is valid.

  debug( 'Debugging FooBar', \%somehash );

This will send something like the following to the log.

  [Package::Name::method] Debugging FooBar
  $VAR1 = {
            key => 'value',
          }

=cut

sub logmsg {

  ## no critic qw( CodeLayout::ProhibitParensWithBuiltins )
  ## no critic qw( ValuesAndExpressions::ProhibitMagicNumbers )

  my @caller     = caller( 2 );
  my $subroutine = $caller[3];

  my $msg;

  for my $l ( @_ ) {

    if ( ref $l eq '' ) {

      chomp( my $line = $l );
      my $linebreak = $line =~ /\n/ ? "\n" : ' ';
      $msg .= "[$subroutine]$linebreak$line";

    } else {

      $msg .= sprintf "\n%s", dumper $l;

    }
  }

  return $msg;

} ## end sub logmsg

=head2 debug

=head2 info

=head2 notice

=head2 warning

=head2 error

=head2 critical

=head2 alert

=head2 emergency

These are the various log levels.

=cut

## no critic qw( Subroutines::RequireFinalReturn )
## no critic qw( Subroutines::RequireArgUnpacking )

sub debug     { $log->debug( logmsg( @_ ) ) }
sub info      { $log->info( logmsg( @_ ) ) }
sub notice    { $log->notice( logmsg( @_ ) ) }
sub warning   { $log->warning( logmsg( @_ ) ) }
sub error     { $log->error( logmsg( @_ ) ) }
sub critical  { $log->critical( logmsg( @_ ) ) }
sub alert     { $log->alert( logmsg( @_ ) ) }
sub emergency { $log->emergency( logmsg( @_ ) ) }

1;
