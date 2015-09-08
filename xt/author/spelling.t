# https://metacpan.org/pod/Test::Spelling

## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Lax::RequireEndWithTrueConst )
## no critic qw( Lax::RequireExplicitPackage::ExceptForPragmata )
## no critic qw( Modules::RequireEndWithOne )
## no critic qw( Modules::RequireExplicitPackage )
## no critic qw( NamingConventions::Capitalization )
## no critic qw( OTRS::ProhibitRequire )
## no critic qw( Subroutines::ProhibitCallsToUndeclaredSubs )
## no critic qw( TestingAndDebugging::RequireUseStrict  )
## no critic qw( TestingAndDebugging::RequireUseWarnings )

BEGIN {

  use Test::Most;

  plan skip_all => 'these tests are for testing by the author'
    unless $ENV{AUTHOR_TESTING};

}

eval { require Test::Spelling };

plan skip_all => 'Test::Spelling required for these tests'
  if $@;

plan skip_all => 'Test::Spelling requires a working spell checker'
  unless Test::Spelling::has_working_spellchecker;

use File::Find::Rule;

my @files = Test::Spelling::all_pod_files();

plan tests => scalar @files;

# One word per line.
my $stopwords = '.stopwords';

if ( -f $stopwords && -r _ ) {
  if ( open my $FH, '<', $stopwords ) {
    my @stopwords = <$FH>;
    chomp @stopwords;
    Test::Spelling::add_stopwords( @stopwords );
  } else {
    diag( "Unable to open $stopwords: $!" );
  }
}

# XXX: Change this to explicitly checking each individual file.
Test::Spelling::pod_file_spelling_ok( $_ ) for @files;
