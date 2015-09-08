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

plan skip_all => 'Set TEST_PERLLINT if you want to test with Perl::Lint'
  unless exists $ENV{TEST_PERLLINT};

eval { require Test::Perl::Lint };

plan skip_all => 'Test::Perl::Lint required for these tests'
  if $@;

Test::Perl::Lint::all_policies_ok( { targets => [qw( bin lib )], } );
