grammar Markdown::To::PDF::Grammar {

    token TOP {<md(0)>}
    token md($*INDENT = 0, :continue($*CONTINUE-INDENT) is copy = False) {
        [<block=.link-def> || <block=.sep-line> || <block> || <scan> ]*
    }
    token eol {[\n|$] { $*CONTINUE-INDENT = False } }
    token ws { <!ww>\h* }

    proto token sep-line {*}
    token sep-line:sym<blank> {<.blank-line>}
    token blank-line { ^^ \h* <.eol>}
    token sep-line:sym<hr>    { ^^ '-'+ <.eol>}

    token absolute-uri {:i
        # Match scheme
        $<scheme>=[ https? | ftp ] '://'

        # Match domain name/host
        $<host>=[[\w+] +% '-'] +% \.

        # Match optional path, subpath and query strings (excluding ending punctuation like periods)
        [ '/' [ \w+ | <[/.?&=\-+%#]> ]* ]?
    }
    token uri {:i $<uri>=[<absolute-uri> | [ \w+ | <[/.?&=\-+%#]> ]+]}
    token url { '<' ~ '>' <uri> || <uri> }
    token anchor { '[' ~ ']' $<text>=[<anchor>|<-[\[\]]>*] }
    rule link-def { ^^ <ref=.anchor> ':' <url> <.eol> }

    proto token link {*}
    token link:sym<hyper>    { <text=.anchor> '(' ~ ')' $<url>=<.uri>? }
    token link:sym<ref>      { <text=.anchor> <ref=.anchor>? }
    token link:sym<quoted>   { '<' ~ '>' <url=.uri> }
    token link:sym<absolute> { <url=.absolute-uri> }

    proto token inline {*}
    token inline:sym<link> { [$<image>=\!]? <link> }
    token inline:sym<em1> {('*'**1..3) ~ '*'+ <words> }
    token inline:sym<em2> {('_'**1..3) ~ '_'+ <words> }
    token inline:sym<code> {(\`+) ~ $0 $<code>=.*? }
    token text {[<![*_<|]>\S]+}
    token words {<word>*}
    token word {[<inline>||<inline=.text>]<ws>?}

    proto token block {*}
    token fence { <.indent><[`~]> ** 3..* }
    rule name { <alpha>+}
    token block:sym<fenced-code> {
        ^^ [<fence><name>?\n] ~ [$<fence><.eol>] $<code>=.*?
    }
    token quote-line { <.indent> [$<q>='>' \h*]+ <words> <.eol> }
    token block:sym<quoted> { <quote-line>+ }
    token indented-code { <.code-indent> $<line>=\N* <.eol>}
    token block:sym<indented-code> {
        <line=.indented-code> [<line=.indented-code> | <line=.blank-line>]*
    }
    rule header-end {[ '#' ]* <.eol>}
    sub visual-indent(Str() $leading, Int :$tab-width = 8 --> Int) {
        my $col = 0;
        for $leading.Str.comb -> $char {
            if $char eq "\t" {
                # Advance to the next tab stop
                $col += $tab-width - ($col % $tab-width);
            } else {
                # Standard space (or other \h character)
                $col += 1;
            }
        }
        return $col;
    }

    token indent {
         :my $cont = $*CONTINUE-INDENT;
         :my $indent = $cont ?? 0 !! $*INDENT;
         [ <?{$cont}> | ^^ ]
         $<leading>=\h* <?{ $indent <= visual-indent($<leading>) < $indent + 4}>
    }

    token code-indent {
         :my $cont = $*CONTINUE-INDENT;
         :my $indent = $cont ?? 0 !! $*INDENT;
         [ <?{$cont}> | ^^ ]
         $<leading>=\h+
         <?{ visual-indent($<leading>) >= $indent + 4}>
    }

    token li-indent {^^ $<leading>=\h* <?{ $*INDENT <= visual-indent($<leading>) <= $*INDENT + 1}> }
    token block:sym<header> {<.indent> $<level>='#'**1..6 \h+ [<!header-end><word>]+ <header-end> }
    token bp {<[-+*]>}
    token list-item {:my $indent;
         $<leading>=[<.li-indent> <.bp> \h] { $indent = visual-indent($<leading>.Str) }
         <md($indent, :continue)>
    }
    token block:sym<list> { <list-item>+ }
    token digits {<digit>+ }
    token num { <digits> +%% \. }
    token olist-item {:my $indent;
        $<leading>=[<.li-indent> <num> \h] { $indent = visual-indent($<leading>.Str) }
        <md($indent, :continue)>
    }
    token block:sym<olist> { <olist-item>+ }
    proto token header-underline {*}
    token header-underline:sym<h1> {^^ '='+ <.eol> }
    token header-underline:sym<h2> {^^ '-'+ <.eol> }
    token para-line {<.indent> <word><words> <.eol>}
    token block:sym<para-or-header> { <para-line> [<!header-underline><para-line>]* <header-underline>? }
    token table-align {
        \h* $<left>=':'? '-' ** 3..* $<right>=':'? \h*
    }

    token table-delim {
        <.indent> '|'? [ <table-align> +% '|' ] '|'? \h* <.eol>
    }

    token table-cell-text {
        [ '\\|' | <!eol><-[|]> ]+
    }

    token table-cell-word {
        [ <inline> || <inline=.table-cell-text> ] $<ws>=\h*
    }

    token table-cell {
        \h* $<words>=[ <table-cell-word>* ]
    }

    token table-row {
        <.indent>
        [
            '|' [ <table-cell> +% '|' ] '|'?   # Leading pipe (trailing optional)

          | <table-cell> ** 2..* % '|'         # No leading pipe (needs >= 1 inner pipe)
        ]
        \h* <.eol>
    }

    token block:sym<table> {
        $<header>=<table-row>
        <table-delim>
        # Enforce GFM rule: header and delimiter column counts must match
        <?{ $<header><table-cell>.elems == $<table-delim><table-align>.elems }>
        [ <!blank-line> <!sep-line> $<body-row>=<table-row> ]*
    }

    # fallback, when all else fails
    token scan {<indent> | <!after ^^\h*>.}
}
