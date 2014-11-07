;
; dos-part of NTVDMclp
;
; (q) by sergey korowkin aka sk // [rAN], 2000.
; (q) by Tatyana Medvedeva aka tm // [ice-lock NPD2000].
;
; http://aux.ru/sk, skank@mail.ru, 2:6033/27@fidonet
;

.286
code    segment
        assume cs:code, ds:code, ss:code, es:nothing

        org 100h

        WINOLDAPVERSION   = 001Bh

        clpVERSION        = 0100h

        clpfnGETVERSION   = 0000h
        clpfnINIT         = 0001h
        clpfnDONE         = 0002h

start:  jmp realstart

        ; resident part
our2f:  pushf

        ; check for presence
        cmp ax, 'sk'
        jne ah17

        mov ax, 'tm'

        mov dx, cs:old2f.word ptr 0
        mov ds, cs:old2f.word ptr 2

        push cs
        pop cx

        mov bx, cs:Handle

        jmp exit

        ; ah=17h comparator
ah17:   cmp ah, 17h
        jne tm

        cmp al, 00h
        jl exit

        cmp al, 09h
        jg exit

        cmp al, 09h
        je al09

        push ds

        cmp al, 03h
        jne alnot03

        ; al=03h need some mappings (si -> ds, cx -> si)
        push si
        pop ds
        mov si, cx

alnot03:
        mov cx, ax

        mov ax, cs:Handle

        db 0c4h
        db 0c4h
        db 58h
        db 02h

        pop ds
        popf
        jmp bye

al09:   xchg si, dx
        xchg cx, ax

        popf
        jmp bye

        ; ..maybe this is direct call to dll?
tm:     cmp ax, 'tm'
        jne exit

        mov ax, cs:Handle

        db 0c4h
        db 0c4h
        db 58h
        db 02h

        jmp bye

        ; ..uh. fuckin' 2fh handler..
exit:   popf
        db 0eah
old2f   dd ?

bye:    retf 2

        ; dll handle
Handle  dw 0

        ; non-resident part
realstart:
        mov dx, offset greetz
        call msg

        ; check for NT
        mov ax, 3306h
        int 21h

        mov dx, offset nt

        cmp bx, 3205h
        jne theend

        ; check for presence
        mov ax, 'sk'

        int 2fh

        cmp ax, 'tm'

        je already

        ; load dll
        mov si, offset dllName
        mov di, offset dllReg
        mov bx, offset dllDisp

        db 0c4h
        db 0c4h
        db 58h
        db 00h

        mov Handle, ax

        mov dx, offset loaderr

        jc theend

        ; check version

        mov cx, clpfnGETVERSION

        call dll

        mov dx, offset vermism

        cmp cx, clpVERSION

        jne theend

        ; init dll

        mov cx, clpfnINIT

        call dll

        ; save vector
        mov ax, 352Fh
        int 21h

        mov old2f.word ptr 0,bx
        mov old2f.word ptr 2,es

        ; set vector
        mov dx, offset our2f
        mov ax, 252fh
        int 21h

        ; show some stuff 'bout TSR
        mov dx, offset goinTSR

        call msg

        ; TSR
        mov dx, offset realstart
        int 27h

        ; show the message
msg:    mov ah, 09h

        int 21h

        ret

        ; show the message and shut down
theend: mov ax, cs:Handle

        cmp ax, 0

        je msg

        call msg

        ; shut down dll..
        mov cx, clpfnDONE

        call dll

        ; unload it
        mov ax, cs:Handle

        db 0c4h
        db 0c4h
        db 58h
        db 01h

        ret

dll:    ; call dll
        mov ax, Handle

        db 0c4h
        db 0c4h
        db 58h
        db 02h

        ret

        ; ..if we're already installed
already:
        cmp word ptr cs:[81h], 'U/'
        je unload

        cmp word ptr cs:[81h], 'u/'
        je unload

        push cs
        pop ds

        mov dx, offset alr

        call msg

        ret

        ; ..unload!
unload:
        ; ds:dx - old handler
        ; cx - code
        ; bx - dll handle

        mov ax, 252fh
        int 21h

        push cs
        pop ds

        dec cx
        push cx
        pop es
        mov word ptr es:[1], 0

        mov Handle, bx

        mov dx, offset unloadd

        jmp theend

        ; system data ;)
dllName db 'ntvdmclp.dll', 0
dllReg  db 'ntvdmclpRegister', 0
dllDisp db 'ntvdmclpDispatch', 0

        ; messages
greetz  db 'NTVDMclp v1.0, (q) by sk&tm // [rAN], 2000.', 0dh, 0ah, 0dh, 0ah, '$'
nt      db 'please install NT4 or W2k before using this program!', 0dh, 0ah, '$'
loaderr db 'failed to load NTVDMclp.dll.', 0dh, 0ah, '$'
vermism db 'version mismatch.', 0dh, 0ah, '$'
gointsr db 'installed.', 0dh, 0ah, '$'
alr     db 'already installed, use /U switch to unload.', 0dh, 0ah, '$'
unloadd db 'unloaded.', 0dh, 0ah, '$'

code    ends
        end Start
