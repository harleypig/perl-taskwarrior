# https://metacpan.org/pod/Test::Pod::Coverage

## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Lax::RequireExplicitPackage::ExceptForPragmata )
## no critic qw( Modules::RequireExplicitPackage )
## no critic qw( OTRS::ProhibitRequire )
## no critic qw( TestingAndDebugging::RequireUseStrict  )

BEGIN {

  use Test::Most;

  plan skip_all => 'these tests are for testing by the author'
    unless $ENV{AUTHOR_TESTING};

}

eval { require Test::Pod::Coverage };

plan skip_all => 'Test::Pod::Coverage required for these tests'
  if $@;

Test::Pod::Coverage->import;

plan tests => 1;

SKIP: {

  skip 'no tests set up for this test file yet', 1

  #Test::Pod::Coverage::all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
  #all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });

  #pod_coverage_ok( $_, "$_ is covered" ) for @packages;

}
