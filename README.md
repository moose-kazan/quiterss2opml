## QuiteRSS to OPML ##

Simple tool for export feed list from quiterss to opml format.

It reads feeds.db file and print feed list in OPML format to stdout.

Tool written on perl and required some dependencies, which can be
installed by command:

`sudo apt install libxml-writer-perl libdbi-perl libdbd-sqlite3-perl`

## Usage ##

`./QuiteRSS2OPML.pl > myfeeds.opml`

or

`./QuiteRSS2OPML.pl path/to/feeds.db > myfeeds.opml`
