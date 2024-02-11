; 	Csapkodó Csóka -	Egyszerű Flappy Bird klón HomeLab 3/4 gépre
;	
;   A Flappy Bird clone for the famous Homelab 3/4 computers
;
;   MIT licence - feel free to use this code for simply anything.
;
;	Kolma, Kornél (Ko-Ko), 2024. 
;	
;   https://pleasurebytes.games
;
;   https://pexy.io
;
;	e-mail: kolma.kornel@gmail.com




org 0x4100

SCREEN:		EQU	0xF000
BUFFER:		EQU	0x6000

inittitle:
	out ($ff),a	
	ld sp,$40FF
	call clearScreen
	ld a,$20
	call BirdMask	
	call initTitlescreen
	call waitNoSpace
	
	ld hl,modifybackground+1	;madár háttér a title-nél space
	ld (hl), $20
	
	ld hl,fbirdytemp
	ld (hl),0
	
	ld hl,b1x					;title madár pozijának resetelése
	inc hl
	ld a,38
	ld (hl),a
	ld hl,b2x
	inc hl
	ld a,39
	ld (hl),a	
	
	
	
titleloop:
	ld de,SCREEN+30*64
	call printWave
	call slowDown
	call scrollWave
	ld hl,0xe801	
	ld a,(hl)
	bit 0,a
	jp nz,titleloop
	
	
	ld de,SCREEN+30*64		;második fázis, áradás I. fejezet !!!
	ld b,17
	call cunamiWave
	
	ld b,20
justwave:					;egy kis hullámzás, ami elriasztja a csókát
	push b
	ld de,SCREEN+14*64
	call printWave
	call slowDown
	call scrollWave
	pop b
	djnz justwave

	
	ld hl,SCREEN+36+7*64
	ld (hl),$20				;statikmadár farkincáját töröljük

	
	
	ld hl,fbirdy			;madár animáció + hullámzás
	ld (hl),5
	ld b,120
	ld a,0
flyaway:
	push b
	inc a
	cp 15
	jp nz, nodecy
	ld hl,b1x					;title madár pozijának rezetelése
	inc hl
	inc (hl)
	ld hl,b2x
	inc hl
	inc (hl)
	ld a,0
	ld hl,fbirdy
	dec (hl)	
nodecy:
	push af
b1x:
	ld hl,SCREEN+26			
	call clearBird
b2x:
	ld hl,SCREEN+27
	call printBird
	ld de,SCREEN+14*64
	call printWave
	call slowDown
	call scrollWave
	pop af
	pop b	
	djnz flyaway


	ld de,SCREEN+13*64				;utolsó fázis, áradás II. !!!
	ld b,14
	call cunamiWave


	ld a,$2e
	call BirdMask
	call clearScreen
		
	ld hl,modifybackground+1		;madár háttér visszaállítása "."-ra
	ld (hl), $2e
	
	ld a,r							;rnd seedelése
	ld (rindex),a
	
	call clearBuffer
	call initBeforeGameVariable
	call initGameScreen
	
gameloop:
	ld hl,BUFFER+12+3*64			
	call clearBird					;madárka törlése a bufferből
	call screenScroll				;buffer scrollozása
	ld hl,BUFFER+12+3*64
	call printBird					;madárka kirajzolása + gameover check
	call drawLastColumn				;utolsó oszlop (üres v. cső) megrajzolása bufferbe
	
	ld 	hl,firstpress				;addig nincs gravitáció, míg meg nem nyomta a
	ld  a,(hl)						;space gombot (lásd. keyCheck)
	cp 0
	jp z,nogravity
	ld hl, gravitytimer
	ld a,(hl)
	cp 1							;minél nagyobb, annál kisebb a gravitáció, most 1 csak
	jp nz, nogravtimer
	ld (hl),0
	ld hl,fbirdy					;"gravitáció"
	;inc (hl)						
nogravtimer:
	inc (hl)						;változó, hogy mit növel
nogravity:
	
	
	call slowDown					;e helyett inkább egy timer?
	call copyBuffer
	
	ld hl, gameover
	ld a,(hl)
	cp 0
	jp z,notgameover
;****
	call printGameOverText
	call makeGameOverSound
	call waitSpace
	ld de,SCREEN+30*64				;áradáseffekt játék végén
	ld b,30
	call cunamiWave
	jp inittitle


notgameover:	
	call keyCheck
	jp gameloop
	

;########################### JÁTÉK RUTINOK
;#### billentyű rutinok

keyCheck:
	ld hl,$e801				;SPACE
	ld a,(hl)
	bit 0,a
	jp z,spacepressed
	ret
spacepressed:
	ld hl,firstpress
	ld (hl),1
	ld hl,fbirdy
	dec (hl)
	;dec (hl)
	ret

waitSpace:
	ld hl,0xe801	
	ld a,(hl)
	bit 0,a
	jp nz,waitSpace
	ret

waitNoSpace:
	ld hl,0xe801	
	ld a,(hl)
	bit 0,a
	jp z,waitNoSpace
	ret

;#### title-nél a hullám emelkedő rutinja
cunamiWave:	
cunamiloop:
	push bc
	push de
	call printWave
	ld b,3
moreslow:							;még több lassítás, hogy szép legyen a víz effekt
	push bc
	;call slowDown
	call scrollWave
	;out ($7f),a
	ld h,3					;hosszúság -> max 10s
	ld l,205				;hangmagasság -> 250Hz - 2kHz
	call soundGen
	out ($ff),a	
	pop bc
	djnz moreslow
	call scrollWave
	pop de
	ld hl,de
	scf
	ccf
	ld bc,64
	sbc hl,bc
	ld de,hl
	pop bc
	djnz cunamiloop
	ret
	
BirdMask:
	ld (fbird+2),a
	ld (fbird+3),a
	ld (fbird+7),a
	ret

;##### print Csapkodó Csóka
printBird:			;HL-ben madár bázis koordináta (+1, lásd. inc a)
	ld de,64
	ld a,(fbirdy)					;madár pozi kiszámítsa
	ld (fbirdytemp),a
	inc a
	ld b,a
birdycalc:
	add hl,de
	djnz birdycalc
	
	call collisionCheck				;hl-ben a lényeg, de vissza kell állítani
	
	ld a,(fbirdphase)
	cp 2
	jr nc,f2
f1:	
	push hl
	ld hl,fbirdphase
	inc (hl)
	pop hl
	ld a,(fbird)
	ld (hl),a
	inc hl
	ld a,(fbird+1)
	ld (hl),a
	add hl,de
	dec hl
	ld a,(fbird+2)
	ld (hl),a
	inc hl
	ld a,(fbird+3)
	ld (hl),a
	ret
f2:
	push hl
	ld hl,fbirdphase
	inc (hl)
	ld a,(hl)
	cp 4
	jp nz,lessthancycle
	ld a,0
	ld (hl),a
lessthancycle:
	pop hl
	ld a,(fbird+4)
	ld (hl),a
	inc hl
	ld a,(fbird+5)
	ld (hl),a
	add hl,de
	dec hl
	ld a,(fbird+6)
	ld (hl),a
	inc hl
	ld a,(fbird+7)
	ld (hl),a
	ret


collisionCheck:	
	push hl
	
	ld a,(hl)
	cp $2e
	jp nz,collision
	inc hl
	ld a,(hl)
	cp $2e
	jp nz,collision
	add hl,de
	dec hl
	ld a,(hl)
	cp $2e
	jp nz,collision
	inc hl
	ld a,(hl)
	cp $2e
	jp nz,collision

	pop hl
	ret
collision:
	ld hl,gameover
	ld (hl),1	
	pop hl
	ret

clearBird:  ;madár bázis koordináta HL-ben (+1, lásd. inc a)
	ld de,64
	ld a,(fbirdytemp)					;madár pozi kiszámítsa
	inc a
	ld b,a
birdycalcclear:
	add hl,de
	djnz birdycalcclear
modifybackground:
	ld a,$2e
	ld (hl),a
	inc hl
	ld (hl),a
	add hl,de
	dec hl
	ld (hl),a
	inc hl
	ld (hl),a
	ret


;##### buffer másolása a képernyőmemóriába
copyBuffer:
	ld hl,BUFFER+4*64				;képernyőmásoló rutin
	ld de,SCREEN+4*64
	ld bc,64*19
	ldir
	ret

clearBuffer:
	ld a,0x2e						;'.'
	ld hl,BUFFER
	ld de,BUFFER+1
	ld bc,2048
	ld (hl),a
	ldir
	ret

clearScreen:
	ld a,0x20
	ld hl,SCREEN
	ld de,SCREEN+1
	ld bc,2048
	ld (hl),a
	ldir
	ret

;##### scroll rutin: képernyő megfelelő részét balra mozgatja + kezeli a csöveket
screenScroll:
	ld hl,BUFFER+4*64+1				;képernyőmásoló rutin
	ld de,BUFFER+4*64
	ld b,19
allrow:
	ld c,b
	ld b,63
onerow:
	ld a,(hl)
	ld (de),a
	inc hl
	inc de
	djnz onerow
	inc hl
	inc de
	ld b,c
	djnz allrow
	ret
	
	
drawLastColumn:					;utolsó oszlop, üres vagy újabb cső
	ld hl, pipecounter
	ld a,(pipecounter)
	cp 0
	jr z,newpipe
	dec (hl)
	call deleteLastColumn
	ret	
newpipe:
	call random18
	ld hl,holestart				;váltózó lyukkezdet egy igazán basic random generátorral
	ld (hl),a				
	ld hl, pipecounter
	ld (hl),12		 
	call drawNewPipe
	call add1point
	ret

random18:
	push hl
	push de
	ld a,(rindex)
	cp 255
	jp nz, norndoverflow
	ld a,0
	ld (rindex),a
norndoverflow:
	ld hl, rindex
	inc (hl)
	ld e,(hl)
	ld d,0
	ld hl,rnumbers
	add hl,de
	ld a,(hl)
	pop de
	pop hl
	ret
	ret
	

;##### pont számláló rutin 3 digitig bőven elég
add1point:
	ld hl,SCREEN+19+1*64
	ld a,(hl)
	cp $39
	jp z,firstdigit9
	inc (hl)
	ret
firstdigit9:
	ld a,$30		;'0'
	ld (hl),a
	dec hl
	ld a,(hl)		;level up páros számoknál (páratlan még inc előtt)
	and %00000001
	cp 1
	jp nz,nolvlup
	call levelUp
nolvlup:
	ld a,(hl)
	cp $39
	jp z,seconddigit9
	inc (hl)
	ret
seconddigit9:
	ld a,$30
	ld (hl),a
	dec hl
	inc (hl)
	ret
	
;##### level up
levelUp:
	push hl
	ld hl,SCREEN+33+1*64
	ld a,(hl)
	cp $39
	jp z,maxlevel				;max 9 szint, ekkor a lyuk mérete 2.
	
	inc (hl)
	
	ld hl,holewidth				;csőben a lyuk méretének csökkentése 1-el
	dec (hl)
maxlevel:
	pop hl
	ret




;##### játék elején változók beállítása
initBeforeGameVariable:
	ld hl, pipecounter
	ld (hl),15
	ld hl,fbirdy
	ld (hl),7
	ld hl,fbirdytemp
	ld (hl),7	
	ld hl,fbirdphase
	ld (hl),0
	ld hl,gameover
	ld (hl),0
	ld hl,firstpress
	ld (hl),0
	ld hl,holewidth
	ld (hl),10
	ld hl,gravitytimer
	ld (hl),0
	ret

;##### cső kirajzolása
drawNewPipe:				;felül 4 sor, alul 2 sor kimarad
	ld hl,BUFFER+63+4*64	;oszlop kezdőpozi
	ld de,64				;soronként 64 karakter
	ld a,(holestart)		;sorok száma
	ld c,a					;c-ben számoljuk ki a cső maradékát
	ld b,a
	ld a,$9c				;oszlopkarakter
drawpipec:
	ld (hl),a
	add hl,de
	djnz drawpipec
	scf
	ccf
	sbc hl,de				;felső csőrész vége 
	ld a,$ff
	ld (hl),a
	add hl,de
	
	

	ld a,(holewidth)		;lyuk kiszámolása
	ld b,a
	add c
	ld c,a
drawhle:
	add hl,de
	djnz drawhle

	ld a,18
	sub c
	ld b,a
	ld a,$ff				;alsó cső felső vége
	ld (hl),a
	add hl,de
	ld a,$9c				;oszlopkarakter
drawpipec2:
	ld (hl),a
	add hl,de
	djnz drawpipec2
	ret

;##### utolsó oszlop törlése
deleteLastColumn:
	ld hl,BUFFER+63+4*64	;oszlop kezdőpozi
	ld de,64				;soronként 64 karakter
	ld b,19
	ld a,0x2e				;'.'
dellastc:
	ld (hl),a
	add hl,de
	djnz dellastc
	ret
	
	
;##### JÁTÉK ELŐTTI INICIALIZÁLÁSOK


scrollWave:							;hullám scrollozása a memóriában (a csorduló effekt miatt - ha lesz rá időm - így jobb)
	ld hl,wave+63
	ld a,(hl)						;mentjük az első karaktert
	
	ld hl,wave+62
	ld de,wave+63
	ld bc,63
	lddr						
	
	ld hl,wave+0
	ld (hl),a
	ret



printWave:							;hullám kirajzolása, DE=hová
	ld hl,wave
	ld bc,64*2
	ldir
	ret
	

initTitlescreen:				
	ld hl,titlescreen				;kezdőképernyő kipakolása
	ld de,SCREEN+19+7*64	
	ld bc,26
	ldir							;első sor

	ld a,0							;többi sor
printtsrows:
	ld bc,38						;ez lehetne egyszerűbb is, majd optimalizálom
	ex de,hl
	add hl,bc
	ex de,hl
	ld bc,26						;oszlopszám
	ldir
	inc a
	cp 17							;sorok száma -1
	jp nz, printtsrows
	
	ret
	
	
;#### játékképernyő előkészítése
initGameScreen:
	ld hl,score				;pontszám és rekord felirat
	ld de,SCREEN+4+64
	ld bc,30
	ldir
	
	
			
	ld hl,SCREEN+2*64		;felső sor megrajzolása
	ld de,SCREEN+3*64
	ld b,64
fillup:
	ld (hl),$12
	ld (de),$fc
	inc hl
	inc de
	djnz fillup

	ld hl,SCREEN+23*64		;alsó sor megrajzolása
	ld de,SCREEN+24*64
	ld b,64
filldown:
	ld (hl),$cf
	ld (de),$1f
	inc hl
	inc de
	djnz filldown
	
	ld hl,promotext			;promo felirat
	ld de,SCREEN+24*64
	ld bc,64*8
	ldir
	
	ret

;#### lassító rutin
slowDown:					 ;egyszerű lassító rutin 2 ciklusban
    ld b,0x42					 ;0 -> 256 ciklus
slower2: 
	ld c,b					 
slower1:
	nop
    djnz slower1
    ld b,c
    djnz slower2
	ret

;#### pacmanhez hasonló soundeffekt game over esetén	
makeGameOverSound:
	;out ($7f),a
	ld a,10
makegosound1:
	push af
	ld h,6	
	ld l,a
	call soundGen
	pop af
	inc a
	inc a
	cp 80
	jp nz, makegosound1
	ld a,50
makegosound2:
	push af
	ld h,5	
	ld l,a
	call soundGen
	pop af
	inc a
	inc a
	cp 120
	jp nz, makegosound2

	ld a,90
makegosound3:
	push af
	ld h,5	
	ld l,a
	call soundGen
	pop af
	inc a
	inc a
	cp 160
	jp nz, makegosound3
	out ($ff),a	
	ret


soundGen:			;Nickmann Laci hanggenerátor rutinja
	push bc
	ld b,l
sc1:
	ld a,($e880)
	djnz sc1
	ld b,l
sc2:
	ld a,($e800)
	djnz sc2
	dec h
	jr nz,sc1
	pop bc
	ret

printGameOverText:				;ez csak teszt, majd rövidítem
	ld hl,gotext	
	ld de,SCREEN+26*64+26
	ld bc,10
	ldir
	
	ld de,SCREEN+27*64+26
	ld bc,10
	ldir

	ld de,SCREEN+28*64+26
	ld bc,10
	ldir	

	ld de,SCREEN+29*64+26
	ld bc,10
	ldir


	ret


;####################################### VÁLTOZÓK
firstpress:			db	0				;kezdődik a játék, megvolt az első space? 
holestart: 			db	3				;a csőben a lyuk kezdete
holewidth: 			db	8				;ez pedig a lyuk vastagsága
pipecounter:		db	7				;ebben számolom a csövek rajzolási gyakoriságát
gravitytimer:		db  0				;a játék sebességéhez képest a madár sebessége

fbirdytemp:			db  0				;madárka korábbi y koordinátája
fbirdy:				db	8				;a madárka y koordinátája (0 a plafonhoz viszonyítva, közv. alatta)
fbirdphase:			db 	0				;0 vagy 1, 2 fázisú animáció
fbird:				db $11,$1e,$2e,$2e	;madár 2 fázisa
					db $11,$1e,$1c,$2e
		
gameover:			db 0				;game over flag					
score:				db $50,$6f,$6e,$74,$73,$7a,$7f,$6d,$3a," 000000     ", $53,$7a,$69,$6e,$74, $3a, " 01"


titlescreen:
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,200,162,27,32,32,32,32
db 32,32,29,255,255,26,255,255,32,32,32,32,32,32,32,29,255,255,26,255,255,32,32,32,32,32
db 32,32,255,27,32,255,27,32,32,32,32,32,32,32,32,255,27,32,255,27,32,32,32,32,32,32
db 32,32,255,0,32,23,18,32,32,32,32,32,32,32,32,255,0,32,23,18,32,32,32,32,32,32
db 32,32,255,0,32,32,31,21,32,32,32,32,32,32,32,255,0,32,32,31,21,32,32,32,32,32
db 32,32,255,30,0,32,29,255,32,32,32,32,32,32,32,255,30,0,32,29,255,32,32,32,32,32
db 32,32,28,255,22,24,255,27,65,80,75,79,68,95,32,28,255,22,24,255,27,95,75,65,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 169,114,116,97,58,32,75,111,108,109,97,32,75,111,114,110,123,108,32,40,75,111,45,75,111,41
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,50,48,50,52,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32
db 114,101,112,116,101,116,123,115,58,32,83,112,97,99,101,32,47,32,116,157,122,103,111,109,98,32

wave:
db 32,16,17,18,19,20,255,255,255,255,20,19,18,17,16,32
db 32,16,17,18,19,20,255,255,255,255,20,19,18,17,16,32
db 32,16,17,18,19,20,255,255,255,255,20,19,18,17,16,32
db 32,16,17,18,19,20,255,255,255,255,20,19,18,17,16,32
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255

;******************* RANDOM NUMBERS
rindex:			db 74			;ez lehet majd a seed (pl. tovább gombnál r értéke ide be)
rnumbers:						;random.org-al generálva
				db 1,6,3,8,8,5,1,1,2,3,7,3,3,7,7,3
				db 1,4,6,6,3,7,5,7,1,4,3,2,1,2,8,6
				db 3,2,7,7,4,6,7,5,5,5,6,1,6,2,1,4
				db 3,1,2,6,6,5,8,8,2,2,3,7,4,5,5,4
				db 6,2,5,6,7,2,1,2,6,1,3,3,1,7,2,5
				db 4,7,7,5,6,6,5,4,5,2,6,2,7,4,6,8
				db 1,2,7,6,5,3,3,4,7,4,8,7,1,7,4,1
				db 5,2,2,6,4,3,6,6,3,5,4,3,1,1,3,1
				db 2,7,8,4,8,4,5,8,1,5,6,2,4,4,5,5
				db 2,4,3,7,7,4,1,1,5,6,8,8,5,5,4,1
				db 2,2,3,3,6,2,4,1,1,1,5,1,8,1,8,3
				db 5,2,5,3,4,4,5,4,8,8,6,4,4,5,8,6
				db 5,7,8,1,8,2,4,4,8,2,8,8,5,4,2,3
				db 8,4,6,6,8,7,8,1,1,4,7,4,4,8,6,7
				db 6,8,7,5,4,6,4,7,4,5,2,7,7,4,2,7
				db 2,7,1,7,3,1,2,7,1,5,8,6,6,5,5,8
				

gotext:
db 32,32,32,28,32,32,32,32,32,32
db 213,0,213,22,31,29,31,27,22,31
db 234,234,0,22,32,234,32,30,22,32
db 32,213,32,21,18,28,18,213,21,18


promotext:
db $20,$8e,$92,$92,$92,$8f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$93,$20,$20,$1e,$93,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $8e,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$8f,$20
db $20,$93,$20,$ff,$20,$93,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $93,$16,$1a,$ea,$1f,$1b,$d5,$ea,$ea,$20,$ea,$1d,$1f,$1e,$93,$20
db $20,$93,$1c,$20,$20,$93,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $93,$16,$1b,$ea,$1b,$20,$19,$1a,$ea,$20,$ea,$ea,$20,$d5,$93,$20
db $20,$93,$20,$8e,$92,$91,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $93,$d5,$20,$ea,$12,$1e,$d5,$ea,$ea,$1d,$ea,$1c,$12,$1b,$93,$20
db $20,$93,$20,$93,$50,$6c,$65,$61,$73,$75,$72,$65,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $90,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$92,$91,$20
db $20,$93,$20,$93,$42,$79,$74,$65,$73,$2e,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$90,$92,$91,$47,$61,$6d,$65,$73,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

vege:
db $19,$74