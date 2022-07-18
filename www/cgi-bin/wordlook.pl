#!/usr/bin/perl -- # -*- perl -*-

require "cgi-lib.pl";

&ReadParse(*values);

# If anything goes wrong, print this
sub errormsg {
    my ($errortxt) = @_;
    print "Content-type: text/html\n\n";
    print "<HTML>\n<HEAD>\n";
    print "<TITLE>Character Look-up Error</TITLE>\n";
    print "</HEAD>\n<BODY>\n";
    print $errortxt, "<P>";
    print " Please try again. \n</BODY>\n</HTML>";
    exit;
}

sub addTones {
    my($withnumbers) = shift;
    my($i);
    $withnumbers =~ s/ng(\d)\b/${1}ng/g;
    $withnumbers =~ s/n(\d)\b/${1}n/g;
    $withnumbers =~ s/ao(\d)\b/a${1}o/g;
    $withnumbers =~ s/ai(\d)\b/a${1}i/g;
    $withnumbers =~ s/ei(\d)\b/e${1}i/g;
    $withnumbers =~ s/ou(\d)\b/o${1}u/g;

    @tonenums = ("a1", "a2", "a3", "a4", "a5", "e1", "e2", "e3", "e4", "e5",
        "i1", "i2", "i3", "i4", "i5", "o1", "o2", "o3", "o4", "o5",
        "u1", "u2", "u3", "u4", "u5", 
        "u:1", "u:2", "u:3", "u:4", "u:5", "u:",
        "v1", "v2", "v3", "v4", "v5", "v");
    @tonemarks = ('&#x0101;', '&aacute;', '&#x01ce;', '&#x00e0;', 'a', 
        '&#x0113;', '&#x00e9;', '&#x011b;', '&#x00e8;', 'e', 
        '&#x012b;', '&#x00ed;', '&#x01d0;', '&#x00ec;', 'i',
        '&#x014d;', '&#x00f3;', '&#x01d2;', '&#x00f2;', 'o',
        '&#x016b;', '&#x00fa;', '&#x01d4;', '&#x00f9;', 'u',
        '&#x01d6;', '&#x01d8;', '&#x01da;', '&#x01dc;', '&#x00fc;', '&#x00fc;',
        '&#x01d6;', '&#x01d8;', '&#x01da;', '&#x01dc;', '&#x00fc;', '&#x00fc;'); 

    for ($i = 0; $i < scalar(@tonenums); $i++) {
        $withnumbers =~ s/$tonenums[$i]/$tonemarks[$i]/ge;
    } 
    $withnumbers =~ s/5//g;

    return $withnumbers;
}


sub hex2utf8 {
    my($hexchar) = @_;
    #print "$hexchar \n";
    if ($hexchar !~ m/^0x/) {
        $hexchar = "0x" . $hexchar;
    }
    $binchar = oct($hexchar);
    if ($binchar <= 127) {
        $retval = pack("C", $binchar);
    } elsif ($binchar <= 2047) {
        $bin1 = ($binchar >> 6) | 0xC0;
        $bin2 = ($binchar & 0x3F) | 0x80;
        $retval = pack("C2", $bin1, $bin2);
    } else {
        $bin1 = ($binchar >> 12) | 0xE0;
        $bin2 = (($binchar & 0x0FFF) >> 6) | 0x80;
        $bin3 = ($binchar & 0x003F) | 0x80;
        $retval = pack("C*", $bin1, $bin2, $bin3);
        #	#print "in 3 char version with $hexchar and $retval bin1 $bin1 bin2 $bin2 bin3 $bin3\n";
    }
    $retval;
}


sub utf82ucs {
    my($utfstring) = @_;
    my($unichar, $unival, $unistring, $i, $int1, $int2, $int3, $byte1, $byte2, $byte3);

    $i = 0;
    while ($i < length($utfstring)) {
        $byte1 = substr($utfstring, $i, 1);
        if (unpack("C", $byte1) <= 0x7F) { # 1 byte long (ASCII)
            $unichar = pack("C", 0x00) . $byte1;
            $i++;
        } elsif ((unpack("C", $byte1) & 0xE0) == 0xC0) { # 2 bytes long
            $byte2 = substr($utfstring, $i+1, 1);
            $int1 = unpack("C", $byte1) & 0x1F;
            $int1 <<= 0x06;
            $int2 = unpack("C", $byte2) & 0x3F;
            $unival = $int1 | $int2;
            $unichar = pack("CC", (0xFF00 & $unival) >> 8, (0x00FF & $unival));
            $i += 2;
        } else {  # 3 bytes long
            $byte2 = substr($utfstring, $i+1, 1);
            $byte3 = substr($utfstring, $i+2, 1);

            $int1 = 0x0F & unpack("C", $byte1);
            $int1 <<= 12;
            $int2 = 0x3F & unpack("C", $byte2);
            $int2 <<= 6;
            $int3 = 0x3F & unpack("C", $byte3);
            $unival = $int1 | $int2 | $int3;
            $unichar = pack("CC", (0xFF00 & $unival) >> 8, (0x00FF & $unival));
            $i += 3;
        }
        $unistring .= $unichar;
    }
    $unistring;
}

sub bytes2hex {
    my($twobytes) = @_;
    my $hex1, $hex2, $allhex;

    $hex1 = unpack "H2", substr($twobytes, 0, 1);
    $hex2 = unpack "H2", substr($twobytes, 1, 1);
    $allhex = "\U$hex1$hex2\E";
}


sub gifify {
    my($utfstring) = shift;
    my($i, $charcount, $byte1, $out);

    $i = 0; $charcount = 0;
    while ($i < length($utfstring)) {
        $byte1 = substr($utfstring, $i, 1);
        if (unpack("C", $byte1) <= 0x7F) { # 1 byte long (ASCII)
            $out .= $byte1;
            $i++;
        } elsif ((unpack("C", $byte1) & 0xE0) == 0xC0) { # 2 bytes long
            $out .= substr($utfstring, $i, 2);
            $i += 2;
        } else {  # 3 bytes long
            $out .= "<IMG SRC=\"/cgi-bin/ugif/" . 
            &bytes2hex(&utf82ucs(substr($utfstring, $i, 3))) . ".gif\">";
            $i += 3;
        }
    }
    return $out;

}

$output = $values{'output'}; #"gif";
$searchtype = $values{'searchtype'};
$where = $values{'where'};
$encoding = "utf-8";
$DICTFILE = "cedict_ts.u8";


# Send the content and character set type to the browser
print "Content-type: text/html; charset=utf-8\n\n";
print <<INTRO;
<HTML>
<HEAD>
<TITLE>Dictionary Search Results</TITLE>
<script>
<!--
function loadPref() 
{
var allcookies = document.cookie;

if (allcookies == "") return false;

var start = allcookies.indexOf("worddict=", 0);
if (start == -1) return false;
start += 9;
var end = allcookies.indexOf(';', start);
if (end == -1) end = allcookies.length;

var cookieval = allcookies.substring(start, end);

var a = cookieval.split('&'); // break into name/value pairs
var prefhash = new Object();
for (var i=0; i < a.length; i++) { 
  a[i] = a[i].split(':');
  prefhash[a[i][0]] = a[i][1];
}

document.lookup.searchtype.selectedIndex = prefhash["searchtype.selectedIndex"];
document.lookup.where.selectedIndex = prefhash["where.selectedIndex"];
if (prefhash["output.checked"] == "true") {
   document.lookup.output.checked = true;
}
else if (prefhash["output.checked"] == "false") {
   document.lookup.output.checked = false;
}

return true;
}


function savePref() 
{
var cookieval = "";

cookieval = "searchtype.selectedIndex:" + document.lookup.searchtype.selectedIndex + '&';
cookieval += "output.checked:" + document.lookup.output.checked + '&';
cookieval += "where.selectedIndex:" + document.lookup.where.selectedIndex;


var cookie = 'worddict=' + cookieval;
var today = new Date();
var expiry = new Date(today.getTime() + 28 * 24 * 60 * 60 * 1000); // plus 28 days
cookie += "; expires=" + expiry.toGMTString();
cookie += "; path=/";
document.cookie = cookie;

}

-->
</script>

</HEAD>
<BODY onLoad="loadPref();" onUnload="savePref();" BGCOLOR=#FFFFFF>
INTRO


$tchinfield = 0; $schinfield = 1; $pyfield = 2; $engfield = 3;
$searchword = $values{'word'};

if ($searchword =~ m/0x[0-9a-f]/i) {
    $searchword =~ s/0x([0-9a-f]{4})/hex2utf8($1)/eig;
}


if ($searchword =~ m/^\s*$/) {
    $emptyquery = 1;
}

if (vec($searchword, 0, 8) > 127 and
    ($searchtype eq "pinyin" or $searchtype eq "english")) {
    $searchtype = "chinese";
}

if (vec($searchword, 0, 8) < 127 and
    ($searchtype eq "chinese" or $searchtype eq "simp" or $searchtype eq "trad")) {
    if ($searchword =~ m/\d\b/) {
        $searchtype = "pinyin";
    } else {
        $searchtype = "english";
    }
}


if ($searchword =~ m/\d\b/ and
    $searchtype ne "pinyin") {
    $searchtype = "pinyin";
}

if ($searchtype eq "simp") {
    $searchfield = $schinfield;
} elsif ($searchtype eq "trad") {
    $searchfield = $tchinfield;
} elsif ($searchtype =~ m/pinyin/i) {
    $searchfield = $pyfield;
    @pystrings = split(/\s/, $searchword);
    $searchword = "";
    foreach $pystring (@pystrings) {
        $pystring .= "[1-5]" unless $pystring =~ m/[1-5]$/;
        $searchword .= $pystring . " ";
    }
    $searchword =~ s/\s$//;
} elsif ($searchtype =~ m/english/i) {
    $searchfield = $engfield;
    $searchword = "\\b$searchword\\b";
    $where = "anywhere";
} 


# Get the search pattern in the proper format
if ($where eq "whole") {
    $pattern = "^$searchword\$";
} elsif ($where eq "start") {
    $pattern = "^$searchword";
} elsif ($where eq "end") {
    $pattern = "$searchword\$";
} elsif ($where eq "anywhere") {
    $pattern = "$searchword";
}

#print "$pattern";

if ($emptyquery == 1) {
    print "Search term cannot be blank.  Please try again.\n";
    foreach $value (keys %ENV) {
        #print "$value &nbsp;&nbsp;&nbsp; $ENV{$value}<BR>";
    }
} else {
    $totalentries = 0;
    open(DICTFILE) || print "Can't open dictionary file $DICTFILE\n";
    print "<TABLE cellpadding=5>\n";
    print "<TR bgcolor=skyblue><TD><b>Trad.</b></TD> <TD><b>Simp.</b></TD> <TD><b>Pinyin</b></TD> <TD><b>English</b></TD></TR>\n";
    while ($dictline = <DICTFILE>) {
        chomp;
        $dictline =~ m/^(\S+)\s(\S+)\s\[([^\]]+)\]\s(.+)$/;
        $dictfields[$tchinfield] = $1;
        $dictfields[$schinfield] = $2;
        $dictfields[$pyfield] = $3;
        $dictfields[$engfield] = $4;
        $nospaces = $dictfields[$pyfield];
        $nospaces =~ s/\s//g;
        $nospaces =~ s/5/0/g;
        if ($searchtype eq "chinese" and
            ($dictfields[$tchinfield] =~ m/$pattern/i ||
                $dictfields[$schinfield] =~ m/$pattern/i)) {
            &printRow;
            $totalentries++;
        }
        elsif ($dictfields[$searchfield] =~ m/$pattern/i) {
            &printRow;
            $totalentries++;
        }

    }
    print "</TABLE>\n";
    close(DICTFILE);


    if ($totalentries == 0) {
        print "<H3>Sorry, no matching entries were found in the dictionary. <P>";
        print "Please make sure you were searching on the correct field (Trad. Chinese, Simp. Chinese, Pinyin, or English).</H3>";
    } else {
        if ($totalentries == 1) {
            print "<P><H3>$totalentries entry found.</H3>\n";
        } else {
            print "<P><H3>$totalentries entries found.</H3>\n";
        }
        print "<P>The simplified version is shown only if different from the traditional.";
    }

}
print <<EOHTML;
<HR>
<P>
<center>
<FORM METHOD=POST ACTION="/cgi-bin/wordlook.pl" name="lookup">
<TABLE>
<TR>
<TD NOWRAP ALIGN=CENTER>
Search <INPUT TYPE="text" maxlength=30 name="word"> as
<SELECT NAME="searchtype">
<OPTION VALUE="chinese">Chinese (Trad. or Simp)
<OPTION VALUE="simp">Simp. Chinese
<OPTION VALUE="trad">Trad. Chinese
<OPTION VALUE="pinyin">Pinyin
<OPTION VALUE="english">English
</SELECT>
</TD>
</TR>
<TR>
<TD align="center">
Match 
<SELECT NAME="where">
<OPTION VALUE="whole">whole dictionary field
<OPTION VALUE="start">at start of dictionary field
<OPTION VALUE="end">at end of dictionary field
<OPTION VALUE="anywhere">anywhere in dictionary field
</SELECT>.<BR>
</TD>
</TR>
<TR>
<TD ALIGN="CENTER">
<INPUT TYPE="submit" VALUE="Look It Up!">
</TD>
</TR>
</TABLE>
</FORM>
<Center>
<P>
Return to the <A HREF="/">main dictionary page</A>.
</BODY>
</HTML>
EOHTML

sub printRow {
    if ($totalentries % 2 == 0) {
        print "<TR bgcolor=lightblue>";
    } else {
        print "<TR bgcolor=skyblue>";
    }
    #print "<TR>\n";

    print "<TD>\n";
    if ($output eq "gif") {
        print &gifify($dictfields[$tchinfield]);
    } else {
        print $dictfields[$tchinfield];
    }
    print "</TD>\n";

    print "<TD>\n";
    if ($dictfields[$tchinfield] ne $dictfields[$schinfield]) { 
        if ($output eq "gif") {
            print &gifify($dictfields[$schinfield]);
        } else {
            print $dictfields[$schinfield];
        }
    }
    print "</TD>\n";

    print "<TD>\n";
    print &addTones($dictfields[$pyfield]);
    print "</TD>\n";

    print "<TD>\n";
    print $dictfields[$engfield];
    print "</TD>\n";
    print "</TR>\n";
}
