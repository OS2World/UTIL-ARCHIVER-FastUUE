[NewStat]

ns.collect Yes

ns.base data\ns.dat

ns.count.total yes
ns.count.hour yes
ns.count.subject yes
ns.count.from yes
ns.count.to yes

[NewStat.Groups]

begin
 name first
 desc The First
 areas replace *

 ns.scan Yes
 ns.make No
 ns.disabled No

 ns.count.total yes
 ns.count.hour yes
 ns.count.subject yes
 ns.count.from yes
 ns.count.to yes

 ns.scan.period 01/01/1980-01/01/2010
 ns.make.period 01/01/1980-01/01/2010
end
