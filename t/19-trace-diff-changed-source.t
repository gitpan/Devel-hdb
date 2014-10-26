use strict;
use warnings;

use lib 't';
use HdbHelper;
use WWW::Mechanize;
use JSON;
use File::Temp;

use Test::More;
if ($^O =~ m/^MS/) {
    plan skip_all => 'Test hangs on Windows';
} else {
    plan tests => 9;
}

my $program_source = <<'PROGRAM';
    f($a);
    # EMPTY_LINE
    sub f {
        if ($a) {
            4;
        } else {
            6;
        }
        8;
    }
PROGRAM

my $program_file = File::Temp->new();
$program_file->close();

my $trace_file = File::Temp->new();
$trace_file->close();

my($url, $pid) = start_test_program('-file' => $program_file->filename,
                                    '-source' => $program_source,
                                    '-module_args' => 'trace:'.$trace_file->filename);

local $SIG{ALRM} = sub {
    ok(0, 'Test program did not finish');
    exit;
};
alarm(5);
waitpid($pid, 0);
ok(-s $trace_file->filename, 'Program generated a trace file');

# Run it again, but remove the line "# EMPTY_LINE" to make the raw line number different
$program_source =~ s/# EMPTY_LINE\n//;

my $url2 = start_test_program('-file' => $program_file->filename,
                              '-source' => $program_source,
                              '-module_args' => 'follow:'.$trace_file->filename);
isnt($url2, $url, 'Start test program again in follow mode');

my $mech = WWW::Mechanize->new();
my $resp = $mech->post($url2.'eval', content => '$a = 1' );
ok($resp->is_success, 'Set test variable to 1');

$resp = $mech->get($url2.'continue');
ok($resp->is_success, 'continue');

# expecting 'stack' and 'trace_diff' messages
my $json = JSON->new();
my @messages = sort { $a->{type} cmp $b->{type} } @{ $json->decode( $resp->content) };

is($messages[0]->{type}, 'stack', 'Got stack message');
is($messages[0]->{data}->[0]->{line}, 4, 'Stopped on differing line');

is($messages[1]->{type}, 'trace_diff', 'Got trace_diff message');
my $diff_data = $messages[1]->{data};
is($diff_data->{line}, 4, 'Diff data shows actual line');
is($diff_data->{expected_line}, 6, 'Diff data shows expected line');


