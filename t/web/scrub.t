#!/usr/bin/perl
use strict;
use warnings;

use RT::Test nodb => 1, tests => 10;
use RT::Interface::Web; # This gets us HTML::Mason::Commands
use Test::LongString;

{
    my $html = 'This is a test of <span style="color: rgb(255, 0, 0); ">color</span> and <span style="font-size: 18px; "><span style="font-family: Georgia, serif; ">font</span></span> and <em><u><strike><strong>boldness</strong></strike></u></em>.';
    is_string(scrub_html($html), $html, "CKEditor produced HTML sails through");
}

{
    my $html = '<p style="text-align: right; ">
        And <span style="color: rgb(255, 0, 0); "><span style="font-size: 16px; "><span style="font-family: Georgia, serif; ">alignment with color</span></span></span>?</p>';
    is_string(scrub_html($html), $html, "CKEditor produced HTML sails through");
}

{
    my $html = 'This is a test of <span style="color: rgb(255, 0, 0); content: url(/Nasty/URL);">color</span> and <span style="font-size: 18px; "><span style="font-family: Georgia, serif; ">font</span></span> and <em><u><strike><strong>boldness</strong></strike></u></em>.';
    my $expected = 'This is a test of <span>color</span> and <span style="font-size: 18px; "><span style="font-family: Georgia, serif; ">font</span></span> and <em><u><strike><strong>boldness</strong></strike></u></em>.';
    is_string(scrub_html($html), $expected, "nasty CSS not allowed through");
}

{
    my $html = 'Let\'s add some <span style="color: blue; font-family: Georgia">color</span> up in <span style="color: #DEADBE">here</span>.';
    is_string(scrub_html($html), $html, "multiple props and color specs allowed");
}

{
    my $html = q[<span lang=EN-US style='font-family:"Century Gothic","sans-serif";'>oh hai I'm some text</span>];
    my $expected = q[<span lang="EN-US" style="font-family:&quot;Century Gothic&quot;,&quot;sans-serif&quot;;">oh hai I'm some text</span>];
    is_string(scrub_html($html), $expected, "font lists");
}

{
    my $html = q[<span lang=EN-US style='font-size:7.5pt;font-family:"Century Gothic","sans-serif";color:#666666;mso-fareast-language:IT'>oh hai I'm some text</span>];
    my $expected = q[<span lang="EN-US" style="font-size:7.5pt;font-family:&quot;Century Gothic&quot;,&quot;sans-serif&quot;;color:#666666;mso-fareast-language:IT">oh hai I'm some text</span>];
    is_string(scrub_html($html), $expected, "outlook html");
}

{
    no warnings 'utf8';
    my $html = qq[Some content\N{U+FFFF}here];
    my $expected = q[Some contenthere];
    my $got = eval{scrub_html($html)};
    ok(!$@, "Testing U+FFFF didn't die");
    is_string($got, $expected, "U+FFFF non-character");

    # This may die _hard_, escaping even the eval.
    $got = eval{scrub_html("<p>content</p>")};
    ok(!$@, "Later uninteresting calls also don't die");
    is_string($got, "<p>content</p>", "Later uninteresting calls return the right value");
}

sub scrub_html {
    return HTML::Mason::Commands::ScrubHTML(shift);
}

