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

eval { require Test::Compile };

plan skip_all => 'Test::Compile required for these tests'
  if $@;

use File::Find::Rule;

my @binfiles = File::Find::Rule->file()->in( qw( bin ) );
my @plfiles  = File::Find::Rule->file()->name( '*.pl', '*.t' )->in( qw( lib t ) );
my @pmfiles  = File::Find::Rule->file()->name( '*.pm' )->in( qw( lib t ) );

plan tests => scalar @binfiles + scalar @plfiles + scalar @pmfiles;

Test::Compile::pl_file_ok( $_, "$_ compiles" ) for @binfiles, @plfiles;
Test::Compile::pm_file_ok( $_, "$_ compiles" ) for @pmfiles;
