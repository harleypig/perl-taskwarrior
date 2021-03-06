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

eval { require Test::NoSmartComments };

plan skip_all => 'Test::NoSmartComments required for these tests'
  if $@;

Test::NoSmartComments::no_smart_comments_in_all();
Test::NoSmartComments::no_smart_comments_in_tests();
done_testing();
