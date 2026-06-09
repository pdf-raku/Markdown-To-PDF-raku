grammar Markdown::To::PDF::Grammar {

    token TOP { [<block> | <block=.sep-line>]* }
    token ww { \w <![*]>\w | ^^ \w | \w $$ }
    token ws { <!ww>\h* }
    token eol {[\n|$]}

    proto token sep-line {*}
    token sep-line:sym<blank> {<.blank-line>}
    token blank-line { ^^ \h* <.eol>}
    token sep-line:sym<hr>    { ^^ '-'+ <.eol>}
    proto token md {*}
    token md:sym<link> { '[' ~ ']' $<name>=.*? '(' ~ ')' $<url>=.*? }
    token md:sym<styled> {('*'**1..3 | '_'**1..3) <word>* $0?}
    rule word {[<md>||<![*_]>(\S+)] }

    proto token block {*}
    token fence { <[`~]> ** 3..* }
    rule name { <alpha>+}
    token block:sym<fenced-code> {
        ^^ [<fence><name>?<.eol>] ~ [$<fence><.eol>] $<code>=.*?
    }
    token quote-line { \h**0..3 [$<q>='>' \h*]+ <word>* <.eol> }
    token block:sym<quoted> { <quote-line>+ }
    token indented-code { ^^ $<indent>=[\h**4 \h*] $<line>=\N* <.eol>}
    token block:sym<indented-code> {
        <line=.indented-code> [<line=.indented-code> | <line=.blank-line>]*
    }
    rule header-end {[ '#' ]* <.eol>}
    token block:sym<header> {^^ \h**0..3 $<level>='#'**1..6 \h+ [<!header-end><word>]+ <header-end> }
    rule bp {<[-+*]> }
    token list-item {^^ $<indent>=\h**0..3 <.bp><word>* <.eol> [<!list-item><block>]?}
    token block:sym<list> { <list-item>+ }
    token digits {<digit>+ }
    token num { <digits> +%% \. }
    token olist-item {^^ $<indent>=\h**0..3 <num> \h* <word>* <.eol> [<!olist-item><block>]?}
    token block:sym<olist> { <olist-item>+ }
    proto token underline {*}
    token underline:sym<single> {^^ '-'+ <.eol> }
    token underline:sym<double> {^^ '='+ <.eol> }
    token text-line {^^ \h**0..3 <word>+ <.eol>}
    token block:sym<paragraph> { <text-line> [<!underline><text-line>]* <underline>? }
}
