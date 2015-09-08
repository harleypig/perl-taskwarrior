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

# Force author testing for this test.
local $ENV{AUTHOR_TESTING} = 1;

eval { require Test::Kwalitee };

plan skip_all => 'Test::Kwalitee required to test kwalitee.'
  if $@;

my @tests = qw(
);

# Move these to @tests as they are completed.

my @todo_tests = qw(

  has_abstract_in_pod has_buildtool has_changelog has_humanreadable_license
  has_license_in_source_file has_manifest has_meta_yml has_readme has_tests
  meta_json_conforms_to_known_spec meta_json_is_parsable
  meta_yml_conforms_to_known_spec meta_yml_is_parsable no_broken_auto_install
  no_broken_module_install no_symlinks use_strict

);

plan tests => scalar @tests + scalar @todo_tests;

# When @todo_tests is empty, fail so we can update this file.
## no critic qw( ValuesAndExpressions::RequireInterpolationOfMetachars )
ok( scalar @todo_tests > 0, '@todo_tests is not empty' );

Test::Kwalitee::kwalitee_ok( $_ ) for @tests;

TODO: {

  local $TODO = 'Need to fix these as time permits.';

  Test::Kwalitee::kwalitee_ok( $_ ) for @todo_tests;

}

done_testing;
