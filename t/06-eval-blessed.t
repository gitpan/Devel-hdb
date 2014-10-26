use strict;
use warnings;

use lib 't';
use HdbHelper;
use WWW::Mechanize;
use JSON;
use Devel::hdb::App;
use Scalar::Util;

use Test::More;
if ($^O =~ m/^MS/) {
    plan skip_all => 'Test hangs on Windows';
} else {
    plan tests => 29;
}

my $url = start_test_program();

my $json = JSON->new();
my $stack;

my $mech = WWW::Mechanize->new();
my $resp = $mech->get($url.'continue');
ok($resp->is_success, 'Run to breakpoint');

$resp = $mech->post("${url}eval", content => '$hash');
ok($resp->is_success, 'Get value of a blessed hash');
my $answer = $json->decode($resp->content);
ok(delete $answer->{data}->{result}->{__refaddr}, 'encoded has a refaddr');
is_deeply($answer->{data},
    {   expr => '$hash',
        result => { __blessed => 'HashThing',
                    __reftype => 'HASH',
                    __value => { a => 1 } }
    },
    'value is correct');
    
$resp = $mech->post("${url}eval", content => '$array');
ok($resp->is_success, 'Get value of a blessed array');
$answer = $json->decode($resp->content);
ok(delete $answer->{data}->{result}->{__refaddr}, 'encoded has a refaddr');
is_deeply($answer->{data},
    { expr => '$array',
      result => { __blessed => 'ArrayThing',
                  __reftype => 'ARRAY',
                  __value => [1,2,3] }
    },
    'value is correct');

$resp = $mech->post("${url}eval", content => '$scalar');
ok($resp->is_success, 'Get value of a blessed scalar');
$answer = $json->decode($resp->content);
ok(delete $answer->{data}->{result}->{__refaddr}, 'encoded has a refaddr');
is_deeply($answer->{data},
    { expr => '$scalar',
      result => { __blessed => 'ScalarThing',
                  __reftype => 'SCALAR',
                  __value => "a string" }
    },
    'value is correct');

$resp = $mech->post("${url}eval", content => '$code');
ok($resp->is_success, 'Get value of a blessed coderef');
$answer = $json->decode($resp->content);
my $coderefstr = delete $answer->{data}->{result}->{__value};
ok(delete $answer->{data}->{result}->{__refaddr}, 'encoded has a refaddr');
is_deeply($answer->{data},
    { expr => '$code',
      result => { __blessed => 'CodeThing',
                  __reftype => 'CODE' }
    },
    'value is correct');
like($coderefstr, qr{CODE\(0x\w+\)}, 'Coderef string is formatted properly');


$resp = $mech->post("${url}eval", content => '$file');
ok($resp->is_success, 'Get value of an IO::File instance');
$answer = $json->decode($resp->content);
ok(delete $answer->{data}->{result}->{__refaddr}, 'encoded has a refaddr');
my $handle_info = delete $answer->{data}->{result}->{__value}->{IO};
like($handle_info, qr(^\d+$), 'Filehandle looks ok');
ok(delete $answer->{data}->{result}->{__value}->{SCALAR}->{__refaddr}, 'embedded SCALAR has a refaddr');
like(delete $answer->{data}->{result}->{__value}->{NAME}, qr(GEN\d), 'glob name');
is_deeply($answer->{data},
    { expr => '$file',
      result => { __blessed => 'IO::File',
                  __reftype => 'GLOB',
                  __value => {
                        PACKAGE => 'Symbol',
                        IOseek => '0 but true',
                        SCALAR => {
                            __reftype => 'SCALAR',
                            __value => undef,
                        }
                    }}
    },
    'value is correct');

$resp = $mech->post("${url}eval", content => '$re');
ok($resp->is_success, 'Get value of a Regex instance');
$answer = $json->decode($resp->content);
ok(delete $answer->{data}->{result}->{__refaddr}, 'encoded has a refaddr');
is_deeply($answer->{data},
    { expr => '$re',
      result => { __reftype => 'REGEXP',
                  __value => [ 'abc', 'i' ],
                }
    },
    'value is correct');


$resp = $mech->post("${url}eval", content => '$complex');
ok($resp->is_success, 'Get value of a complex structure');
$answer = $json->decode($resp->content);
ok(delete $answer->{data}->{result}->{__refaddr}, 'top-level has a refaddr');
ok(delete $answer->{data}->{result}->{__value}->[0]->{__refaddr}, 'first list elt has a refaddr');
ok(delete $answer->{data}->{result}->{__value}->[1]->{__refaddr}, 'next list elt has a refaddr');
ok(delete $answer->{data}->{result}->{__value}->[2]->{__refaddr}, 'last list elt has a refaddr');
is_deeply($answer->{data},
    { expr => '$complex',
      result => { __reftype => 'ARRAY',
                  __blessed => 'ComplexThing',
                  __value => [
                    {   __reftype => 'HASH',
                        __blessed => 'HashThing',
                        __value => { a => 1 }
                    },
                    {   __reftype => 'ARRAY',
                        __blessed => 'ArrayThing',
                        __value => [ 1,2,3],
                    },
                    {   __reftype => 'SCALAR',
                        __blessed => 'ScalarThing',
                        __value => 'a string',
                    },
                ] }
    },
    'value is correct');



__DATA__
use IO::File;
my $hash = bless {a => 1 }, 'HashThing';
my $array = bless [ 1,2,3 ], 'ArrayThing';
my $string = "a string";
my $scalar = bless \$string, 'ScalarThing';
my $code = bless sub { 1; }, 'CodeThing';
my $file = IO::File->new(__FILE__);
my $re = qr(abc)i;
my $complex = bless [ $hash, $array, $scalar ], 'ComplexThing';
$DB::single=1;
1;
