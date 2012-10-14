use strict;
use warnings;
use Test::More (skip_all => 'only for release testing')x!
               ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING});

use Test::MinimumVersion 0.101080;

# Unfortunately Perl::MinimumVersion does not check regexp features
# (?^: ... ) interests us
# But Regexp::Parser can check if the regexp can be parsed by 5.8.4

minimum_version_ok('lib/Number/Phone/FR/Full.pm', '5.008');
done_testing;
