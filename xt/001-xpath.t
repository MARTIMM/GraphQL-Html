use v6.c;

use Test;
use XML::XPath;

my $x   = XML::XPath.new(xml => '<body><p>abc</p><h3>test</h3><p><a>yada yada</a></p></body>');
my $lnk = $x.find('//a', :to-list);
is $lnk.elems, 1, 'found one element';
note $lnk;
my @t   = $x.find('//text()', :start($lnk[0]), :to-list);

is @t.elems, 1, 'found one element';
is @t[0].text, 'yada yada', 'found yada yada';

done-testing;
