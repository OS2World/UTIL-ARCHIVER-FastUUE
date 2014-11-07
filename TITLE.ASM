;
; title for NTVDMclp
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

        clptitleSET       = 0010h

start:
        mov ax, 'sk'

        push ds

        int 2fh

        pop ds

        cmp ax, 'tm'

        jne load

        mov Handle, bx

        call set

        ret

        ; we're need to load dll before calling clptitleSET...
load:   mov ax, 3306h

        int 21h

        mov dx, offset nt

        cmp bx, 3205h

        jne off

        mov si, offset dllName
        mov di, offset dllReg
        mov bx, offset dllDisp

        db 0c4h
        db 0c4h
        db 58h
        db 00h

        jc oops

        mov Handle, ax

        call set

        mov ax, Handle

        db 0c4h
        db 0c4h
        db 58h
        db 01h

        ret

set:    xor bh, bh
        mov bl, cs:[80h]

        add bl, 81h

        mov byte ptr cs:[bx], 0

        sub bl, 81h

        mov dx, 81h

        mov cx, clptitleSET
        mov ax, Handle

        db 0c4h
        db 0c4h
        db 58h
        db 02h

        ret

off:    mov ah, 09h
        int 21h

        ret

oops:   mov dx, offset failed

        jmp off

Handle  dw ?

        ; system data ;)
dllName db 'ntvdmclp.dll', 0
dllReg  db 'ntvdmclpRegister', 0
dllDisp db 'ntvdmclpDispatch', 0

        ; messages
nt      db 'this program requires NT$'
failed  db 'failed to load dll$'

code    ends
        end Start
