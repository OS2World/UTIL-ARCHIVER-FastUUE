# ������砥� ���⨫�� ����⮢
use postpkt;

# ����� ��ࠬ����
# ���� � ��� � 䠩�� � ���⮬ fastuue (�� ���-䠩�!!!)
$statfile = "stat.txt";
#
$pktfrom = $pktto = '99:2003/110@webnet'; # ����, � ���ண� � �� ����� 
                                          # ���� �ନ஢����� ������
$msgfrom = $msgto = $pktto;               # ����, � ���ண� � �� �����
                                          # ���� ���ᮢ��� ᮮ�饭�� � �����
$fromname = 'FastUUE';                    # �� �쥣� ����� ������� ���⨭�
$toname = 'All';                          # �� ����� ��� ������� ���⨭�
$area = 'HOMEBREW.INFO';                  # �宮������ ��� ���⨭��, 
                                          # �᫨ '', � NETMAIL
$pass = 'FUUE';                           # ��஫� �� ������
$subj = 'New files';                      # Subject ���쬠
$origin = 'HomeBrew System';              # �ਤ���
$tearline =   
 'fastuue & perlann.pl & postpkt.pm';     # ��ૠ��

$tagline = '�����, ������� �����!';    # �������

$path = 'C:/FTNMAIL/UTIL/FUUEBETA/OUT/'   # ����, ��� �ନ������ pkt
$base = '';                               # ���� � ��� 䠩�� ��� msgid'��
                                          # �᫨ �����稢����� �� '\' ��� 
                                          # '/' ��� ���������, � �㤥� 
                                          # ��⮬���᪨ ���������: 'msgid'

$tshift = 'yes';                          # ���� �ᥣ� ��⠢��� � 'yes'.
                                          # �������� ���ࠬ � ਤ�ࠬ
                                          # �ࠢ��쭮 ���஢��� ���ᠣ�
                                          # � ���浪� �� ������
$maxsize = 10240;                         # ���ᨬ���� ࠧ��� ���ᠣ�
                                          # �᫨ 0 <- �� ����������
                                          # �᫨ �� ��।�����, � 10240


# ���뢠�� ���� ����� �� �⥭��
open(FUUE, "<$statfile") || die "�� ���� ������ $statfile!!!\n";

# ��⠥� ����
while(<FUUE>)
{
 chomp;

 SW:
 {
  if(/^Filename (.*)$/io) { $tmp{Filename}=$1; last SW; }
  if(/^Size (.*)$/io)     { $tmp{Size}=$1;     last SW; }
  if(/^Echo (.*)$/io)     { $tmp{Echo}=$1;     last SW; }
  if(/^FromAddr (.*)$/io) { $tmp{FromAddr}=$1; last SW; }
  if(/^FromName (.*)$/io) { $tmp{FromName}=$1; last SW; }
  if(/^ToAddr (.*)$/io)   { $tmp{ToAddr}=$1;   last SW; }
  if(/^ToName (.*)$/io)   { $tmp{ToName}=$1;   last SW; }
  if(/^Subject (.*)$/io)  { $tmp{Subject}=$1;  last SW; }
  if(/^Title (.*)$/io)    { $tmp{Title}=$1;    last SW; }
  if(/^Sections (.*)$/io) { $tmp{Sections}=$1; last SW; }
  if(/^Hatch (.*)$/io)    { $tmp{Hatch}=$1;    last SW; }
  if(/^Save (.*)$/io)     { $tmp{Save}=$1;     last SW; }
  if(/^\[NewFile\]$/io)   { undef %tmp;   last SW; }
  if(/^\[EndFile\]$/io)
  {
   push @data, {%tmp};
   undef %tmp;
   last SW; 
  }
 } 
}

# ����뢠�� 䠩�
close(FUUE);

#
@MonthList = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
@WDayList = ('�������쭨�', '��୨�', '�।�', '��⢥�', '��⭨�', '�㡡��', '����ᥭ��');
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$fyear = $year+1900;

# �㭪�� ���஢�� (᭠砫� �� Echo, ��⮬ �� Filename)
sub sortfunc
{
 my $a = shift;
 my $b = shift;

 my $ret = uc($a->{Echo}) ne uc($b->{Echo});
 return $ret if $ret != 0;

 return uc($a->{Filename}) cmp uc($b->{Filename});
}

# �㭪�� ��� ������ᨨ ࠧ��� 䠩�
sub ConvSize
{
 my $size = shift;
 my $lim  = shift;
 my $ret;

 $ret = $size.'b';
 $ret = $size%1024 .'K' if length($ret)>$lim;
 $ret = $size%1048576 .'M' if length($ret)>$lim;
 $ret = $size%1073741824 .'G' if length($ret)>$lim;
 return $ret;
}

sub getn 
{ 
 my $src = shift; 
 my $lim = shift;
 if (length($src)>$lim)
 {
  $src = substr($src, 0, $lim-1) . "";
 }
 return $src;
}

$text = '';

# �����
$text .= "������� $WDayList[$wday], $mday $MonthList[$mon] $fyear.\n";

# � ⥯��� �뢮��� ������ � ���஢���
$totalsize = 0;
$totalfiles = 0;
$post = 0;
foreach $tmp (sort {sortfunc($a, $b)} @data)
{
 $post = 1;
 $totalfiles++;
 $totalsize+=$tmp->{Size};
 $AName = getn($tmp->{Filename}, 30);
 $ASize = ConvSize($tmp->{Size}, 8);
 $hs = 'hatched as: '.$tmp->{Hatch} if $tmp->{Hatch} ne '';
 $hs .= ', ' if ($hs ne '')&&($tmp->{Save} ne '');
 $hs .= 'saved as: '.$tmp->{Save} if $tmp->{Save} ne ''; 

 $text .= ' '.('-' x 77)."\n";
 $text .= sprintf(" %s: %s, \"%s\"\n", $AName, $ASize, getn(($tmp->{Title} ne '')? $tmp->{Title}: $tmp->{Subject}, 78-7-length($AName)-length($ASize)));
 $text .= (' ' x 23).getn('['.$tmp->{Echo}.']'.(($tmp->{Sections} ne '')? '; '.$tmp->{Sections}.' section(s)': ''), 55)."\n";
 $text .= (' ' x 23).getn($tmp->{FromName}.' ['.$tmp->{FromAddr}.'] -> '.$tmp->{ToName}, 55)."\n";
 $text .= (' ' x 23).getn($hs, 55)."\n";
 $text .= "\n";
 undef $hs;
}

# ����
$text .= ' '.('=' x 77)."\n";
$text .= ' '.ConvSize($totalsize, 11)." � $totalfiles 䠩���\n";
$text .= ' '.('=' x 77)."\n";
$text .= "\n\n"; 

# ���⨭�
if ($post)
{
 PostPKT(OrgPKT=>$pktfrom,
         DstPKT=>$pktto,
         OrgAdr=>$msgfrom,
         DstAdr=>$msgto,
         From=>$fromname,
         To=>$toname,
         Area=>$area,
         Pass=>$pass,
         Subj=>$subj,
         Origin=>$origin,
         TearLine=>$tearline,
         TagLine=>$tagline,
         Text=>$text,
         Path=>$path,
         MaxSize=>$maxsize,
         TShift=>$tshift,
         Base=>$base
       );
}
 