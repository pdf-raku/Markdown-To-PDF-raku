use v6;
use Text::Markdown;
use Markdown::To::PDF::TagsTree;
use PDF::Tags::Render;
use PDF::API6;
use Test;

my $text = q:to/TEXT/;
## Markdown Test ##

This is a simple markdown document.

---

It has two
paragraphs.
TEXT

my Text::Markdown:D $md = $text.&parse-markdown;

my Markdown::To::PDF::TagsTree $reader .= new;
my $doc-ast = $reader.render: $md;

is-deeply $doc-ast, 'Document' => [
       :Lang<en>,
       :H2["Markdown Test"],
       :P["This is a simple markdown document."],
       :Artifact[:Placement<Block>, :role<HR>],
       :P["It has two paragraphs."],
   ];

my PDF::Tags::Render $renderer .= new;
lives-ok {
    $renderer.render: $doc-ast;
}

## next text with lists

$reader .= new;
$md = parse-markdown q:to/TEXT/;
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

$doc-ast = $reader.render: $md;
is-deeply $doc-ast , 'Document' => [
        :Lang("en"),
        :L[:LI[:P["List One"]],
           :LI[:P["List Two"]]],
        :BlockQuote[:P["blockquote fun"]],
        :P[:Code["code\nblock"]],
        :L[:LI[:P["Block List One"]],
           :LI[:P["Block List Two"]]],
        :L[:LI[:P["ol One"]],
           :LI[:L[:LI[:P["ol Two"]]]]],
        :L[:LI[:P["Other List One"]],
           :LI[:P["Other List Two"]]],
 ];
$renderer.render: $doc-ast;

$md = parse-markdown q:to/TEXT/;
```
# unknown
code
```

```raku
# raku code
```

TEXT

$doc-ast = $reader.render: $md;
is-deeply $doc-ast , 'Document' => [
        :Lang("en"),
        :P[:Code["# unknown\ncode"]],
        :P[:Code[:role("raku"), "# raku code"]]
];
$renderer.render: $doc-ast;
                                                   
$md = parse-markdown q:to/TEXT/;
This is a *paragraph* with **many** `different` ``inline` elements``.
[Links](http://google.com), for [example][], as well as ![Images](/bad/path.jpg)
(including ![Reference][] style) <http://google.com>

[example]: http://example.com
[Reference]: /another/bad/image.jpg
TEXT

$doc-ast = $reader.render: $md;
$renderer.render: $doc-ast;

is-deeply $doc-ast , 'Document' => [
        :Lang("en"),
        :P["This is a ", :Em["paragraph"], " with ", :Strong["many"], " ", :Code["different"], " ", :Code["inline` elements"], ". ",
           :Link[:href("http://google.com"), "Links"], ", for ", :Link[:href("#example"), "example"], ", as well as ",
           :Figure[:Alt("Images"), :href("/bad/path.jpg"), "Images"], " (including ", :Figure[:Alt("Reference"), :href("#Reference"), "Reference"]
           , " style) ", :Link[:href("http://google.com"), "http://google.com"]],
];

$renderer.pdf.save-as: "tmp/page-tree.pdf";

done-testing;

