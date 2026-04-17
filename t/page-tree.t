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
my $doc-ast = Markdown::To::PDF::TagsTree.render:  $document;

is-deeply $doc-ast, 'Document' =>
                               [
                                   :Lang<en>,
                                   :H2["Markdown Test"],
                                   :P["This is a simple markdown document."],
                                   :HR[],
                                   :P["It has two paragraphs."],
                               ];

my %role-map = (
    :HR => :Artifact[ :Placement<Block> ],
);

lives-ok {
    my PDF::Tags::Render $renderer .= new: :%role-map;
    my PDF::API6:D $pdf = $renderer.render: $doc-ast;
    mkdir "tmp";
    $pdf.save-as: "tmp/page-tree.pdf";
}

pass;

done-testing;

