# https://metacpan.org/pod/Test::CheckDeps

## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( TestingAndDebugging::RequireUseStrict  )

BEGIN {

  use Test::Most;

  plan skip_all => 'these tests are for testing by the author'
    unless $ENV{AUTHOR_TESTING};

}

eval { require Test::CheckDeps };

plan skip_all => 'Test::CheckDeps required for these tests'
  if $@;

Test::CheckDeps::check_dependencies( 'suggests' );

done_testing();
