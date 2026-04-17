unit class Markdown::To::PDF::TagsTree;

use Text::Markdown;

has Pair:D @!tags;
has Str:D $.lang = 'en';
has $!level = 1;
has Bool $!inlining = False;
has %.role-map;
has Bool $.indent;
has @!item-nums;

enum Tags ( :Artifact<Artifact>, :BlockQuote<BlockQuote>, :Caption<Caption>, :CODE<Code>, :Division<Div>, :Document<Document>, :Header<H>, :Label<Lbl>, :LIST<L>, :ListBody<LBody>, :ListItem<LI>, :FootNote<FENote>, :Reference<Reference>, :Paragraph<P>, :Quote<Quote>, :Span<Span>, :Section<Sect>, :Table<Table>, :TableBody<TBody>, :TableHead<THead>, :TableHeader<TH>, :TableData<TD>, :TableRow<TR>, :Link<Link>, :Emphasis<Em>, :Strong<Strong>, :Title<Title> );

proto method render($, *% --> Pair) {*}

multi method render(::?CLASS:U: |c) {
    self.new.render(|c);
}

method !block(Str:D $tag, $md, |c) {
    self!tag: $tag, |c, {
        $.read($_) for $md.items;
    }
}

multi method render(::?CLASS:D: Text::Markdown::Document $md) {
    self!block: Document, Lang => $!lang, $md;
}

multi method read(Text::Markdown::Heading $md) {
    my UInt:D $level = $md.level.&min(6).&max(1);
    self!tag: 'H' ~ $level, {
        self!add-content: $md.text;
    }
}

multi method read(Text::Markdown::Rule $md) {
    %!role-map<HR> //= :Artifact[ :Placement<Block> ];
    self!tag: 'HR';
}

multi method read(Text::Markdown::Paragraph $md) {
    self!block: Paragraph, $md;
}

multi method read(Str:D $text) {
        $!inlining = True;
        self!add-content: $text;
}

method !indent($n = 0) {
    if $.indent {
        my $depth = $n + @!tags;
        self!add-content: "\n" ~ '  ' x $depth
            if @!tags;
    }
}

method !open-tag($tag) {
    self!indent unless $!inlining;
    my $tag-ast = $tag.fmt => [];
    @!tags.tail.value.push: $tag-ast if @!tags;
    @!tags.push: $tag-ast;
    $tag-ast;
}

method !close-tag(Str:D $tag where @!tags.tail.key ~~ $tag) {
    self!indent(-1) unless $!inlining;
    @!tags.pop;
}

method !tag(Str:D $tag, &code = sub {}, :$inline, *%atts) {
    temp $!inlining = .so with $inline;
    my Pair $tag-ast := self!open-tag: $tag;
    $tag-ast.value.append: %atts.sort;
    &code();
    self!close-tag: $tag;
    $tag-ast;
}

method !add-content($c) {
    die "no active tags" unless @!tags;
    @!tags.tail.value.push: $c;
}
