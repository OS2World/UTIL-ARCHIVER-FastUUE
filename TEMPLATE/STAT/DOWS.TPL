@assign @gsize 41
@assign @gfill Û
@assign @gempty °
@assign @cmsize 6
@assign @cssize 7
ÂÄÄ Day of week (by size) ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂ
³     Name     ³                 Graphic                   ³  Msgs  ³   Size  ³
ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄ´
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d1size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d1msgs @cmsize
@convsize @d1size @cssize
@leftpad @d1size @cssize
³ Monday       ³ @bar ³ @d1msgs ³ @d1size ³
@destroy @scs
@destroy @bar
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d2size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d2msgs @cmsize
@convsize @d2size @cssize
@leftpad @d2size @cssize
³ Tuesday      ³ @bar ³ @d2msgs ³ @d2size ³
@destroy @scs
@destroy @bar
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d3size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d3msgs @cmsize
@convsize @d3size @cssize
@leftpad @d3size @cssize
³ Wednesday    ³ @bar ³ @d3msgs ³ @d3size ³
@destroy @scs
@destroy @bar
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d4size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d4msgs @cmsize
@convsize @d4size @cssize
@leftpad @d4size @cssize
³ Thursday     ³ @bar ³ @d4msgs ³ @d4size ³
@destroy @scs
@destroy @bar
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d5size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d5msgs @cmsize
@convsize @d5size @cssize
@leftpad @d5size @cssize
³ Friday       ³ @bar ³ @d5msgs ³ @d5size ³
@destroy @scs
@destroy @bar
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d6size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d6msgs @cmsize
@convsize @d6size @cssize
@leftpad @d6size @cssize
³ Saturday     ³ @bar ³ @d6msgs ³ @d6size ³
@destroy @scs
@destroy @bar
@assign @scs @nothing
@assign @bar @nothing
@scale @scs @d7size @maxsize @gsize
@padch @bar @scs @gfill
@padch @bar @gsize @gempty
@leftpad @d7msgs @cmsize
@convsize @d7size @cssize
@leftpad @d7size @cssize
³ Sunday       ³ @bar ³ @d7msgs ³ @d7size ³
@destroy @scs
@destroy @bar
ÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁ
@destroy @cssize
@destroy @cmsize
@destroy @gempty
@destroy @gfill
@destroy @gsize

