unit class Markdown::To::PDF;

use PDF::Render::Simple :PdfAst;
use PDF::Render::Simple::Writer;

use Markdown::To::PDF::Grammar;
use Markdown::To::PDF::Actions;

our sub parse-markdown($md) is export(:parse-markdown) {
    my Markdown::To::PDF::Actions $actions .= new;
    Markdown::To::PDF::Grammar.parse: $md, :$actions;
    $/.made;
}

multi method render(Str:D $md, *%o --> PDF::API6:D) is hidden-from-backtrace {
    my PdfAst $made = $md.&parse-markdown;
    self.render: $made, |%o
}

multi method render(
    PdfAst $made,
    :$renderer = PDF::Render::Simple,
    *%o --> PDF::API6:D
) is export(:pod-render) {
    $renderer.render($made, |%o);
}
