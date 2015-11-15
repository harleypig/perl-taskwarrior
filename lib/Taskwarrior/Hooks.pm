package Taskwarrior::Hooks;

# ABSTRACT: The library that handles hooks for the taskwarrior package.

use strict;
use warnings;
use feature 'state';

use Log::Any qw( $log );

use IO::Handle;
use JSON (); # XXX: Maybe move json to Taskwarrior::Task?
use Path::Tiny;
use Try::Tiny;

use Taskwarrior::Task -all;

use constant PROGNAME => path( $0 )->basename;

use constant IS_ADD    => PROGNAME =~ /^on-add-/;
use constant IS_EXIT   => PROGNAME =~ /^on-exit-/;
use constant IS_LAUNCH => PROGNAME =~ /^on-launch-/;
use constant IS_MODIFY => PROGNAME =~ /^on-modify-/;

# VERSION

sub hook_croak ($) {

  my ( $self, $msg ) = @_;
  $msg ||= 'No message passed to hook_croak';

  my @caller = caller( 1 );
  my ( $line, $subroutine ) = @caller[2,3];

  $msg = sprintf '[%s:%s] %s', $subroutine, $line, $msg;

  $log->critical( $msg );
  print "$msg\n";
  exit 1;

}

sub new {

  my ( $class ) = @_;

  $log->infof( '[new] Creating new %s object', __PACKAGE__ );

  my $self = bless {}, $class;

  $self->get_args;
  $self->get_stdin;

  return $self;

}

sub progname { return PROGNAME }

sub is_add    { return IS_ADD }
sub is_exit   { return IS_EXIT }
sub is_launch { return IS_LAUNCH }
sub is_modify { return IS_MODIFY }

sub get_args {

  my ( $self ) = @_;

  hook_croak '[get_args] ARGV already parsed'
    if exists $self->{argv};

  hook_croak '[get_args] ARGV is empty'
    unless @ARGV;

  $log->infof( '[get_args] Parsing ARGV' );

  $self->{argv} = { map { split /:/, $_, 2 } @ARGV };

  $log->debugf( '[get_args] Found %s', $self->{argv} );

  for my $sub ( keys %{ $self->{argv} } ) {

    $log->debugf( '[get_args] building %s command, returns %s', $sub, $self->{argv}{$sub} );
    no strict 'refs';
    *$sub = sub { return $_[0]->{argv}{$sub} };

  }
} ## end sub get_args

sub get_stdin {

  my ( $self ) = @_;

  hook_croak '[get_stdin] already got stdin'
    if exists $self->{input};

  $log->infof( '[get_stdin] Getting STDIN' );

  try {

    my $STDIN = IO::Handle->new;

    $STDIN->fdopen( fileno( STDIN ), 'r' )
      or die "Unable to open STDIN: $!\n";

    my @lines = $STDIN->getlines;

    die "An error occurred reading from STDIN: $!\n"
      if $STDIN->error;

    $log->debugf( "[get_stdin] Found %d lines\n%s", scalar @lines, @lines );

    my @json;
    push @json, $self->json_decode( $_ ) for @lines;

    $self->{input} = \@json;

    $self->{output} = $json[0] if $self->is_add;
    $self->{output} = $json[1] if $self->is_modify;

    #$self->{test}   = Taskwarrior::Task->new( $self->output );
    #use Data::Dumper;
    #$Data::Dumper::Sortkeys = 1;
    #$log->debug( Dumper $self->{test} );

  } ## end try
  catch { hook_croak "[get_stdin] ERROR: $_" };

  return;

} ## end sub get_stdin

sub get_input {

  my ( $self ) = @_;
  $log->debugf( '[get_input] Returning %s', $self->{input} );
  return wantarray ? @{ $self->{input} } : $self->{input};

}

sub output {

  my ( $self ) = @_;

  $log->debugf( '[output] Returning %s', $self->{output} );
  return $self->{output};

}

sub set_feedback {

  my ( $self, $feedback ) = @_;
  $log->debugf( '[set_feedback] Setting feedback to %s', $feedback );
  $self->{feedback} = $feedback;
  return;

}

sub get_feedback {

  my ( $self ) = @_;
  $log->debugf( '[get_feedback] Returning %s', $self->{feedback} );
  return $self->{feedback};

}

sub done {

  my ( $self ) = @_;

  $log->info( '[done] Dumping output and feedback, if they exist' );

  my $string;

  if ( $self->is_add || $self->is_modify ) {

    hook_croak '[done] json output is expected but no output is available'
      unless exists $self->{output} && defined $self->{output} && ref $self->{output} eq 'HASH';

    $string .= $self->json_encode( $self->{output} );
    $string .= "\n";

  }

  $string .= $self->get_feedback
    if exists $self->{feedback} && defined $self->{feedback};

  $log->debugf( '[done] Dumping %s', $string );

  return print $string;

} ## end sub done

sub json {

  my ( $self ) = @_;
  return $self->{json} ||= JSON->new->utf8;

}

sub json_encode {

  my ( $self, $json_data ) = @_;
  my $json_string;

  try {
    $json_string = $self->json->shrink->canonical->encode( $json_data );
  }
  catch { hook_croak "[json_encode] $_" };

  return $json_string;

}

sub json_decode {

  my ( $self, $json_string ) = @_;
  my $json_data;

  try {
    $json_data = $self->json->allow_nonref->decode( $json_string );
  }
  catch { hook_croak "[json_decode] $_" };

  return $json_data;

}

1;
