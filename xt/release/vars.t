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


eval { require Test::Vars };

plan skip_all => 'Test::Vars required for these tests'
  if $@;

use File::Find::Rule;

my @files = File::Find::Rule->file()->name( '*.pm' )->in( qw( lib t ) );

plan tests => scalar @files;

#my %ignore = ( ignore_vars => [qw( $ignore1 $ignore2 )] );

Test::Vars::vars_ok( $_, %ignore ) for @files;
