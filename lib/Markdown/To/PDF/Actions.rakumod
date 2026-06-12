# A set of Markdown::Grammar actions to produce
# a PDF-Tags-Tree data structure
unit class Markdown::To::PDF::Actions;

has $!Lang = 'en';
has %!ref;

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

method anchor($/) { make $<text>.Str }

method link:sym<text-and-url>($/) {
    my $href = $<url>.Str;
    make 'Link' => [:$href, $<text>.made];
}

method link:sym<text-and-ref>($/) {
    my $text = $<text>.made;
    my $id = .made with $<ref>;
    $id ||= $text;

    my @Link = [Any, $text];
    if %!ref{$id}:exists {
        @Link[0] := %!ref{$id};
    }
    else {
        %!ref{$id} := @Link[0];
        %!ref{$id} = :href<#>;
    }
    make (:@Link);
}

method link-def($/) {
    my $id = $<ref>.made;
    my $href = $<url>.Str;
    %!ref{$id} = :$href;
    make [];
}

method link:sym<quoted>($/) {
    my $href = $<url>.Str;
    make 'Link' => [:$href, $href];
}

method link:sym<absolute>($/) {
    my $href = $<url>.Str;
    make 'Link' => [:$href, $href];
}

method inline:sym<link>($/) { make $<link>.made }

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

sub trim(@words) {
    @words.pop if @words.tail ~~ ' ';
    @words;
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
    make 'H' ~ $level => $<word>>>.made.&trim.&coalesce;
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

method para-line($/) {
    my @words = $<word>.made;
    @words.append: .made with $<words>;
    make @words.&trim;
}

method header-underline:sym<h1>($/) { make 'H1' }
method header-underline:sym<h2>($/) { make 'H2' }

method block:sym<para-or-header>($/) {
    my @words;
    for @<para-line> {
        @words.push: ' ' if @words;
        @words.append: .made;
    }

    my $P := @words.&coalesce;

    make do with $<header-underline> {
        .made => [:$P];
    }
    else {
        :$P;
    }
}
