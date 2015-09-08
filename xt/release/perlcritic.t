## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Lax::RequireExplicitPackage::ExceptForPragmata )
## no critic qw( Modules::RequireExplicitPackage )
## no critic qw( OTRS::ProhibitRequire )
## no critic qw( TestingAndDebugging::RequireUseStrict  )

BEGIN {

  use Test::Most;

  plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};

}

eval { require Test::Perl::Critic };

plan skip_all => 'Test::Perl::Critic required for these tests'
  if $@;

use File::Find::Rule;

my @binfiles = File::Find::Rule->file()->in( qw( bin ) );
my @files = File::Find::Rule->file()->name( '[^\.]+', '*.p[ml]', '*.t' )->in( qw( lib t ) );

plan tests => scalar @binfiles + scalar @files;

my $rcfile = '.perlcriticrc';
Test::Perl::Critic->import( -profile => $rcfile );

TODO: {

  local $TODO = 'Need to fix these as time permits.';

  critic_ok( $_, "PerlCritic test for $_" ) for @binfiles, @files;

}
