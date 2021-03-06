use strict;
use warnings;
use Test::More tests => 5;

use MediaWiki::Bot;
my $t = __FILE__;

my $bot = MediaWiki::Bot->new({
    agent   => "MediaWiki::Bot tests ($t)",
    host    => 'test.wikipedia.org',
});

if(defined($ENV{'PWPMakeTestSetWikiHost'})) {
    $bot->set_wiki($ENV{'PWPMakeTestSetWikiHost'}, $ENV{'PWPMakeTestSetWikiDir'});
}

my $namespace_id = 10;
my $page_limit = 1;

my @pages = $bot->get_pages_in_namespace($namespace_id);
like($pages[0], qr/^Template:/, 'Template namespace found');

@pages = $bot->get_pages_in_namespace($namespace_id, $page_limit);
is(scalar @pages, $page_limit, 'Correct number of pages retrieved');

$namespace_id = 'non-existent';
@pages = $bot->get_pages_in_namespace($namespace_id);

is($pages[0], undef, 'Error code received');
is($bot->{error}->{code}, 3, 'Error code in MediaWiki::Bot object');

$namespace_id = 6;
@pages = $bot->get_pages_in_namespace($namespace_id, 'max', { max => 0 });
cmp_ok(scalar @pages, '>', 500, 'Got more than 500 pages'); # RT 66790
