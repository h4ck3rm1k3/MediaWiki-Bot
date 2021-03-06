use strict;
use warnings;
use Test::More 0.88;

use MediaWiki::Bot;
my $t = __FILE__;

my $host     = $ENV{'PWPMakeTestSetWikiHost'} || 'test.wikipedia.org';
my $username = $ENV{'PWPUsername'};
my $password = $ENV{'PWPPassword'};
plan skip_all => 'Login with patrol rights required'
    unless $host and $username and defined $password;

my $bot = MediaWiki::Bot->new({
    agent => "MediaWiki::Bot tests ($t)",
    login_data => {
        username => $username,
        password => $password,
        do_sul => 0,
    },
    host => $host,
});

my $tests_run = 0;
{
    my @rc = $bot->recentchanges(0, 5);
    foreach my $change (@rc) {
        if ($change->{type} eq 'edit') {
            my $success = $bot->patrol($change->{rcid});

            if ($bot->{error}->{details} and $bot->{error}->{details} =~ m/^(?:permissiondenied|badtoken)/) {
                pass q{Account isn't permitted to patrol};
                $tests_run++;
                last;
            }
            else {
                ok $success, 'Patrolled OK';
                $tests_run++;
            }
        }
    }
}

{
    my @rc = $bot->recentchanges(0, 5, { hook => \&mysub });

    sub mysub {
        my ($res) = @_;
        foreach my $hashref (@$res) {
            next unless defined $hashref->{rcid} and $hashref->{type} eq 'edit';
            my $success = $bot->patrol($hashref->{rcid});

            if ($bot->{error}->{details} and $bot->{error}->{details} =~ m/^(?:permissiondenied|badtoken)/) {
                pass q{Account isn't permitted to patrol};
                $tests_run++;
                last;
            }
            else {
                ok $success, 'Patrolled the page OK';
                $tests_run++;
            }
        }
    }
}

done_testing($tests_run);
