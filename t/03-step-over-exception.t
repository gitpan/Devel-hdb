use strict;
use warnings;

use lib 't';
use HdbHelper;
use WWW::Mechanize;
use JSON;

use Test::More;
if ($^O =~ m/^MS/) {
    plan skip_all => 'Test hangs on Windows';
} else {
    plan tests => 11;
}

my $url = start_test_program();

my $json = JSON->new();
my $stack;

my $mech = WWW::Mechanize->new();
my $resp = $mech->get($url.'stack');
ok($resp->is_success, 'Request stack position');
$stack = strip_stack($json->decode($resp->content));
is_deeply($stack,
    [ { line => 1, subroutine => 'main::MAIN' } ],
    'Stopped on line 1');

$resp = $mech->get($url.'stepover');
ok($resp->is_success, 'step over');
$stack = strip_stack($json->decode($resp->content));
is_deeply($stack,
    [ { line => 1, subroutine => '(eval)' },
      { line => 1, subroutine => 'main::MAIN' } ],
    'Stopped inside the eval line 1');

$resp = $mech->get($url.'stepover');
ok($resp->is_success, 'step over');
$stack = strip_stack($json->decode($resp->content));
is_deeply($stack,
  [ { line => 2, subroutine => 'main::MAIN' } ],
    'Stopped on line 2');

$resp = $mech->get($url.'stepover');
ok($resp->is_success, 'step over');
$stack = strip_stack($json->decode($resp->content));
is_deeply($stack,
  [ { line => 3, subroutine => 'main::MAIN' } ],
    'Stopped on line 3');

$resp = $mech->get($url.'stepover');
ok($resp->is_success, 'step over');
my @messages = sort { $a->{type} cmp $b->{type} } @{ $json->decode($resp->content) };
is($messages[0]->{data}->[0]->{subroutine},
    'Devel::Chitin::exiting::at_exit',
    'Stopped in at_exit()');
is_deeply($messages[1],
    { type => 'termination', data => { exit_code => 2 } },
    'Got termination message');


__DATA__
eval { do_die() };
wrap_die();
exit(2);
sub do_die {
    die "in do_die";
}
sub wrap_die {
    eval { do_die() };
}
