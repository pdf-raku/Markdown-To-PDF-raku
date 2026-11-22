use Markdown::To::PDF :&parse-markdown;
use PDF::Render::Simple :PdfAst;
use PDF::API6;

sub MAIN(
    *@files ($, *@),
    Str :$save-as is copy,
    Numeric :$width,
    Numeric :$height,
    Numeric :$margin,
    Bool :$index = True,
    Bool :$,
    Bool :$quiet,
) {
    my %o = (:$width, :$height, :$margin).grep: *.value.defined;
    $save-as //= @files.pop
        if @files.tail ~~ m:i/'.pdf'$/;
    my PDF::Render::Simple $renderer .= new: :!finish;
    with @files -> $md {
        my PdfAst:D $doc-ast = $md.IO.slurp.&parse-markdown;
        $renderer.render: $doc-ast;
    }
    $renderer.finish(:$index);
    my PDF::API6:D $pdf = $renderer.pdf;
    $pdf.save-as: $save-as;
    say $save-as unless $quiet;
}
