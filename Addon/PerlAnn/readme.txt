Постинг анонсов с использованием перла. Краткая документация.

1. Настройка FastUUE:

*.List.Announcer.Center должен указывать на perllist.tpl,
*.List.Announcer.(Footer|Header) должны отсутствовать.

Важные для работы строки помечены '>'.

 uue.List.Announce Yes
 uue.List.Announcer.Enabled Yes
>uue.List.Announcer.Center ReplaceFile (Template)\perllist.tpl
>uue.List.Announcer.Type Text
>uue.List.Announcer.Name stat.txt
>uue.List.Announcer.Directory (Main)\other\
 uue.List.Announcer.Area.Type Echomail

 crax.List.Announce Yes
 crax.List.Announcer.Enabled Yes
>crax.List.Announcer.Center ReplaceFile (Template)\perllist.tpl
>crax.List.Announcer.Type Text
>crax.List.Announcer.Name stat.txt
>crax.List.Announcer.Directory (Main)\other\
 crax.List.Announcer.Area.Type Echomail


2. Настройка скрипта perlann.pl:
По вкусу, но главное, чтобы $statfile указывал та тот же файл статистики.

