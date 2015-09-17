# https://metacpan.org/pod/Test::CleanNamespaces

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

eval { require Test::CleanNamespaces };

plan skip_all => 'Test::CleanNamespaces required for these tests'
  if $@;

Test::CleanNamespaces::all_namespaces_clean();
done_testing();
