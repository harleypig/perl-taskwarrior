# https://metacpan.org/pod/Test::EOF

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

BEGIN {

  use Test::Most;

  plan skip_all => 'these tests are for testing by the author'
    unless $ENV{AUTHOR_TESTING};

}

eval { require Test::EOF };

plan skip_all => 'Test::EOF required for these tests'
  if $@;

Test::EOF::all_perl_files_ok( { maximum_newlines => 4 } );

done_testing();
