use v6;
use Text::Markdown::Document;
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

my Text::Markdown::Document:D $document .= new($text);
my Markdown::To::PDF::TagsTree $reader .= new;
my $doc-ast = $reader.render: $document;
my %role-map := $reader.role-map;

is-deeply %role-map, %( HR => :Artifact[ :Placement<Block> ] );

is-deeply $doc-ast, 'Document' => [
       :Lang<en>,
       :H2["Markdown Test"],
       :P["This is a simple markdown document."],
       :HR[],
       :P["It has two paragraphs."],
   ];

my PDF::Tags::Render $renderer .= new: :%role-map;
lives-ok {
    $renderer.render: $doc-ast;
}

## next text with lists

$reader .= new;
$document .= new: q:to/TEXT/;
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

$doc-ast = $reader.render: $document;
 is-deeply $doc-ast , 'Document' => [
        :Lang("en"),
        :L[:LI[:P["List One"]],
            :LI[:P["List Two"]]],
        :BlockQuote[:P["blockquote fun"]],
        :Code["code\nblock"],
        :L[:LI[:P["Block List One"]],
            :LI[:P["Block List Two"]]],
        :L[:LI[:P["ol One"]],
            :LI[:L[:LI[:P["ol Two"]]]]],
        :L[:LI[:P["Other List One"]],
            :LI[:P["Other List Two"]]],
 ];

$renderer.render: $doc-ast;

$renderer.pdf.save-as: "tmp/page-tree.pdf";
done-testing;

