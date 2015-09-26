## no critic qw( BuiltinFunctions::ProhibitStringyEval )
## no critic qw( ErrorHandling::RequireCheckingReturnValueOfEval )
## no critic qw( Modules::RequireEndWithOne )
## no critic qw( ValuesAndExpressions::ProhibitMagicNumbers )
## no critic qw( ValuesAndExpressions::RequireInterpolationOfMetachars )
## no critic qw( Variables::ProhibitUnusedVariables )

use Test::Most tests => 5;
use Test::Trap;
use Log::Any::Test;
use Log::Any qw( $log );

use Taskwarrior qw( :all );

subtest 'strict, warnings and features' => sub {

  plan tests => 6;

  eval '$x = 1;';
  like( $@, qr/Global symbol "\$x" requires explicit/, 'strict is enabled' );

  {
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings = shift };
    my $y =~ s/hi//;
    like( $warnings, qr/Use of uninitialized value/, 'warnings is enabled' );
  }

  ## no critic qw( ValuesAndExpressions::ProhibitImplicitNewlines )
  eval q!
  use Taskwarrior;
  #use Data::Dumper;

  BEGIN {
    #diag( Dumper \%^H );
    ok exists $^H{feature_say}, 'feature say is enabled';
    ok exists $^H{feature_state}, 'feature state is enabled';
  }!;

  eval 'say "# say() is available";';
  is( $@, '', 'say() is available' );

  eval 'state $mystateful = 1;';
  is( $@, '', 'state is available' );

};

subtest 'carping' => sub {

  plan tests => 5;

  SKIP: {

    skip 'carp not exported', 4 unless ok( __PACKAGE__->can( 'carp' ), 'Can do carp' );

    my $carp_msg = 'Carping is better than warning!';
    my @r = trap { carp $carp_msg };

    #$trap->diag_all;
    $trap->did_return( 'carp returned correctly' );
    $trap->stdout_is( '', 'carp stdout was empty' );
    $trap->warn_like( 0, qr/$carp_msg/, 'carp warned correctly' );
    ok( scalar @{ $trap->warn } == 1, 'carp only returned one warning' );

  }
};

subtest 'croaking' => sub {

  plan tests => 4;

  SKIP: {

    skip 'croak not exported', 3 unless ok( __PACKAGE__->can( 'croak' ), 'Can do croak' );

    my $croak_msg = 'Croaking is better than dying!';
    my @r = trap { croak $croak_msg };

    #$trap->diag_all;
    $trap->did_die( 'croak died correctly' );
    $trap->die_like( qr/$croak_msg/, 'croak reported correct message' );
    $trap->quiet( 'croak was quiet' );

  }
};

subtest 'dumping' => sub {

  plan tests => 2;

  SKIP: {

    skip 'dumper not exported', 1 unless ok( __PACKAGE__->can( 'dumper' ), 'Can do dumper' );

    my $got_dumper = dumper { test => 'one' };

    ## no critic qw( ValuesAndExpressions::ProhibitImplicitNewlines )
    my $expect_dumper = q!$VAR1 = {
          'test' => 'one'
        };
!;

    is( $got_dumper, $expect_dumper, 'dumper dumped dump' );

  }
};

subtest 'logging' => sub {

  my $prefix = '[main::__ANON__] ';

  my @levels = qw( debug info notice warning error critical alert emergency );

  #my @skipprefix = qw( notice warning );
  my @skipprefix = qw();
  my $skipprefix = join q{|}, @skipprefix;

  plan tests => scalar @levels * 2;

  for my $level ( @levels ) {

    my $method = __PACKAGE__->can( $level );

    SKIP: {

      skip "$level not exported", 1 unless ok( $method, "Can do $level" );

      my $msg = "This is a(n) $level message.";

      my $expected_msgs = { category => 'Taskwarrior', level => $level };
      $expected_msgs->{message} = $level =~ /^(?:$skipprefix)$/ ? $msg : "$prefix$msg";
      $expected_msgs = [$expected_msgs];

      $method->( $msg );
      my $got_msgs = $log->msgs;

      #diag( dumper { Expected => $expected_msgs, Got => $got_msgs } );
      cmp_deeply( $log->msgs, $expected_msgs, "$level logged correctly" );
      $log->clear;

    } ## end SKIP:
  } ## end for my $level ( @levels)
};
