# https://metacpan.org/pod/Test::Pod::Coverage

## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Lax::RequireEndWithTrueConst )
## no critic qw( Lax::RequireExplicitPackage::ExceptForPragmata )
## no critic qw( Modules::RequireEndWithOne )
## no critic qw( Modules::RequireExplicitPackage )
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

eval { require Test::Pod::Coverage };

plan skip_all => 'Test::Pod::Coverage required for these tests'
  if $@;

eval { require Pod::Coverage::TrustPod };

plan skip_all => 'Pod::Coverage::TrustPod required for these tests'
  if $@;

Test::Pod::Coverage::all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::TrustPod' } );
