# A set of Markdown::Grammar actions to produce
# a PDF-Tags-Tree data structure
unit class Markdown::To::PDF::Actions;

has $!Lang = 'en';

use Method::Also;

method TOP($/) {
    my @Document = :$!Lang;
    @Document.append: .made for @<block>;
    make (:@Document);
}

method sep-line:sym<hr>($/) {
    make 'Artifact' => [role => 'HR', Placement => 'Block']
}

method sep-line:sym<blank>($/) {
    make [];
}

method word($/) {
    make $<md> ?? $<md>.made !! $0.Str
}

method quote-line($/) {
    make @<word>>>.made.join: ' ';
}

method indented-code($/) {
    make $<line>.Str;
}

method blank-line($/) {
    make '';
}
method block:sym<indented-code>($/) {
    make 'P' => [:Code[ @<line>>>.made.join: "\n" ]];
}

method block:sym<quoted>($/) {
    my @P = @<quote-line>>>.made;
    make 'BlockQuote' => [:@P];
}

method block:sym<header>($/) {
    my UInt $level = $<level>.chars;
    my @words = @<word>>>.made;
    make 'H' ~ $level => @words;
}

method list-item($/) {
    my @P = @<word>>>.made;
    @P.append: .made with $<block>;
    make 'LI' => [:@P];
}

method block:sym<list>($/) {
    my @L = $<list-item>>>.made;
    make (:@L);
}

method olist-item($/) {
    my @Lbl = $<num>.Str;
    my @P   = @<word>>>.made;
    make 'LI' => [:@Lbl, :@P];
}

method block:sym<olist>($/) {
    my @L = $<olist-item>>>.made;
    make (:@L);
}

method text-line($/) {
    make @<word>>>.made;
}

method block:sym<paragraph>($/) {
    my @P;
    @P.append: .made for @<text-line>;
    if $<underline> {
        $_ = :U($_) for @P;
    }
    make (:@P);
}

