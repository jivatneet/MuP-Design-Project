.model tiny
.data

db     509 dup(0)
dw     0000
db     508 dup(0)

.code
.startup

mov al,92h
out 06h,al            ;configure 8255
mov al,00110100b   	  ;configure 8254 (counter 0, mode 2)
out 0eh,al
mov al,64h            ; 0064h(100)
out 08h,al
mov al,00h            ;
out 08h,al

mov al,01110010b      ;configure 8254 (counter 1, mode 1)
out 0eh,al
mov al,0ch            ;00ch (12)
out 0ah,al
mov al,00h            ;
out 0ah,al
mov al,10110110b      ;configure 8254 (counter 2, mode 3)
out 0eh,al
mov al,64h            ;0064h( to be given to soc), 064h(100)
out 0ch,al
mov al,00h
out 0ch,al


ir1:
	in al,02h            ; (ir sensor), if 0 door is closed
	and al,01h
	jnz ir1

mov cl,0
mov al,00000000b  	  ;( pc4- gate1 =0)
out 04h,al
mov al,00000000b    	;( pc1- heater =0)
out 04h,al



start:
	in al, 00h
	cmp al,38            ; maintaining temperature at 30 degrees
	jge x1
	mov al,00000010b     ;heater(pc 1) on
	out 04h,al
	jmp start

x1:
	mov al,00000000b    ;heater(pc 1) off
	out 04h,al

getlevel:
	in al,02h
	mov ah,al
	and ah,01000000b
	jnz lvl3
	mov cl,04h
	jmp end10

lvl3:
	mov ah,al
	and ah,00010000b
	jnz lvl2
	mov cl,03h
	jmp end10

lvl2:
	mov ah,al
	and ah,00001000b
	jnz lvl1
	mov cl,02h
	jmp end10

lvl1:
	mov ah,al
	and ah,00001000b
	mov cl,01h

end10:
	in al,02h
	mov ah,al
	and ah,80h ;80h = sterlize
	jz ster
	mov ah,al
	and ah,20h      	   ;20h=end
	jz end1
	jmp start

end1:                  ;end pressed

call delay_20ms        ;de-bounce


in al,02h
and al,20h
jnz start

mov al,10110110b      ;configure 8254 (counter 2, mode 3) "reinitialize for adc"
out 0eh,al
mov al,64h            ;0ch( to be given to soc)
out 0ch,al
mov al,00h
out 0ch,al
mov al,01110010b      ;counter 1 mode 1
out 0eh,al
mov al,03h            ; count =3 (3 sec)
out 0ah,al
mov al,00h
out 0ah,al

mov al,00010000b     ;  pulse to gate 1 (pc4)
out 04h,al
nop
nop
mov al,00000000b    ;pulse
out 04h,al

door:
	mov al,00100000b
	out 04h,al           ;switching motor on( pc 5)
	in al,02h            ;out 1 (pb1)
	and al,02h
	jz door

mov al,00000000b      ;switching motor off( pc 5)
out 04h,al

jmp ir1

ster:                ;sterilize pressed
	call delay_20ms        ;de-bounce
	in al,02h
	and al,80h
	jnz start
	mov al,10000000b    ;lock door( pc 7)/ status on
	out 04h,al

x5:
	mov al,10000010b    ; heater (pc 1)-on
	out 04h,al


wait1:
	in al,02h
	mov ah,al
	and ah,20h
	jz end1						   	;20h=end
	in al, 00h
	cmp al,102            ; waiting for 80 degree celsius
	jle wait1

mov al,01110010b	;counter 1 mode 1
out 0eh,al
mov al,30h			;waiting time has been kept low as the simulation slows down during the period
out 0ah,al
mov al,00h
out 0ah,al
mov al,10010000b 	;  pulse to gate 1 (pc4)
out 04h,al
nop
nop
mov al,10000010b	;pulse
out 04h,al

temp100:
	in al, 00h
	cmp al,102          ; mantaining temperature=80 degrees
	jle htron
	mov al,10000000b    ;heater(pc 1) off
	out 04h,al


nop                   ;nop given to calibrate heater's rate of cooling with heating
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop

htron:
	mov al,10000010b    ;heater(pc 1) on
	out 04h,al
	in al,02h            ;out 1 (pb1)
	and al,02h
	cmp al,0
	jz temp100

mov al,01110010b    ;counter 1 mode 1
out 0eh,al
cmp cl,1            ;count of level button
jz s1
cmp cl,2
jz s2
cmp cl,3
jz s3
cmp cl,4
jz s4


s1:
	mov al,40h           ;count =120 (2 min)
	out 0ah,al
	mov al,06h
	out 0ah,al
	mov al,10010000b     ;pulse to gate 1 (pc4)
	out 04h,al
	nop
	nop
	mov al,10000000b     ;pulse
	out 04h,al

fan1:
	mov al,10001000b     ;switching motor on (pc 3)
	out 04h,al
	in al,02h            ;out 1 (pb1)
	and al,02h
	jz fan1
	jmp out1

s2:
	mov al,10110100b      ;counter 2, mode 2
	out 0eh,al
	mov al,02h            ;given count 2 (duty cycle:50%)
	out 0ch,al
	mov al,00h
	out 0ch,al
	mov al,80h            ; count =240 (4 min)
	out 0ah,al
	mov al,0ch
	out 0ah,al
	mov al,10010000b      ; pulse to gate 1 (pc4)
	out 04h,al
	nop
	nop
	mov al,10000000b    ;pulse
	out 04h,al

fan2:
	mov al,10001000b     ;switching motor on (pc 3)
	out 04h,al
	in al,02h            ;out 1 (pb1)
	and al,02h
	cmp al,0
	jz fan2
	jmp out1

s3:
	mov al,10110100b       ;counter 2, mode 2
	out 0eh,al
	mov al,03h             ;given count 3 (duty cycle:33%)
	out 0ch,al
	mov al,00h
	out 0ch,al
	mov al,0c0h            ; count =360 (6 min)
	out 0ah,al
	mov al,12h
	out 0ah,al
	mov al,10010000b       ; pulse to gate 1 (pc4)
	out 04h,al
	nop
	nop
	mov al,10000000b    ;pulse
	out 04h,al

fan3:
	mov al,10001000b    ;switching motor on (pc 3)
	out 04h,al
	in al,02h            ;out 1 (pb1)
	and al,02h
	cmp al,0
	jz fan3
	jmp out1

s4:
	mov al,10110100b      ;counter 2, mode 2
	out 0eh,al
	mov al,04h            ;given count 4 (duty cycle:25%)
	out 0ch,al
	mov al,00h
	out 0ch,al
	mov al,00h            ; count =480 (8 min)
	out 0ah,al
	mov al,19h
	out 0ah,al
	mov al,10010000b      ; pulse to gate 1 (pc4)
	out 04h,al
	nop
	nop
	mov al,10000000b      ;pulse
	out 04h,al

fan4:
	mov al,10001000b      ;switching motor on (pc 3)
	out 04h,al
	in al,02h             ;out 1 (pb1)
	and al,02h
	cmp al,0
	jz fan4
	jmp out1

out1:
	mov al,10000000b     ;switching motor off (pc 3)
	out 04h,al
	mov al,00000000b     ;unlock door( pc 7)/ status off
	out 04h,al
	mov al,10110110b     ;configure 8254 (counter 2, mode 3)
	out 0eh,al
	mov al,0e8h          ;0ch( to be given to soc)
	out 0ch,al
	mov al,03h           ;0ch( to be given to soc)
	out 0ch,al

	in al,02h
	mov ah,al
	and ah,20h
	jz end1						   	;20h=end

	jmp start


delay_20ms proc near    ;subroutine
	mov dx,cx
	mov cx,10
	x2:
	nop
	nop
	loop x2
	mov cx,dx
	ret
delay_20ms endp

.exit
end
