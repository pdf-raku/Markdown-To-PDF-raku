unit class Markdown::To::PDF;

use PDF::Tags::Render;
also is PDF::Tags::Render;

use Text::Markdown;
use Markdown::To::PDF::TagsTree;
use PDF::Tags::Render::Writer;

sub read-batch($renderer, Text::Markdown $md, PDF::Content::PageTree:D $pages, $frag, |c) is hidden-from-backtrace {
    my Markdown::To::PDF::TagsTree $md-reader .= new;
    my PDF::Tags::Render::Writer $writer = $renderer.writer: :$pages, :$frag;
    my Pair:D $pdf-ast = $md-reader.render($md);
    my Hash:D $info = $writer.write-batch($pdf-ast<Document>, $frag);
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
    :$renderer is copy = PDF::Tags::Render,
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
