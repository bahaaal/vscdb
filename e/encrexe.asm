;�����������������������������������������������������������������������������
;                   Black Wolf's File Protection Utilities 2.1s
;
;EncrEXE - This program encrypts specified file and attaches the decryption
;          code from EN_EXE onto the file so that it will decrypt on
;          each execution.  It utilizes ULTIMUTE .93� to protect then EN_EXE
;          code from easy manipulation.
;
;LISCENSE:
;    Released As Freeware - These files may be distributed freely.
;
;Any modifications made to this program should be listed below the solid line,
;along with the name of the programmer and the date the file was changed.
;Also - they should be commented where changed.
;
;NOTE THAT MODIFICATION PRIVILEDGES APPLY ONLY TO THIS VERSION (2.1s)!  
;I'd appreciate notification of any modifications if at all possible, 
;reach me through the address listed in the documentation file (bwfpu21s.doc).
;
;DISCLAIMER:  The author takes ABSOLUTELY NO RESPONSIBILITY for any damages
;resulting from the use/misuse of this program/file.  The user agrees to hold
;the author harmless for any consequences that may occur directly or 
;indirectly from the use of this program by utilizing this program/file
;in any manner.
;�����������������������������������������������������������������������������
;Modifications:
;       None as of 08/05/93 - Initial Release.

.model tiny
.radix 16
.code
       
       org 100

        extrn   _ULTMUTE:near, _END_ULTMUTE:byte, Init_Rand:near
        extrn   Get_Rand:near

start:
        call    GetFilename
        call    Init_Rand
        call    Get_Rand
        mov     [Key1],ax
        call    Get_Rand
        mov     [Key2],ax
        call    Get_Rand
        mov     [Key3],ax
        call    Get_Rand
        mov     [Key4],ax
        
        call    Do_File
        mov     ax,4c00
        int     21
;---------------------------------------------------------------------------
GetFilename:
        mov     ah,09
        mov     dx,offset Message
        int     21

        mov     dx,offset Filename_Data
        mov     al,60
        call    gets
        ret
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
Message:
        db      'EncrEXE 2.0 (c) 1993 Black Wolf Enterprises.',0a,0dh
        db      'Enter Filename To Protect -> $'
;---------------------------------------------------------------------------
gets:
        mov     ah,0a
        push    bx
        mov     bx,dx
        mov     byte ptr ds:[bx],al
        mov     byte ptr ds:[bx+1],0
        pop     bx
        int     21
        push    bx
        mov     bx,dx
        mov     al,byte ptr ds:[bx+1]   
        xor     ah,ah
        add     bx,ax
        mov     byte ptr ds:[bx+2],0
        pop     bx
        ret
;---------------------------------------------------------------------------
Save_Header:
        mov     ax,word ptr [exeheader+0e]    ;Save old SS
        mov     word ptr [Old_SS],ax
        mov     ax,word ptr [exeheader+10]    ;Save old SP
        mov     word ptr [Old_SP],ax
        mov     ax,word ptr [exeheader+14]    ;Save old IP
        mov     word ptr [Old_IP],ax
        mov     ax,word ptr [exeheader+16]    ;Save old CS
        mov     word ptr [Old_CS],ax
        ret

Do_File:        
        mov     ax,3d02
        mov     dx,offset Filename
        int     21
        jnc      Terminate_NOT
        jmp     Terminate
Terminate_NOt:
        xchg    bx,ax
        
        call    GetTime        
        call    BackupFile

        mov     ah,3f
        mov     cx,1a
        mov     dx,offset EXEheader
        int     21

        cmp     word ptr [EXEheader],'ZM'       ;not EXE file.
        je      IsEXE
        jmp     close_file
IsEXE:
        call    Save_Header
        
        mov     ax,4200
        xor     cx,cx
        xor     dx,dx                   ;Go back to beginning
        int     21

        mov     ax,word ptr [EXEheader+08]
        mov     cl,4                            ;convert header to bytes
        shl     ax,cl

        mov     word ptr [HeaderSize],ax

        mov     cx,ax        
        mov     dx,offset Header                ;Load header
        mov     ah,3f
        int     21
        
        call    Encrypt_Entire_File
        
        mov     ax,4202
        xor     cx,cx                   ;Go end
        xor     dx,dx
        int     21

        mov     cl,4
        shr     ax,cl
        inc     ax
        shl     ax,cl
        mov     cx,dx           ;Pad file
        mov     dx,ax
        mov     ax,4200
        int     21
        
        push    ax dx

        call    calculate_CSIP          ;calculate starting
                                        ;point.

        mov     ah,40
        mov     dx,offset Set_Segs
        mov     cx,end_set_segs-set_segs
        int     21

        push    bx        
        mov     si,offset begin_password        ;On Entry -> CS=DS=ES
        mov     di,offset _END_ULTMUTE          ;SI=Source, DI=Destination
        
        mov     bx,word ptr [exeheader+14]       ;BX=Next Entry Point
        add     bx,end_set_segs-set_segs

        mov     cx,end_password-begin_password+1 ;CX=Size to Encrypt
        add     cx,word ptr [headersize]         ;add in EXE header

        mov     ax,1                             ;AX=Calling Style
        call    _ULTMUTE                
                                                ;On Return -> CX=New Size

        pop     bx
        pop     dx ax                   ;DX:AX = unmodified
                                        ;file size.
        
        push    cx bx
        add     cx,end_set_segs-set_segs
        call    calculate_size
        pop     bx cx

        mov     dx,offset _END_ULTMUTE
        mov     ah,40
        int     21
        
        mov     ax,4200
        xor     dx,dx
        xor     cx,cx
        int     21
        
        mov     ah,40
        mov     cx,1a
        mov     dx,offset EXEheader
        int     21

        mov     cx,word ptr [headersize]        
        sub     cx,1a
        jz      Close_File

Zero_Header:
        push    cx
        mov     ah,40
        mov     cx,1
        mov     dx,offset zero
        int     21
        pop     cx
        loop    Zero_Header
        
Close_File:
        mov     ax,5701
        mov     cx,word ptr cs:[Time]
        mov     dx,word ptr cs:[Date]   ;restore date/time
        int     21 

        mov     ah,3e
        int     21
        ret

GetTime:
        mov     ax,5700
        int     21
        mov     word ptr cs:[Time],cx
        mov     word ptr cs:[Date],dx
        ret

Time    dw      0
Date    dw      0

Terminate:
        mov     ah,09
        mov     dx,offset BadFile
        int     21
        ret
BadFile db      'Error Opening File.',07,0dh,0a,24
zero    db      0,0
calculate_CSIP:
        push    ax
        mov     cl,4 
        mov     ax,word ptr [exeheader+8]       ;Get header length
                                                ;and convert it to
        shl     ax,cl                           ;bytes.
        mov     cx,ax
        pop     ax

        sub     ax,cx                           ;Subtract header
        sbb     dx,0                            ;size from file
                                                ;size for memory
                                                ;adjustments

        mov     cl,0c                           ;Convert DX into
        shl     dx,cl                           ;segment Address
        mov     cl,4
        push    ax                      ;Change offset (AX) into
        shr     ax,cl                   ;segment, except for last
        add     dx,ax                   ;digit.  Add to DX and
        shl     ax,cl                   ;save DX as new CS, put
        pop     cx                      ;left over into CX and
        sub     cx,ax                   ;store as the new IP.
        mov     word ptr [exeheader+16],dx    ;Set new CS:IP
        mov     word ptr [exeheader+10],0fffe ;Set new SP
        mov     word ptr [exeheader+0e],dx    ;Set new SS = CS
        mov     word ptr [exeheader+14],cx
        mov     word ptr [exeheader+6],0        ;Set 0 relocation items.
        ret

calculate_size:
        add     ax,cx                   ;Add virus size to DX:AX
        adc     dx,0
        
        push    ax                      ;Save offset for later
        mov     cl,7
        shl     dx,cl                   ;convert DX to pages
        mov     cl,9
        shr     ax,cl
        add     ax,dx
        inc     ax
        mov     word ptr [exeheader+04],ax  ;save # of pages

        pop     ax                              ;Get offset
        mov     dx,ax
        shr     ax,cl                           ;Calc remainder
        shl     ax,cl                           ;in last page
        sub     dx,ax
        mov     word ptr [exeheader+02],dx ;save remainder
        ret

Set_Segs:
        push    es ds
        push    cs cs
        pop     es ds
 End_Set_Segs:

Encrypt_Entire_File:
        mov     ah,3f        
        mov     cx,400
        mov     dx,offset Encrypt_Buffer                ;Read in buffer full
        int     21

        or      ax,ax
        jz      Add_Protection_Code                     ;None left? leave...
        
        push    ax
        call    EncryptBytes                            ;Encrypt buffer
        pop     ax
        push    ax

        xor     dx,dx
        sub     dx,ax
        mov     cx,0ffff                                ;Go back to where we
        mov     ax,4201                                 ;read from
        int     21

        mov     ah,40
        pop     cx
        mov     dx,offset Encrypt_Buffer                ;Write it back
        int     21

        cmp     ax,400                                  ;Buffer full? loop...
        je      Encrypt_Entire_File
Add_Protection_Code:
        ret

EncryptBytes:                           ;This algorithm needs help....
        push    ax bx cx dx si di
        
        mov     si,offset Encrypt_Buffer
        mov     di,si
        mov     cx,200

Decrypt_Loop:        
        lodsw
        ror     ax,1
        add     ax,[Key4]
        xor     ax,[Key3]
        rol     ax,1
        sub     ax,[Key2]
        xor     ax,[Key1]

        
        stosw
        loop    Decrypt_Loop
        
        pop     di si dx cx bx ax
        ret
                dw      0
                dw      0
Filename_data   dw      0
Filename        db      80 dup(0)
Exeheader       db      1a dup(0)
Encrypt_Buffer  dw      400 dup(0)
HeaderSize      dw      0


BackupFile:
        mov     si,offset Filename
        mov     cx,80

  Find_Eofn:
        lodsb
        cmp     al,'.'
        je      FoundDot
        or      al,al
        jz      FoundZero
        loop    Find_Eofn
        jmp     Terminate
FoundZero:
        mov     byte ptr [si-1],'.'
        inc     si
FoundDot:
        mov     word ptr [si],'LO'
        mov     byte ptr [si+2],'D'
        mov     byte ptr [si+3],0

        
        mov     dx,offset Filename
        mov     word ptr [SourceF],bx
        mov     ah,3c
        xor     cx,cx
        int     21
        jnc     GCreate
         jmp    Terminate
GCreate:
        mov     word ptr cs:[Destf],ax
BackLoop:
        mov     ah,3f
        mov     bx,word ptr cs:[Sourcef]
        mov     cx,400
        mov     dx,offset Encrypt_Buffer
        int     21

        mov     cx,ax
        mov     ah,40
        mov     bx,word ptr cs:[Destf]
        mov     dx,offset Encrypt_Buffer
        int     21

        cmp     ax,400
        je      BackLoop
DoneBack:
        mov     ah,3e
        mov     bx,word ptr cs:[Destf]
        int     21

        mov     ax,4200
        xor     cx,cx
        xor     dx,dx
        mov     bx,word ptr cs:[Sourcef]
        int     21
        ret

SourceF dw      0
DestF   dw      0


begin_password:         ;code from en_exe
;------------------------------------------------------------------------
db 0e8h, 02dh, 01h, 058h, 050h, 02eh, 089h, 086h, 076h, 02h
db 02eh, 089h, 086h, 0fh, 01h, 033h, 0dbh, 05h, 010h, 00h
db 08ch, 0c9h, 02bh, 0c8h, 0d1h, 0e1h, 083h, 0d3h, 00h, 0ebh
db 0ch, 090h, 0eah, 0d1h, 0e3h, 0d1h, 0e1h, 083h, 0d3h, 00h
db 0ebh, 0bh, 0ffh, 0d1h, 0e3h, 0d1h, 0e1h, 083h, 0d3h, 00h
db 0ebh, 0edh, 09ah, 08eh, 0c0h, 08eh, 0d8h, 033h, 0f6h, 033h
db 0ffh, 0e8h, 0fbh, 00h, 0ebh, 01h, 0eah, 0adh, 033h, 086h
db 080h, 02h, 03h, 086h, 082h, 02h, 0d1h, 0c8h, 033h, 086h
db 084h, 02h, 02bh, 086h, 086h, 02h, 0d1h, 0c0h, 0abh, 053h
db 051h, 08bh, 0c6h, 08bh, 0d8h, 0b1h, 04h, 0d3h, 0e8h, 0d3h
db 0e0h, 03bh, 0c3h, 075h, 0dh, 083h, 0eeh, 010h, 083h, 0efh
db 010h, 01eh, 058h, 040h, 08eh, 0d8h, 08eh, 0c0h, 059h, 05bh
db 0e2h, 0c9h, 083h, 0fbh, 00h, 074h, 06h, 04bh, 0ebh, 0c1h
db 0e8h, 0b6h, 00h, 050h, 01eh, 033h, 0c0h, 08eh, 0d8h, 08dh
db 086h, 0d5h, 01h, 087h, 06h, 00h, 00h, 050h, 08ch, 0c8h
db 087h, 06h, 02h, 00h, 050h, 033h, 0c9h, 02eh, 0c7h, 086h
db 0a4h, 01h, 090h, 090h, 0f7h, 0f1h, 058h, 087h, 06h, 02h
db 00h, 058h, 087h, 06h, 00h, 00h, 01fh, 058h, 07h, 01fh
db 02eh, 08bh, 086h, 076h, 02h, 05h, 010h, 00h, 02eh, 03h
db 086h, 07ch, 02h, 0fah, 08eh, 0d0h, 02eh, 08bh, 0a6h, 07eh
db 02h, 0fbh, 033h, 0c0h, 08bh, 0f0h, 08bh, 0f8h, 02eh, 0ffh
db 0aeh, 078h, 02h, 02eh, 08bh, 086h, 076h, 02h, 05h, 010h
db 00h, 02eh, 01h, 086h, 07ah, 02h, 0e8h, 01h, 00h, 0cfh
db 050h, 053h, 051h, 052h, 06h, 01eh, 056h, 057h, 055h, 08bh
db 0ddh, 02eh, 08bh, 0afh, 0a0h, 02h, 02eh, 08bh, 08fh, 08eh
db 02h, 0bh, 0c9h, 074h, 027h, 03h, 0ebh, 02eh, 0c5h, 0b6h
db 088h, 02h, 02bh, 0ebh, 08ch, 0d8h, 02eh, 03h, 087h, 076h
db 02h, 05h, 010h, 00h, 08eh, 0d8h, 02eh, 08bh, 087h, 076h
db 02h, 05h, 010h, 00h, 01h, 04h, 083h, 0c5h, 04h, 0e8h
db 017h, 00h, 0e2h, 0d9h, 05dh, 05fh, 05eh, 01fh, 07h, 05ah
db 059h, 05bh, 058h, 0c3h, 05dh, 0ebh, 01h, 0eah, 055h, 081h
db 0edh, 03h, 01h, 0c3h, 0c3h, 0ebh, 014h, 090h, 0eah, 0e8h
db 02ch, 00h, 0ebh, 06h, 090h, 0e8h, 026h, 00h, 0ebh, 0f5h
db 0bh, 0edh, 074h, 0f7h, 05dh, 0ebh, 0e9h, 055h, 033h, 0edh
db 0ebh, 0efh, 050h, 072h, 06fh, 074h, 065h, 063h, 074h, 069h
db 06fh, 06eh, 020h, 062h, 079h, 020h, 042h, 06ch, 061h, 063h
db 06bh, 020h, 057h, 06fh, 06ch, 066h, 0e4h, 021h, 034h, 02h
db 0e6h, 021h, 045h, 0c3h, 00h, 00h
;------------------------------------------------------------------------
Old_IP  dw      0
Old_CS  dw      0fff0
Old_SS  dw      0fff0
Old_SP  dw      0
Key1    dw      0
Key2    dw      0
Key3    dw      0
Key4    dw      0
;------------------------------------------------------------------------
end_password:
Header:
        db     800 dup(0)       ;leave space for ultimute with db (0)'s
end start

N ENCREXE.COM
E 0100 E8 23 00 E8 7B 15 E8 89 15 A3 27 0E E8 83 15 A3 
E 0110 29 0E E8 7D 15 A3 2B 0E E8 77 15 A3 2D 0E E8 98 
E 0120 00 B8 00 4C CD 21 B4 09 BA 36 01 CD 21 BA 90 03 
E 0130 B0 60 E8 4D 00 C3 45 6E 63 72 45 58 45 20 32 2E 
E 0140 30 20 28 63 29 20 31 39 39 33 20 42 6C 61 63 6B 
E 0150 20 57 6F 6C 66 20 45 6E 74 65 72 70 72 69 73 65 
E 0160 73 2E 0A 0D 45 6E 74 65 72 20 46 69 6C 65 6E 61 
E 0170 6D 65 20 54 6F 20 50 72 6F 74 65 63 74 20 2D 3E 
E 0180 20 24 B4 0A 53 8B DA 88 07 C6 47 01 00 5B CD 21 
E 0190 53 8B DA 8A 47 01 32 E4 03 D8 C6 47 02 00 5B C3 
E 01A0 A1 20 04 A3 23 0E A1 22 04 A3 25 0E A1 26 04 A3 
E 01B0 1F 0E A1 28 04 A3 21 0E C3 B8 02 3D BA 92 03 CD 
E 01C0 21 73 03 E9 E9 00 93 E8 D1 00 E8 61 0A B4 3F B9 
E 01D0 1A 00 BA 12 04 CD 21 81 3E 12 04 4D 5A 74 03 E9 
E 01E0 A5 00 E8 BB FF B8 00 42 33 C9 33 D2 CD 21 A1 1A 
E 01F0 04 B1 04 D3 E0 A3 2C 0C 8B C8 BA 2F 0E B4 3F CD 
E 0200 21 E8 2D 01 B8 02 42 33 C9 33 D2 CD 21 B1 04 D3 
E 0210 E8 40 D3 E0 8B CA 8B D0 B8 00 42 CD 21 50 52 E8 
E 0220 AE 00 B4 40 BA 2B 03 B9 06 00 CD 21 53 BE A7 0C 
E 0230 BF 29 1A 8B 1E 26 04 83 C3 06 90 B9 89 01 03 0E 
E 0240 2C 0C B8 01 00 E8 E8 13 5B 5A 58 51 53 83 C1 06 
E 0250 90 E8 B5 00 5B 59 BA 29 1A B4 40 CD 21 B8 00 42 
E 0260 33 D2 33 C9 CD 21 B4 40 B9 1A 00 BA 12 04 CD 21 
E 0270 8B 0E 2C 0C 83 E9 1A 74 0E 51 B4 40 B9 01 00 BA 
E 0280 CE 02 CD 21 59 E2 F2 B8 01 57 2E 8B 0E AB 02 2E 
E 0290 8B 16 AD 02 CD 21 B4 3E CD 21 C3 B8 00 57 CD 21 
E 02A0 2E 89 0E AB 02 2E 89 16 AD 02 C3 00 00 00 00 B4 
E 02B0 09 BA B7 02 CD 21 C3 45 72 72 6F 72 20 4F 70 65 
E 02C0 6E 69 6E 67 20 46 69 6C 65 2E 07 0D 0A 24 00 00 
E 02D0 50 B1 04 A1 1A 04 D3 E0 8B C8 58 2B C1 83 DA 00 
E 02E0 B1 0C D3 E2 B1 04 50 D3 E8 03 D0 D3 E0 59 2B C8 
E 02F0 89 16 28 04 C7 06 22 04 FE FF 89 16 20 04 89 0E 
E 0300 26 04 C7 06 18 04 00 00 C3 03 C1 83 D2 00 50 B1 
E 0310 07 D3 E2 B1 09 D3 E8 03 C2 40 A3 16 04 58 8B D0 
E 0320 D3 E8 D3 E0 2B D0 89 16 14 04 C3 06 1E 0E 0E 07 
E 0330 1F B4 3F B9 00 04 BA 2C 04 CD 21 0B C0 74 1F 50 
E 0340 E8 1C 00 58 50 33 D2 2B D0 B9 FF FF B8 01 42 CD 
E 0350 21 B4 40 59 BA 2C 04 CD 21 3D 00 04 74 D3 C3 50 
E 0360 53 51 52 56 57 BE 2C 04 8B FE B9 00 02 AD D1 C8 
E 0370 03 06 2D 0E 33 06 2B 0E D1 C0 2B 06 29 0E 33 06 
E 0380 27 0E AB E2 E8 5F 5E 5A 59 5B 58 C3 00 00 00 00 
E 0390 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 03A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 03B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 03C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 03D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 03E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 03F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0400 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0410 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0420 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0430 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0440 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0450 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0460 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0470 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0480 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0490 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 04A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 04B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 04C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 04D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 04E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 04F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0500 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0510 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0520 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0530 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0540 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0550 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0560 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0570 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0580 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0590 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 05A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 05B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 05C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 05D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 05E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 05F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0600 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0610 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0620 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0630 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0640 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0650 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0660 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0670 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0680 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0690 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 06A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 06B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 06C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 06D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 06E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 06F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0700 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0710 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0720 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0730 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0740 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0750 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0760 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0770 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0780 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0790 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 07A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 07B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 07C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 07D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 07E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 07F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0800 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0810 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0820 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0830 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0840 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0850 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0860 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0870 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0880 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0890 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 08A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 08B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 08C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 08D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 08E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 08F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0900 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0910 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0920 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0930 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0940 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0950 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0960 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0970 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0980 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0990 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 09A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 09B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 09C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 09D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 09E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 09F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A30 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A70 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0A90 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0AA0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0AB0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0AC0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0AD0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0AE0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0AF0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B30 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B70 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0B90 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0BA0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0BB0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0BC0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0BD0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0BE0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0BF0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0C00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0C10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0C20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 BE 92 
E 0C30 03 B9 80 00 AC 3C 2E 74 0E 0A C0 74 05 E2 F5 E9 
E 0C40 6D F6 C6 44 FF 2E 46 C7 04 4F 4C C6 44 02 44 C6 
E 0C50 44 03 00 BA 92 03 89 1E A3 0C B4 3C 33 C9 CD 21 
E 0C60 73 03 E9 4A F6 2E A3 A5 0C B4 3F 2E 8B 1E A3 0C 
E 0C70 B9 00 04 BA 2C 04 CD 21 8B C8 B4 40 2E 8B 1E A5 
E 0C80 0C BA 2C 04 CD 21 3D 00 04 74 DE B4 3E 2E 8B 1E 
E 0C90 A5 0C CD 21 B8 00 42 33 C9 33 D2 2E 8B 1E A3 0C 
E 0CA0 CD 21 C3 00 00 00 00 E8 2D 01 58 50 2E 89 86 76 
E 0CB0 02 2E 89 86 0F 01 33 DB 05 10 00 8C C9 2B C8 D1 
E 0CC0 E1 83 D3 00 EB 0C 90 EA D1 E3 D1 E1 83 D3 00 EB 
E 0CD0 0B FF D1 E3 D1 E1 83 D3 00 EB ED 9A 8E C0 8E D8 
E 0CE0 33 F6 33 FF E8 FB 00 EB 01 EA AD 33 86 80 02 03 
E 0CF0 86 82 02 D1 C8 33 86 84 02 2B 86 86 02 D1 C0 AB 
E 0D00 53 51 8B C6 8B D8 B1 04 D3 E8 D3 E0 3B C3 75 0D 
E 0D10 83 EE 10 83 EF 10 1E 58 40 8E D8 8E C0 59 5B E2 
E 0D20 C9 83 FB 00 74 06 4B EB C1 E8 B6 00 50 1E 33 C0 
E 0D30 8E D8 8D 86 D5 01 87 06 00 00 50 8C C8 87 06 02 
E 0D40 00 50 33 C9 2E C7 86 A4 01 90 90 F7 F1 58 87 06 
E 0D50 02 00 58 87 06 00 00 1F 58 07 1F 2E 8B 86 76 02 
E 0D60 05 10 00 2E 03 86 7C 02 FA 8E D0 2E 8B A6 7E 02 
E 0D70 FB 33 C0 8B F0 8B F8 2E FF AE 78 02 2E 8B 86 76 
E 0D80 02 05 10 00 2E 01 86 7A 02 E8 01 00 CF 50 53 51 
E 0D90 52 06 1E 56 57 55 8B DD 2E 8B AF A0 02 2E 8B 8F 
E 0DA0 8E 02 0B C9 74 27 03 EB 2E C5 B6 88 02 2B EB 8C 
E 0DB0 D8 2E 03 87 76 02 05 10 00 8E D8 2E 8B 87 76 02 
E 0DC0 05 10 00 01 04 83 C5 04 E8 17 00 E2 D9 5D 5F 5E 
E 0DD0 1F 07 5A 59 5B 58 C3 5D EB 01 EA 55 81 ED 03 01 
E 0DE0 C3 C3 EB 14 90 EA E8 2C 00 EB 06 90 E8 26 00 EB 
E 0DF0 F5 0B ED 74 F7 5D EB E9 55 33 ED EB EF 50 72 6F 
E 0E00 74 65 63 74 69 6F 6E 20 62 79 20 42 6C 61 63 6B 
E 0E10 20 57 6F 6C 66 E4 21 34 02 E6 21 45 C3 00 00 00 
E 0E20 00 F0 FF F0 FF 00 00 00 00 00 00 00 00 00 00 00 
E 0E30 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0E40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0E50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0E60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0E70 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0E80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0E90 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0EA0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0EB0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0EC0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0ED0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0EE0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0EF0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F20 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F30 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F70 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0F90 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0FA0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0FB0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0FC0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0FD0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0FE0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 0FF0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1020 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1030 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1040 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1050 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1060 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1070 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1080 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1090 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 10A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 10B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 10C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 10D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 10E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 10F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1100 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1110 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1120 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1130 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1140 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1150 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1160 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1170 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1180 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1190 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 11A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 11B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 11C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 11D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 11E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 11F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1200 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1210 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1220 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1230 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1240 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1250 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1260 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1270 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1280 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1290 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 12A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 12B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 12C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 12D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 12E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 12F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1300 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1310 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1320 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1330 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1340 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1350 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1360 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1370 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1380 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1390 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 13A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 13B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 13C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 13D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 13E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 13F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1400 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1410 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1420 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1430 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1440 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1450 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1460 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1470 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1480 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1490 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 14A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 14B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 14C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 14D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 14E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 14F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1500 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1510 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1520 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1530 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1540 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1550 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1560 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1570 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1580 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1590 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 15A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 15B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 15C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 15D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 15E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 15F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1600 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1610 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1620 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1630 55 50 53 51 52 06 1E 56 57 E8 3B 00 41 41 2E 89 
E 1640 8E 22 19 2E 89 9E AF 16 E8 36 00 E8 63 00 E8 84 
E 1650 00 E8 88 01 E8 AC 01 E8 2B 02 5F 5E 1F 07 5A 59 
E 1660 5B 58 2E 03 8E F5 19 41 41 5D 3D 03 00 74 07 3D 
E 1670 02 00 74 01 C3 CB CF 8B EC 8B 6E 00 81 ED 3C 16 
E 1680 C3 50 1E 33 C0 8E D8 A1 6C 04 1F 2E 89 86 AB 16 
E 1690 58 C3 51 52 2E 8B 86 AB 16 B9 AD DE F7 E1 35 DA 
E 16A0 DA D1 C8 2E 89 86 AB 16 5A 59 C3 00 00 00 00 00 
E 16B0 00 E8 DE FF 25 03 00 3C 01 74 F6 2E 88 86 AD 16 
E 16C0 E8 CF FF D0 E8 72 07 2E C6 86 AE 16 00 C3 2E C6 
E 16D0 86 AE 16 01 C3 1E 56 0E 1F 8B F5 E8 B4 FF 89 84 
E 16E0 34 19 E8 AD FF 89 84 AE 19 89 84 ED 19 E8 A2 FF 
E 16F0 89 84 CE 19 89 84 F2 19 E8 97 FF 88 84 8D 19 88 
E 1700 A4 92 19 E8 8C FF 88 84 AA 19 88 A4 B4 19 E8 81 
E 1710 FF 88 84 C0 19 88 A4 C4 19 E8 76 FF 88 84 D2 19 
E 1720 88 A4 D9 19 E8 6B FF 88 84 DA 19 88 A4 E2 19 8A 
E 1730 84 AD 16 80 A4 26 19 E6 8A E0 D0 E4 D0 E4 D0 E4 
E 1740 08 A4 26 19 50 8A 84 AE 16 08 84 26 19 80 A4 1D 
E 1750 19 FE 08 84 1D 19 80 A4 28 19 FE 08 84 28 19 80 
E 1760 A4 29 19 FE 08 84 29 19 58 80 A4 33 19 FC 08 84 
E 1770 33 19 80 A4 38 19 E4 08 84 38 19 08 A4 38 19 80 
E 1780 A4 3E 19 FC 08 84 3E 19 80 A4 62 19 FC 08 84 62 
E 1790 19 80 A4 8E 19 FC 08 84 8E 19 80 A4 9F 19 FC 08 
E 17A0 84 9F 19 80 A4 E7 19 FC 08 84 E7 19 80 A4 E9 19 
E 17B0 FC 08 84 E9 19 80 A4 AD 19 FC 80 A4 CD 19 FC 08 
E 17C0 84 AD 19 08 84 CD 19 80 A4 EC 19 FC 80 A4 F1 19 
E 17D0 FC 08 84 EC 19 08 84 F1 19 5E 1F C3 06 57 51 0E 
E 17E0 07 8D BE F9 19 E8 AA FE 25 1F 00 D1 E8 D1 E0 40 
E 17F0 2E 88 86 F7 19 91 E8 99 FE 25 07 00 AA E2 F7 59 
E 1800 5F 07 C3 56 57 53 51 1E 53 57 0E 1F 8D B6 1D 19 
E 1810 A5 A4 AC A5 A4 AC A5 2E 8A 8E F7 19 32 ED 8D B6 
E 1820 F9 19 51 AC 56 8A D8 32 FF D1 E3 03 DD 81 C3 FD 
E 1830 18 2E 8B 07 8A CC 32 E4 8D B6 32 19 03 F0 F2 A4 
E 1840 5E 59 E2 DE 8D B6 25 19 A5 AC A5 AC A5 A5 5E 5B 
E 1850 8B C7 2B C6 2E 89 86 F5 19 50 F7 D0 05 05 00 AB 
E 1860 58 03 D8 26 89 5C 01 8B C7 1F 59 5B 5F 5E 56 57 
E 1870 53 51 50 2B C7 03 C3 26 89 45 01 58 8B F8 F2 A4 
E 1880 59 5B 5F 5E C3 53 51 57 56 E8 60 00 2E 8B 86 F5 
E 1890 19 40 40 03 F8 8B F7 06 1F 51 E8 88 00 2E 8B 8E 
E 18A0 F7 19 50 53 51 52 56 57 2E 8B B6 E8 18 4E 2E 8A 
E 18B0 1C 2E 89 B6 E8 18 8D B6 0D 19 32 FF D1 E3 03 F3 
E 18C0 2E 8B 1C 03 DD 2E 89 9E EA 18 5F 5E 5A 59 5B 58 
E 18D0 2E FF 96 EA 18 E2 CB 59 E8 4A 00 E8 4A 00 E8 0B 
E 18E0 00 E2 B6 5E 5F 59 5B C3 00 00 00 00 56 8D B6 F9 
E 18F0 19 2E 03 B6 F7 19 2E 89 B6 E8 18 5E C3 00 04 05 
E 1900 02 08 22 2B 2C 58 05 5E 1B 7A 1F 9A 1A 32 19 37 
E 1910 19 5D 19 3A 19 E7 19 E9 19 EB 19 F0 19 BF 34 12 
E 1920 C3 B9 34 12 C3 87 1D C3 47 47 C3 49 74 03 E9 FF 
E 1930 FC C3 81 F3 34 12 C3 86 FB C3 EB 06 90 D1 CB EB 
E 1940 16 90 50 E8 03 00 58 EB F4 E4 21 0C 02 E6 21 C3 
E 1950 E4 21 34 02 E6 21 C3 50 E8 F5 FF 58 C3 FA EB 09 
E 1960 90 D1 C3 E8 08 00 EB 21 90 E8 02 00 EB F3 50 1E 
E 1970 33 C0 8E D8 EB 01 EA 87 06 04 00 EB 01 9A 87 06 
E 1980 0C 00 87 06 04 00 1F 58 C3 C3 EB 02 EA EA 43 C3 
E 1990 EB 10 EA FA 87 06 84 00 87 06 84 00 FB 1F 58 4B 
E 19A0 EB 09 50 1E 33 C0 8E D8 EB E9 E8 C3 81 C3 34 12 
E 19B0 53 E8 0D 00 E8 81 EB B4 19 80 87 BF 19 BA EB 05 
E 19C0 EA 5B EB F1 EA 80 AF BF 19 BA 5B C3 81 EB 34 12 
E 19D0 EB 09 E8 E6 21 34 02 EB 0A E8 E8 50 E4 21 34 02 
E 19E0 EB F1 E8 E6 21 58 C3 4B C3 43 C3 81 EB 34 12 C3 
E 19F0 81 C3 34 12 C3 00 00 00 00 00 00 00 00 00 00 00 
E 1A00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1A10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
E 1A20 00 00 00 00 00 00 00 00 00 
RCX
1929
W
Q
