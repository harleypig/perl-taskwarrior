# https://metacpan.org/pod/Test::NoTabs

## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Lax::RequireEndWithTrueConst )
## no critic qw( Lax::RequireExplicitPackage::ExceptForPragmata )
## no critic qw( Modules::RequireEndWithOne )
## no critic qw( Modules::RequireExplicitPackage )
## no critic qw( NamingConventions::Capitalization )
## no critic qw( OTRS::ProhibitRequire )
## no critic qw( Subroutines::ProhibitCallsToUndeclaredSubs )
## no critic qw( Subroutines::ProhibitCallsToUnexportedSubs )
## no critic qw( TestingAndDebugging::RequireUseStrict  )
## no critic qw( TestingAndDebugging::RequireUseWarnings )
## no critic qw( Tics::ProhibitLongLines )

BEGIN {

  use Test::Most;

  plan skip_all => 'these tests are for testing by the author'
    unless $ENV{AUTHOR_TESTING};

}

eval { require Test::NoTabs };

plan skip_all => 'Test::NoTabs required for these tests'
  if $@;

use File::Find::Rule;

my @binfiles = File::Find::Rule->file()->in( qw( bin ) );
my @files = File::Find::Rule->file()->name( '[^\.]+', '*.p[ml]', '*.t' )->in( qw( lib t ) );

plan tests => scalar @binfiles + scalar @files;

Test::NoTabs::notabs_ok( $_ ) foreach @binfiles, @files;
