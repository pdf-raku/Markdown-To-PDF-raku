unit class Markdown::To::PDF::TagsTree;

use Text::Markdown;

has Pair:D @!tags;
has Str:D $.lang = 'en';
has $!level = 1;
has Bool $!inlining = False;
has %.role-map;
has Bool $.indent;
has @!item-nums;
has Text::Markdown::Document $!document;

enum Tags ( :Artifact<Artifact>, :BlockQuote<BlockQuote>, :Caption<Caption>, :CODE<Code>, :Division<Div>, :Document<Document>, :Header<H>, :Label<Lbl>, :LIST<L>, :ListBody<LBody>, :ListItem<LI>, :FootNote<FENote>, :Reference<Reference>, :Paragraph<P>, :Quote<Quote>, :Span<Span>, :Section<Sect>, :Table<Table>, :TableBody<TBody>, :TableHead<THead>, :TableHeader<TH>, :TableData<TD>, :TableRow<TR>, :Link<Link>, :Emphasis<Em>, :Strong<Strong>, :Title<Title>, :Figure<Figure> );

proto method render($, *% --> Pair) {*}

multi method render(::?CLASS:U: |c) {
    self.new.render(|c);
}

method !block(Str:D $tag, $md, |c) {
    self!tag: $tag, |c, {
        $.render($_) for $md.items;
    }
}

multi method render(::?CLASS:D: Text::Markdown $md) {
    temp $!document = $md.document;
    self!block: Document, Lang => $!lang, $!document;
}

multi method render(::?CLASS:D: Text::Markdown::Document $md) {
    self.render($_) for $md.items;
}

multi method render(Text::Markdown::Heading $md) {
    my %atts;
    my UInt:D $level = $md.level;
    # map H7, H8, ... -> P
    %atts<role> = 'P' if $level > 6;
    self!tag: 'H' ~ $level, |%atts, {
        self!add-content: $md.text;
    }
}

multi method render(Text::Markdown::Rule $md) {
    %!role-map<HR> //= :Artifact[ :Placement<Block> ];
    self!tag: 'HR';
}

multi method render(Text::Markdown::Paragraph $md) {
    self!block: Paragraph, $md;
}

multi method render(Text::Markdown::Blockquote $md) {
    self!block: BlockQuote, $md;
}

multi method render(Text::Markdown::Code $md) {
    self!tag: CODE, {
        self.render: $md.text
    }
}

multi method render(Text::Markdown::CodeBlock $md) {
    self!tag: Paragraph, {
        my %atts;
        if $md.lang -> $lang {
            %atts<role> = $lang.lc;
        }
        self!tag: CODE, |%atts, {
            self.render: $md.text
        }
   }
}

multi method render(Text::Markdown::List $md) {
    self!tag: LIST, {
        for $md.items -> $item {
            self!tag: ListItem, {
                self.render: $item
            }
        }
    }
}

multi method render(Text::Markdown::Emphasis $md) {
    my $tag = $md.level <= 1 ?? Emphasis !! Strong;
    self!tag: $tag, {
        self.render: $md.text;
    }
}

multi method render(Text::Markdown::Link $md) {
    my %atts;
    if $md.url -> $url {
        %atts<href> = $url
    }
    elsif $md.ref -> $ref {
        # todo proper internal links
        %atts<href> = '#' ~ $ref
            if $!document.references{$ref};
    }
    self!tag: Link, |%atts, {
        self.render: $md.text
    }
}

multi method render(Text::Markdown::Image $md) {
    # todo inline images
    my %atts;
    if $md.url -> $url {
        %atts<href> = $url
    }
    elsif $md.ref -> $ref {
        # todo proper internal links
        %atts<href> = '#' ~ $ref
            if $!document.references{$ref};
    }
    if $md.text -> $alt {
        %atts<Alt> = $alt;
    }
    self!tag: Figure, |%atts, {
        self.render: $md.text
    }
}

multi method render(Str:D $text) {
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
    @!tags.tail;
}
