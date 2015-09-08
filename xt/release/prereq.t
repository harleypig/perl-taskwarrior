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

plan skip_all => 'Set TEST_PREREQ if you want to test with Test::Prereq'
  unless exists $ENV{TEST_PREREQ};

eval { require Test::Prereq::Build };

plan skip_all => 'Test::Prereq::Build required to test prerequisites.'
  if $@;

Test::Prereq::Build::prereq_ok();
