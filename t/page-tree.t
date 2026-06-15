use v6;
use Markdown::To::PDF::Grammar;
use Markdown::To::PDF::Actions;
use PDF::Render::Simple;
use PDF::API6;
use Test;

my $text = q:to/TEXT/;
## Markdown Test ##

This is a simple markdown document. It has
two lines.

---

It has two
paragraphs.
TEXT

sub parse-markdown($text) {
    my Markdown::To::PDF::Actions $actions .= new;
    Markdown::To::PDF::Grammar.parse: $text, :$actions;
    $/.made;
}

my PDF::Render::Simple $renderer .= new;

subtest 'basic document', {
    my Pair:D $doc-ast = $text.&parse-markdown;

    is-deeply $doc-ast, 'Document' => [
       :Lang<en>,
       :H2["Markdown Test"],
       :P["This is a simple markdown document. It has two lines."],
       :Artifact[:role<HR>, :Placement<Block>],
       :P["It has two paragraphs."],
    ];

    lives-ok {
        $renderer.render: $doc-ast;
    }, 'render'
}
## next text with lists

subtest 'block and list tests', {
    my Pair:D $doc-ast = parse-markdown q:to/TEXT/;
    Block and List tests
    ====================

     -  List One
     -  List Two

    > blockquote
    > fun

        code

         block

     -  Block List One

     -  Block List Two

     1. ol One
     2. ol Two

    * Other List One
    * Other List Two

    TEXT

    is-deeply $doc-ast , 'Document' => [
     :Lang("en"),
     :H1[:P["Block and List tests"]],
     :L[:LI[:P["List One"]],
        :LI[:P["List Two"]]],
     :BlockQuote[:P["blockquote\nfun\n"]],
     :P[:Code["code\n\n block\n"]],
     :L[:LI[:P["Block List One"]]],
     :L[:LI[:P["Block List Two"]]],
     :L[:LI[:Lbl["1."], :P["ol One"]],
        :LI[:Lbl["2."], :P["ol Two"]]],
     :L[:LI[:P["Other List One"]],
        :LI[:P["Other List Two"]]],
 ];

    $renderer.render: $doc-ast;
}

subtest 'fenced code tests', {
    my Pair:D $doc-ast = parse-markdown q:to/TEXT/;
    Fenced Code tests
    ----------
    ```
    # unknown
    code
    ```

    ```raku
    # raku code
    ```

    TEXT

    is-deeply $doc-ast , 'Document' => [
        :Lang("en"),
        :H2[:P["Fenced Code tests"]],
        :P[:Code["# unknown\ncode\n"]],
        :P[:Code[:role("raku"), "# raku code\n"]]
    ];
}

subtest 'various inline elements', {
    my Pair:D $doc-ast = parse-markdown q:to/TEXT/;
    This is a *paragraph* with **many** `different` ``inline` elements``.
    [Links](http://google.com), for [example][], as well as ![Images](/bad/path.jpg)
    (including ![Reference][] style) <http://google.com>

    [example]: http://example.com
    [Reference]: /another/bad/image.jpg
    TEXT

    $renderer.render: $doc-ast;

    is-deeply $doc-ast , 'Document' => [
            :Lang("en"),
            :P["This is a ", :Em["paragraph"], " with ", :Strong["many"], " ", :Code["different"], " ", :Code["inline` elements"], ". ",
               :Link[:href("http://google.com"), "Links"], ", for ", :Link[:href("http://example.com"), "example"], ", as well as ",
               :Figure[:href("/bad/path.jpg"), :Alt("Images")], " (including ", :Figure[:href("/another/bad/image.jpg"), :Alt("Reference")]
               , " style) ", :Link[:href("http://google.com"), "http://google.com"]],
    ];

}
$renderer.pdf.save-as: "tmp/page-tree.pdf";

done-testing;

