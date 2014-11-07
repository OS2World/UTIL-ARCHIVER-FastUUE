# postpkt(c) Alexander Reznikov, 2:4600/220@fidonet, homebrewer@yandex.ru
# Если Вы обнаружите в скрипте какие-нибудь ошибки или неточности - сообщите
# мне нетмэйлом или email'ом.
# Немного документации есть в файлике 'postpkt.txt'
#
package postpkt;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(PostPKT);
@EXPORT_OK = qw($postpktver @MonthList rndfile basedir ftnparse fidorize generatemsgid generatemsgidtime);

$postpktver = '1.1.3';
@MonthList = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
sub rndfile { sprintf('%04x%04x', int(rand(0xFFFF)), int(rand(0xFFFF))) }
sub basedir { my $tmp = shift; $tmp =~ /^(.*?)[\/\\]?$/; return $1; }

sub ftnparse { $_ = shift;
               if (!/^\s*(\d+)\s*\:\s*(\d+)\s*\/\s*(\d+)(?:\s*\.(\d+))?(?:\s*\@(\S+))?\s*$/)
               { print "Warning: \"$_\" не похоже на FTN адрес!\n"; }
               my(%ret);
                  $ret{Zone}   = $1 || 0;
                  $ret{Net}    = $2 || 0;
                  $ret{Node}   = $3 || 0;
                  $ret{Point}  = $4 || 0;
                  $ret{Domain} = $5 || '[empty]';
               return %ret; }
sub fidorize { $_ = shift; tr/Н/H/; s/(?:\x0D\x0A)|(?:\x0A)/\x0D/go; $_ }

sub binwrite
{
 my $file = shift;
 my $template = shift;
 my $pack = pack($template, @_);
 syswrite($file, $pack, length($pack));
}

sub generatemsgid { return sprintf('%08x', shift) };
sub generatemsgidtime {
 my $Base = shift;
 dbmopen(%MSGID, "$Base", 0666);
 $address = shift;
 my $msgid = $MSGID{$address} || -1;
 $msgid++;
 my $msgidtime = time;
 if ($msgid < $msgidtime)
 {
  $msgid = $msgidtime;
 };
 $MSGID{$address} = "$msgid";
 dbmclose(%MSGID);
 return $msgid;
}

sub PostPKT {
 my %param = @_;

 my $orgpkt   = $param{OrgPKT}   || die 'Не указан адрес отправителя pkt!\n';
 my $dstpkt   = $param{DstPKT}   || die 'Не указан адрес получателя pkt!\n';
 my $orgadr   = $param{OrgAdr}   || $orgpkt;
 my $dstadr   = $param{DstAdr}   || $dstpkt;
 my $area     = $param{Area}     || '';
 my $from     = $param{From}     || '';
 my $to       = $param{To}       || ($area eq ''? 'You': 'All');
 my $subj     = $param{Subj}     || '';
 my $origin   = $param{Origin}   || '';
 my $tearline = $param{TearLine} || "postpkt.pl $postpktver";
 my $tagline  = $param{TagLine}  || '';
 my $text     = $param{Text}     || '';
 my $path     = $param{Path}     || './';
 my $pid      = $param{Pid}      || "postpkt.pl $postpktver";
 my $pass     = $param{Pass}     || '';
 my $maxsize  = (exists $param{MaxSize}? $param{MaxSize}: 10240);
 if ($param{TShift} =~ /^\s*(?:yes|true|1)\s*$/i) { $tshift = 1; } else { $tshift = 0; };
 my $Base     = $param{Base}     || '';
 $Base .= 'msgid' if (($Base eq '')||($Base =~ /^.*[\/\\]$/));

 $from     = fidorize($from);
 $to       = fidorize($to);
 $subj     = fidorize($subj);
 $origin   = fidorize($origin);
 $tearline = fidorize($tearline);
 $tagline  = fidorize($tagline);
 $pid      = fidorize($pid);
 @text1    = split("\x0D",fidorize($text));
 foreach (@text1) { $_ = "$_\r"; };


 my $from1 = substr($from, 0, 36 );
 my $to1   = substr($to  , 0, 36 );
 (my $origin1) = split("[\@]",$orgadr);

 do
 {
  $pktname = basedir($path).'/'.rndfile().'.pkt';
 } until !(-e "$pktname");

 my %OrgPKTH = ftnparse($orgpkt);
 my %DstPKTH = ftnparse($dstpkt);
 my %OrgAdrH = ftnparse($orgadr);
 my %DstAdrH = ftnparse($dstadr);

 (my $Sec, my $Min, my $Hour, my $Day, my $Month, my $Year,,) = localtime(time);

 open(PKT, ">$pktname");
 binmode(PKT);

 binwrite(PKT, 'v2v6vvv2CCa8v2vvCCvv2v2a4',
 $OrgPKTH{Node}, $DstPKTH{Node}, $Year+1900, $Month, $Day, $Hour, $Min, $Sec, 0, 2,
 $OrgPKTH{Net}, $DstPKTH{Net}, 0xFE, 0x01, $pass, $OrgPKTH{Zone}, $DstPKTH{Zone}, 0, 0x0100, 0x00,
 0x00, 1, $OrgPKTH{Zone}, $DstPKTH{Zone}, $OrgPKTH{Point}, $DstPKTH{Point}, 'PERL');

 $size = 0;
 $parts = 1;

 my $i = 0;
 while ($i<=$#text1)
 {
  $size += length($text1[$i]);
  if (($maxsize>0)&&($size>$maxsize)&&($i<$#text1))
  {
   $size = 0; $parts++;
  }
  $i++;
 }

 $i = 0; my $cpart = 0;
 while ($i<=$#text1)
 {
  $csize = 0; $cpart++;
  my $msgtime = generatemsgidtime($Base, $origin1);
  my $msgid = generatemsgid($msgtime);
  ($Sec, $Min, $Hour, $Day, $Month, $Year,,) = localtime($msgtime) if $tshift;

  my $hdata = '';
  if ($area eq '')
  {
   $hdata .= "\x01INTL $DstAdrH{Zone}:$DstAdrH{Net}/$DstAdrH{Node} $OrgAdrH{Zone}:$OrgAdrH{Net}/$OrgAdrH{Node}\r";
   $hdata .= "\x01TOPT $DstAdrH{Point}\r" if $DstAdrH{Point} != 0;
   $hdata .= "\x01FMPT $OrgAdrH{Point}\r" if $OrgAdrH{Point} != 0;
  } else
  {
   $hdata .= "AREA:$area\r";
  }
  $hdata .= "\x01MSGID: $orgadr $msgid\r".($pid eq ''? '': "\x01PID: $pid\r");
  my $ldata = '' .($tagline eq ''? '': "... $tagline\r").($tearline eq ''? '': "--- $tearline\r")." * Origin: $origin ($origin1)\r";

  binwrite(PKT, 'vv2v2vva20a*xa*xa*xa*',
  2,$OrgAdrH{Node}, $DstAdrH{Node}, $OrgAdrH{Net}, $DstAdrH{Net},
  256, 0,
  sprintf('%02d %s %02d  %02d:%02d:%02d', $Day, "$MonthList[$Month]", $Year % 100, $Hour, $Min, $Sec),
  $to1, $from1, substr(($parts > 1? "[$cpart/$parts] ": '').$subj, 0, 71 ), $hdata);

  binwrite(PKT, 'a*', "Subject: $subj\r") if length($subj)>=71;
  do
  {
   binwrite(PKT, 'a*', $text1[$i]);
   $csize += length($text1[$i]);
   $i++;
  } until (($csize>$maxsize)&&($maxsize>0))||($i > $#text1);
  binwrite(PKT, 'CCa*x', 13, 13, $ldata);
 }
 binwrite(PKT, 'xx');

close(PKT);
return $pktname;
}

1;
