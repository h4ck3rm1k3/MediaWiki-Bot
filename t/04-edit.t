use strict;
use warnings;
use Test::More;

use MediaWiki::Bot;
my $t = __FILE__;

my $username = $ENV{'PWPUsername'};
my $password = $ENV{'PWPPassword'};
my $login_data;
if (defined($username) and defined($password)) {
    $login_data = { username => $username, password => $password };
}
plan tests => ($login_data ? 4 : 2);

my $agent = "MediaWiki::Bot tests ($t)";

my $bot = MediaWiki::Bot->new({
    agent      => $agent,
    login_data => $login_data,
    host       => 'test.wikipedia.org',
});

my $title  = 'User:Mike.lifeguard/04-edit.t';
my $rand   = rand();
my $status = $bot->edit({
    page => $title,
    text => $rand,
    summary => $agent,
});

SKIP: {
    skip 'Cannot use editing tests: ' . $bot->{error}->{details}, 2 if
        defined $bot->{error}->{code} and $bot->{error}->{code} == 3;

    my $is = $bot->get_text($title);
    is($is, $rand, 'Did whole-page editing successfully');

    my $rand2 = rand();
    $status = $bot->edit({
        page    => $title,
        text    => $rand2,
        section => 'new',
        summary => $agent,
        minor   => 1,
    });
    $bot->purge_page($title);
    $is = $bot->get_text($title);
    my $ought = <<"END";
$rand

== $agent ==

$rand2
END
    is("$is\n", $ought, 'Did section editing successfully');
    if ($login_data) {
        my @hist = $bot->get_history($title, 1);
        ok($hist[0]->{minor}, 'Minor edit');

        $bot->edit({
            page    => $title,
            text    => $rand2.$rand,
            summary => $agent . ' (major)',
            minor   => 0,
        });
        @hist = $bot->get_history($title, 1);
        ok(!$hist[0]->{minor}, 'Not a minor edit') or diag explain \@hist;
    }
}
