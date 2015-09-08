# https://metacpan.org/pod/Test::Synopsis

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

eval { require Test::Synopsis };

plan skip_all => 'Test::Synopsis required for these tests'
  if $@;

TODO: {
  local $TODO = 'Add synopsis to documentation.';

  # XXX: Change this to explicitly checking each individual file.
  Test::Synopsis::all_synopsis_ok();
}
