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

eval { require Test::Cmd };

plan skip_all => 'Test::Cmd required for these tests'
  if $@;

plan tests => 1;

Test::Cmd->import();

SKIP: {
  ## no critic qw( ValuesAndExpressions::ProhibitMagicNumbers )
  skip 'no tests have been created for this test file yet', 1;

  ok( 0, 'No tests created yet!' );

}
