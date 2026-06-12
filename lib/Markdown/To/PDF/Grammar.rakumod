grammar Markdown::To::PDF::Grammar {

    token TOP { [<block=.link-def> || <block> | <block=.sep-line>]* }
    token ws { <!ww>\h* }
    token eol {[\n|$]}

    proto token sep-line {*}
    token sep-line:sym<blank> {<.blank-line>}
    token blank-line { ^^ \h* <.eol>}
    token sep-line:sym<hr>    { ^^ '-'+ <.eol>}

    token absolute-uri {:i
        # Match scheme
        $<scheme>=[ https? | ftp ] '://'

        # Match domain name/host
        $<host>=[\w+] +% \.

        # Match optional path, subpath and query strings (excluding ending punctuation like periods)
        [ '/' [ \w+ | <[/.?&=\-+%#]> ]* ]?
    }
    token uri {:i $<uri>=[<absolute-uri> | [ \w+ | <[/.?&=\-+%#]> ]+]}
    token url { '<' ~ '>' <uri> || <uri> }
    token anchor { '[' ~ ']' $<text>=<-[\[\]]>* }
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
    token text {[<![*_<]>\S]+}
    token words {<word>*}
    token word {[<inline>||<inline=.text>]<ws>}

    proto token block {*}
    token fence { <[`~]> ** 3..* }
    rule name { <alpha>+}
    token block:sym<fenced-code> {
        ^^ [<fence><name>?<.eol>] ~ [$<fence><.eol>] $<code>=.*?
    }
    token quote-line { \h**0..3 [$<q>='>' \h*]+ <words> <.eol> }
    token block:sym<quoted> { <quote-line>+ }
    token indented-code { ^^ $<indent>=[\h**4] $<line>=\N* <.eol>}
    token block:sym<indented-code> {
        <line=.indented-code> [<line=.indented-code> | <line=.blank-line>]*
    }
    rule header-end {[ '#' ]* <.eol>}
    token block:sym<header> {^^ \h**0..3 $<level>='#'**1..6 \h+ [<!header-end><word>]+ <header-end> }
    rule bp {<[-+*]> }
    token list-item {^^ $<indent>=\h**0..3 <.bp><words> <.eol> [<!list-item><block>]?}
    token block:sym<list> { <list-item>+ }
    token digits {<digit>+ }
    token num { <digits> +%% \. }
    token olist-item {^^ $<indent>=\h**0..3 <num> \h* <words> <.eol> [<!olist-item><block>]?}
    token block:sym<olist> { <olist-item>+ }
    proto token header-underline {*}
    token header-underline:sym<h1> {^^ '='+ <.eol> }
    token header-underline:sym<h2> {^^ '-'+ <.eol> }
    token para-line {^^ \h**0..3 <word><words> <.eol>}
    token block:sym<para-or-header> { <para-line> [<!header-underline><para-line>]* <header-underline>? }
}
