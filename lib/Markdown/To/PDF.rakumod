unit class Markdown::To::PDF;

use PDF::Render::Simple;

use Markdown::To::PDF::Grammar;
use Markdown::To::PDF::Actions;
use PDF::Render::Simple::Writer;

sub read-batch($renderer, Text::Markdown $md, PDF::Content::PageTree:D $pages, $frag, |c) is hidden-from-backtrace {
    my Markdown::To::PDF::Actions $actions .= new;
    Markdown::To::PDF::Grammar.parse: $text, :$actions
    my Pair:D $doc-ast = $/.made;
    my Hash:D $info = $writer.write-batch($doc-ast<Document>, $frag);
    my Hash:D $index = $writer.index;
    my @toc = $writer.toc;
    %( :@toc, :$index, :$frag, :$info);
}

# synchronous Markdown processing
sub read($renderer, Text::Markdown $md, |c) {
    my %batch = $renderer.&read-batch($md, $renderer.pdf.Pages, $renderer.root);
    $renderer.merge-batch: %batch;
}

method render(
    Text::Markdown $md,
    :$renderer is copy = PDF::Render::Simple,
    Numeric:D :$width  = 612,
    Numeric:D :$height = 792,
    Numeric:D :$margin = 20,
    Numeric   :$margin-left,
    Numeric   :$margin-right,
    Numeric   :$margin-top,
    Numeric   :$margin-bottom,
    Bool :$index    = True,
    Bool :$contents = True,
    Bool :$page-numbers,
    Bool :$async,
    Str  :$page-style,
    IO() :$stylesheet,
    |c,
) is export(:pod-render) {
    $renderer .= new: |c,  :$width, :$height, :$margin, :$margin-top, :$margin-bottom, :$margin-left, :$margin-right, :$contents, :$page-numbers, :$page-style, :$stylesheet;

    $renderer.pdf.media-box = 0, 0, $width, $height;
    $renderer.&read($md, |c);
    $renderer.finish(:$index);
    $renderer.pdf;
}
