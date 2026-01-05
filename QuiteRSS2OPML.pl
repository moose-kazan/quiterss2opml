#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

use DBI;
use XML::Writer;

use Data::Dumper;

my $feedsDbFile = "$ENV{'HOME'}/.local/share/QuiteRss/QuiteRss/feeds.db";
$feedsDbFile = shift @ARGV if @ARGV;

warn "Parsing feeds database from file $feedsDbFile\n";


sub loadTree {
    my $dsn = "dbi:SQLite:dbname=$feedsDbFile";
    my $dbh = DBI->connect($dsn, "", "",  { RaiseError => 1, AutoCommit => 1 });

    my $sqlQuery = "select * from feeds";
    my $sth = $dbh->prepare($sqlQuery);
    $sth->execute();

    my $srcFeeds = [];

    while (my $row = $sth->fetchrow_hashref()) {
        push @$srcFeeds, {
            title => $row->{title},
            description => $row->{description},
            text => $row->{text},
            id => $row->{id},
            parentId => $row->{parentId},
            xmlUrl => $row->{xmlUrl},
            htmlUrl => $row->{htmlUrl},
            childs => [],
        };
    }

    #print Dumper($srcFeeds);exit;

    my %nodes;

    foreach my $item (@$srcFeeds) {
        $nodes{$item->{id}} = $item;
    }

    #print Dumper(\%nodes);exit;

    foreach my $item (@$srcFeeds) {
        next if $item->{parentId} == 0;
        next unless exists $nodes{$item->{parentId}};
        push(@{$nodes{$item->{parentId}}->{childs}}, $item);
    }

    #print Dumper(\%nodes);

    my @rootNodes = grep { $_->{parentId} == 0 } @$srcFeeds;
    return shift @rootNodes;
}

sub printTree($$);
sub printTree($$) {
    my $xmlWriter = shift;
    my $node = shift;

    if ($node->{childs} && @{$node->{childs}}) {
        $xmlWriter->startTag('outline',
            id => $node->{id},
            title => $node->{title},
            text => $node->{text},
            isOpen => 'false',
        );

        foreach my $child (@{$node->{childs}}) {
            printTree($xmlWriter, $child);
        }

        $xmlWriter->endTag('outline');
    }
    else {
        $xmlWriter->emptyTag('outline',
            id => $node->{id},
            title => $node->{title},
            text => $node->{text},
            xmlUrl => $node->{xmlUrl},
            htmlUrl => $node->{htmlUrl},
            type => 'rss',
            activites => '',
            archiveMode => 'globalDefault',
            comment => '',
            copyright => '',
            useCustomFetchInterval => 'false',
            version => 'RSS',
            maxArticleAge => '0',
            maxArticleNumber => '0',
            fetchInterval => '0',
        );
    }
}

eval {
    my $feedsTree = loadTree();

    #print Dumper($feedsTree);

    my $xmlWriter = XML::Writer->new(
        DATA_MODE   => 1,
        DATA_INDENT => 2,
    );
    $xmlWriter->xmlDecl('UTF-8');
    $xmlWriter->startTag('opml', 'version' => '1.0');
    $xmlWriter->startTag('head');
    $xmlWriter->dataElement('title', 'QuiteRSS feeds');
    $xmlWriter->endTag('head');
    $xmlWriter->startTag('body');

    printTree($xmlWriter, $feedsTree);

    $xmlWriter->endTag('body');
    $xmlWriter->endTag('opml');
    $xmlWriter->end();
};
if (my $err = $@) {
    warn "Can't process file: $err\n";
}