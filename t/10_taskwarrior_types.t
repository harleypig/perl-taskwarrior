## no critic qw( Modules::RequireEndWithOne )

use Test::Most tests => 3;
use Test::Trap;

use Data::Dumper;
use File::Temp qw( tempdir tempfile );
use Log::Any::Test;
use Log::Any qw( $log );

use Taskwarrior qw( task );

# Use https://metacpan.org/pod/Test::TypeTiny

my ( $taskpath, $taskdir, $taskrc, $taskrc_fh );

BEGIN {

  $taskdir = tempdir( CLEANUP => 1 );
  ( $taskrc_fh, $taskrc ) = tempfile( UNLINK => 1 );

  print $taskrc_fh "data.location=$taskdir";

  ## no critic qw( Variables::RequireLocalizedPunctuationVars )
  $ENV{TASKRC} = $taskrc;

  ## no critic qw( InputOutput::ProhibitBacktickOperators )
  $taskpath = qx'which task 2>&1';

  if ( $? ) {

    plan skip_all => 'cannot find task executable'
      if $taskpath =~ /^which: no task/;

    plan skip_all => $taskpath;

  }

  chomp $taskpath;

} ## end BEGIN

my $task = task( '_version' );
ok( $task,                 'task returned something' );
ok( !$task->is_terminated, 'task did not terminate' );

my $chk_cmdline = "$taskpath _version";
my $got_cmdline = join ' ', $task->cmdline;
is( $chk_cmdline, $got_cmdline, 'got expected cmdline' );

#note( 'options: ', Dumper $task->options );
#note( 'pid: ',     $task->pid );

my @chk_stdout = $task->stdout->getlines;
chomp @chk_stdout;
my $chk_stdout = join ' ', @stdout;

note( 'stdout:', join ' ', @stdout );

my @stderr = $task->stderr->getlines;
chomp @stderr;
note( 'stderr:', join ' ', @stderr );

note( sprintf '%s: %s', $_, $task->$_ || 'undef' ) for qw( exit signal core );
