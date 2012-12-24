#
#===============================================================================
#
#         FILE: api_tests.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Milovidov Mikhail (), milovidovwork@yandex.ru
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 24.12.2012 23:23:40
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Lingua::Translate::Bing;

use Test::More tests => 3;                      # last test to 

my $translator = Lingua::Translate::Bing->new(client_id => "BingTranslationTest", client_secret =>
    "2hW9esAQegd7cVAylBrDEXnD1QVoWJYHSirAXMkQg40=");

my $tokens = "tokens.xml";

if (-f $tokens) {
    unlink $tokens;
}

ok("Привет!" eq $translator->translate("Hello!", "ru"));
ok("Привет!" eq $translator->translate("Hello!", "ru"));

if (-f $tokens) {
    unlink $tokens;
}

ok("Привет!" eq $translator->translate("Hello!", "ru"));
