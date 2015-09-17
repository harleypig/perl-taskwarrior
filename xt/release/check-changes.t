# https://metacpan.org/pod/Test::CheckChanges

## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Lax::RequireExplicitPackage::ExceptForPragmata )
## no critic qw( Modules::RequireExplicitPackage )
## no critic qw( OTRS::ProhibitRequire )
## no critic qw( TestingAndDebugging::RequireUseStrict  )

BEGIN {

  use Test::Most;

  plan skip_all => 'Getting false error "Failed test \'No Build or Makefile found\'"';

  plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};

}

eval { use Test::CheckChanges };

plan skip_all => 'Test::CheckChanges required for these tests'
  if $@;

Test::CheckChanges::ok_changes();
