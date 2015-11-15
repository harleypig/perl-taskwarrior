package Taskwarrior;

# ABSTRACT: Taskwarrior is a command line task list manager. This package is an interface to that application.

use utf8;
use strict;
use warnings;
use feature qw( state );

use Carp;
use Data::Dumper;
use Log::Any qw( $log );
use System::Command;

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
exportable.

Additionally, a call method that can be used to make system calls and a task
execute method is exportable that handles calls to the task executable.

=cut

=head1 EXPORT

This module does not export anything automatically.

When C<:all> is included in the use line (see SYNOPSIS) the following methods
are exportable into the calling codes namespace.

  alert call carp critical croak debug dumper emergency error info notice task warning

See the description for each method for details.

I don't know why, but including just a specific method, e.g. C<use Taskwarrior
qw( alert );> does not work.  You will have to use ':all' until this issue is
resolved.

=cut

our %EXPORT_TAGS = (

  all => [qw( alert call carp critical croak debug dumper emergency error info notice task warning )],

);

Exporter::export_ok_tags( 'all' );

# Begin hiding
{

=head1 SUBROUTINES AND METHODS

=head2 import

This method is not exportable.

C<import> is called when C<use Taskwarrior> is invoked.

This is equivalent to the following code.

  use utf8;
  use strict;
  use warnings;
  use feature qw( say state );
  use Carp;
  use Data::Dumper;

=cut

## no critic qw( Subroutines::RequireArgUnpacking )
## no critic qw( Subroutines::RequireFinalReturn )

  sub import {

    utf8->import;
    warnings->import;
    strict->import;
    feature->import( qw( say state ) );

    __PACKAGE__->export_to_level( 1, @_ );

  }

=head2 unimport

This method is not exportable.

C<unimport> is called when C<no Taskwarrior> is invoked.

This is equivalent to the following code.

  no utf8;
  no strict;
  no warnings;
  no feature;

=cut

## no critic qw( Subroutines::ProhibitBuiltinHomonyms )
## no critic qw( Subroutines::RequireFinalReturn )

  sub unimport {

    utf8->unimport;
    warnings->unimport;
    strict->unimport;
    feature->unimport;

  }

=head2 call

This method is exportable.

C<call> makes a system call and returns a C<System::Command> object. It is
purely a convenience wrapper.

=cut

  sub call { return System::Command->new( @_ ) }

=head2 task

This method is exportable.

C<task> takes whatever is passed to it and calls the task executable with
those parameters and returns the raw results to the caller.

No validation is performed. The caller is expected to handle any errors
reported by the task executable.

You can pass either a reference to an array or a list.

  my @task_parms = qw( pro:personal _ids );
  task( \@task_parms );

or

  task( @task_parms );

=cut

  sub _find_task_executable {

    state $taskpath = do {

      my $which = call( qw( which task ) );

      my @whicherr = $which->stderr->getlines;
      chomp @whicherr;

      if ( @whicherr > 0 ) {

        ## no critic qw( BuiltinFunctions::ProhibitBooleanGrep )
        croak 'cannot find task executable'
          if grep { /^which: no task/ } @whicherr;

        croak "Unexpected error finding task executable: @whicherr";

      }

      my @cmdpath = $which->stdout->getlines;
      chomp @cmdpath;
      $cmdpath[0];

    };

    return $taskpath;

  } ## end sub _find_task_executable

  sub task {

    my ( @parms ) = @_;

    croak 'task expects either a list or an arrayref'
      if ref $parms[0] && ref $parms[0] ne 'ARRAY';

    @parms = @{ $parms[0] }
      if ref $parms[0] eq 'ARRAY';

    return System::Command->new( _find_task_executable(), @parms )

  }

=head2 dumper

This method is exportable.

C<dumper> is equivalent to the following code.

  Dumper $somevariable;

=cut

## no critic qw( Subroutines::RequireArgUnpacking )
  sub dumper { return Dumper @_ }

=head2 logmsg

This method is not exportable.

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

}

# End hiding

1;
