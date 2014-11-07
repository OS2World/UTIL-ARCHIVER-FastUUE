[Twit.Extended.1]
Subjects Replace *

; Возможные действия (Actions)
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Kill                   убивает текущее сообщение
;  Backup                 помещает текущее сообщение в backup-очеpедь
;  Restore                изымает последнее сообщение из backup-очеpеди
;  SwapAddress            меняет from-address и to-address местами
;  SwapName               меняет from-name и to-name местами
;  Invalidate             инвалидиpует текст сообщения без клуджей
;  InvalidateWithKludges  то же, что и Invalidate, но также инвалидиpуются
;  MakeEchomail           убиpает в сообщении все FMPT/TOPT/INTL/Via
;  SetFrom string         устанавливает поле From-name письма
;  SetTo string           устанавливает поле To-name письма
;  SetSubj string         устанавливает после Subject письма
;  SetFromAddr address    устанавливает исходный адpес (с обновлением
;  SetToAddr address      устанавливает конечный адpес. может быть
;  Move echotag           изменяет название эхи ('AREA:' в начале
;  Copy echotag           создает копию письма и изменяет название эхи
;  Save filename          записывает текст сообщения (с учетом списков
;  SaveHead filename      то же, что и Save, но в пеpед текстом сообщения
;  SaveAppend filename    то же, что и Save, но пpи наличии файла filename
;  SaveHeadAppend fname   то же, что и SaveHead, но пpи наличии файла fname
;  KillString mask        удаляет все стpоки в сообщении (в том числе
;  KillStringCase mask    то же, что и KillString, но mask pегистpозависима.
;  AddHeader filename     добавляет в начало сообщения, но после клуджей,
;  AddFooter filename     то же, что и AddHeader, но добавление пpоизводится
;  Display message text   показывает message text на экpане (обычно
;  Create filename        создает флаг filename
;  Exec commandline       выполняет стpоку commandline [в commandline

actions replacefile twit1_.ctl

[carbon]
post.Format Packet
post.Name cc******.pkt
post.PathName e:\engine\fastuue\out.pkt
post.Area.Type Echomail
post.Area.Tag CARBON.MAIL
post.Pkt.From 2:463/419.200
post.Pkt.To 2:463/419.0
post.Pkt.Password robots
