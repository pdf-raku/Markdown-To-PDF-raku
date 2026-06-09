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

multi sub style(1, @made) {Em => @made}
multi sub style(2, @made) {Strong => @made}
multi sub style(3, @made) {Strong => (Em => @made)}

method inline:sym<link>($/) {
    my $href = $<url>.Str;
    make 'Link' => [:$href, $<text>.Str];
}

method inline:sym<em1>($/) {
    make $0.chars.&style: $<words>.made;
}

method inline:sym<em2>($/) {
    make $0.chars.&style: $<words>.made;
}

method inline:sym<code>($/) {
    my @Code = $<code>.Str;
    make (:@Code);
}

method text($/) { make $/.Str }

method word($/) {
    make $<ws>.chars ?? [$<inline>.made, ' '].Slip !! $<inline>.made;
}

sub coalesce(@words) {
    my @phrase;
    my Str $text;
    for @words -> $word {
        if $word.isa(Str) {
            $text ~= $word;
        }
        else {
            @phrase.push: $text if $text;
            $text = Nil;
            @phrase.push: $word;
        }
    }
    $text ?? @phrase.push($text) !! @phrase;
}
    
method words($/) {
    make @<word>>>.made.&coalesce;
}

method quote-line($/) {
    make $<words>.made;
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

method name($/) { make @<alpha>.join }

method block:sym<fenced-code>($/) {
    my @Code;
    @Code.push: 'role' => .made with $<name>;
    @Code.push: $<code>.Str;
    make 'P' => [:@Code];
}

method block:sym<quoted>($/) {
    my @words;
    for @<quote-line> {
        @words.append: .made;
        @words.append: "\n";
    }
    make 'BlockQuote' => [P => @words.&coalesce];
}

method block:sym<header>($/) {
    my UInt $level = $<level>.chars;
    make 'H' ~ $level => $<word>>>.made.&coalesce;
}

method list-item($/) {
    my @P = $<words>.made;
    @P.append: .made with $<block>;
    make 'LI' => [:@P];
}

method block:sym<list>($/) {
    my @L = $<list-item>>>.made;
    make (:@L);
}

method olist-item($/) {
    my @Lbl = $<num>.Str;
    my @P   = $<words>.made;
    make 'LI' => [:@Lbl, :@P];
}

method block:sym<olist>($/) {
    my @L = $<olist-item>>>.made;
    make (:@L);
}

method text-line($/) {
    my @words = $<word>.made;
    @words.append: .made with $<words>;
    make @words;
}

method block:sym<paragraph>($/) {
    my @words;
    for @<text-line> {
        @words.push: ' ' if @words && @words.tail ne ' ';
        @words.append: .made;
    }
    @words .= &coalesce;
    if $<underline> {
        warn "todo: underline";
    }
    make 'P' => @words;
}

