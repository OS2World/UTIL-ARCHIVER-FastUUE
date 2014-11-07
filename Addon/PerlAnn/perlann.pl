# Подключаем постилку пакетов
use postpkt;

# Разные параметры
# Путь и имя к файлу с отчетом fastuue (не лог-файл!!!)
$statfile = "stat.txt";
#
$pktfrom = $pktto = '99:2003/110@webnet'; # Адреса, с которого и на который 
                                          # будут формироваться пакеты
$msgfrom = $msgto = $pktto;               # Адреса, с которого и на который
                                          # будут адресованы сообщения в пакете
$fromname = 'FastUUE';                    # От чьего имени ведётся постинг
$toname = 'All';                          # На какое имя ведётся постинг
$area = 'HOMEBREW.INFO';                  # Эхообласть для постинга, 
                                          # если '', то NETMAIL
$pass = 'FUUE';                           # Пароль на пакеты
$subj = 'New files';                      # Subject письма
$origin = 'HomeBrew System';              # Ориджин
$tearline =   
 'fastuue & perlann.pl & postpkt.pm';     # Тирлайн

$tagline = 'Дикари, плакать хочется!';    # Таглайн

$path = 'C:/FTNMAIL/UTIL/FUUEBETA/OUT/'   # Путь, где формируются pkt
$base = '';                               # Путь и имя файла для msgid'ов
                                          # если заканчивается на '\' или 
                                          # '/' или отсутствует, то будет 
                                          # автоматически добавлено: 'msgid'

$tshift = 'yes';                          # Лучше всего оставить в 'yes'.
                                          # Помогает тоссерам и ридерам
                                          # правильно сортировать мессаги
                                          # в порядке их появления
$maxsize = 10240;                         # Максимальный размер мессаги
                                          # Если 0 <- не лимитируется
                                          # если не определена, то 10240


# Открываем отчет фастююе на чтение
open(FUUE, "<$statfile") || die "Не могу открыть $statfile!!!\n";

# Читаем отчет
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

# Закрываем файл
close(FUUE);

#
@MonthList = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
@WDayList = ('Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресение');
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$fyear = $year+1900;

# Функция сортировки (сначала по Echo, потом по Filename)
sub sortfunc
{
 my $a = shift;
 my $b = shift;

 my $ret = uc($a->{Echo}) ne uc($b->{Echo});
 return $ret if $ret != 0;

 return uc($a->{Filename}) cmp uc($b->{Filename});
}

# Функция для конверсии размера файл
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

# Хедер
$text .= "Сегодня $WDayList[$wday], $mday $MonthList[$mon] $fyear.\n";

# А теперь выводим анонсы с сортировкой
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

# Футер
$text .= ' '.('=' x 77)."\n";
$text .= ' '.ConvSize($totalsize, 11)." в $totalfiles файлах\n";
$text .= ' '.('=' x 77)."\n";
$text .= "\n\n"; 

# Постинг
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
 