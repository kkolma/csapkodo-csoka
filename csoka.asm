; 	Csapkodó Csóka
;
;	Egyszerű Flappy Bird klón HomeLab 2 gépre
;
;	Írta: Kolma Kornél (Ko-Ko), 2023. 
;	
;   https://pleasurebytes.games
;
;   https://pexy.io
;
;	e-mail: kolma.kornel@gmail.com




org 0x4800

SCREEN:		EQU	0xc001
BUFFER:		EQU	0x6000

inittitle:
	call clearScreen
	call initTitlescreen
	call waitNoEnter
	
	ld hl,modifybackground+1	;madár háttér a title-nél space
	ld (hl), $20
	
	ld hl,fbirdytemp
	ld (hl),0
	
	ld hl,b1x					;title madár pozijának resetelése
	inc hl
	ld a,27
	ld (hl),a
	ld hl,b2x
	inc hl
	ld a,28
	ld (hl),a	
	
	
	
titleloop:
	ld de,SCREEN+22*40
	call printWave
	call slowDown
	call scrollWave
	ld hl,$3afd
	ld a,(hl)
	cp $df
	jp nz,titleloop
	
	

	
	ld de,SCREEN+22*40		;második fázis, áradás I. fejezet !!!
	ld b,13
	call cunamiWave
	
	ld b,20
justwave:					;egy kis hullámzás, ami elriasztja a csókát
	push b
	ld de,SCREEN+10*40
	call printWave
	call slowDown
	call scrollWave
	pop b
	djnz justwave

	
	ld hl,SCREEN+26+5*40
	ld (hl),$20				;statikmadár farkincáját töröljük

	
	
	ld hl,fbirdy			;madár animáció + hullámzás
	ld (hl),3
	ld b,80
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
	ld de,SCREEN+10*40
	call printWave
	call slowDown
	call scrollWave
	pop af
	pop b	
	djnz flyaway


	ld de,SCREEN+10*40				;utolsó fázis, áradás II. !!!
	ld b,12
	call cunamiWave

	call clearScreen
		
	ld hl,modifybackground+1		;madár háttér visszaállítása "."-ra
	ld (hl), $2e
	
	ld a,r							;rnd seedelése
	ld (rindex),a
	
	call clearBuffer
	call initBeforeGameVariable
	call initGameScreen
	
gameloop:
	ld hl,BUFFER+12+3*40			
	call clearBird					;madárka törlése a bufferből
	call screenScroll				;buffer scrollozása
	ld hl,BUFFER+12+3*40
	call printBird					;madárka kirajzolása + gameover check
	call drawLastColumn				;utolsó oszlop (üres v. cső) megrajzolása bufferbe
	
	ld 	hl,firstpress				;addig nincs gravitáció, míg meg nem nyomta
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
	call waitEnter
	ld de,SCREEN+23*40		;második fázis, áradás I. fejezet !!!
	ld b,25
	call cunamiWave
	jp inittitle


notgameover:	
	call keyCheck
	jp gameloop
	

;########################### JÁTÉK RUTINOK
;#### billentyű rutinok

keyCheck:
	ld hl,$3afd	
	ld a,(hl)
	cp $fe
	jp z,spacepressed
	ret
spacepressed:
	ld hl,firstpress
	ld (hl),1
	ld hl,fbirdy
	dec (hl)
	;dec (hl)
	ret

waitEnter:
	ld hl,$3afd	
	ld a,(hl)
	cp $df
	jp nz,waitEnter
	ret

waitNoEnter:
	ld hl,$3afd	
	ld a,(hl)
	cp $df
	jp z,waitNoEnter
	ret

;#### title-nél a hullám emelkedő rutinja
cunamiWave:	
cunamiloop:
	push b
	push de
	call printWave
	ld b,3
moreslow:							;még több lassítás, hogy szép legyen a víz effekt
	push b
	;call slowDown
	call scrollWave
	ld h,3					;hosszúság -> max 10s
	ld l,205				;hangmagasság -> 250Hz - 2kHz
	call 0x1d84
	pop b
	djnz moreslow
	call scrollWave
	pop de
	ld hl,de
	scf
	ccf
	ld bc,40
	sbc hl,bc
	ld de,hl
	pop b
	djnz cunamiloop
	ret

;##### print Csapkodó Csóka
printBird:			;HL-ben madár bázis koordináta (+1, lásd. inc a)
	ld de,40
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
	ld de,40
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
	ld hl,BUFFER+4*40				;képernyőmásoló rutin
	ld de,SCREEN+4*40
	ld bc,40*19
	ldir
	ret

clearBuffer:
	ld a,0x2e						;'.'
	ld hl,BUFFER
	ld de,BUFFER+1
	ld bc,1000
	ld (hl),a
	ldir
	ret

clearScreen:
	ld a,0x20
	ld hl,SCREEN
	ld de,SCREEN+1
	ld bc,1000
	ld (hl),a
	ldir
	ret

;##### scroll rutin: képernyő megfelelő részét balra mozgatja + kezeli a csöveket
screenScroll:
	ld hl,BUFFER+4*40+1				;képernyőmásoló rutin
	ld de,BUFFER+4*40
	ld b,19
allrow:
	ld c,b
	ld b,39
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
	ld hl,SCREEN+19
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
	ld hl,SCREEN+33
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
	ld hl,BUFFER+39+4*40	;oszlop kezdőpozi
	ld de,40				;soronként 40 karakter
	ld a,(holestart)		;sorok száma
	ld c,a					;c-ben számoljuk ki a cső maradékát
	ld b,a
	ld a,$8e				;oszlopkarakter
drawpipec:
	ld (hl),a
	add hl,de
	djnz drawpipec
	scf
	ccf
	sbc hl,de				;felső csőrész vége 
	ld a,$a0
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
	ld a,$a0				;alsó cső felső vége
	ld (hl),a
	add hl,de
	ld a,$8e				;oszlopkarakter
drawpipec2:
	ld (hl),a
	add hl,de
	djnz drawpipec2
	ret

;##### utolsó oszlop törlése
deleteLastColumn:
	ld hl,BUFFER+39+4*40	;oszlop kezdőpozi
	ld de,40				;soronként 40 karakter
	ld b,19
	ld a,0x2e				;'.'
dellastc:
	ld (hl),a
	add hl,de
	djnz dellastc
	ret
	
	
;##### JÁTÉK ELŐTTI INICIALIZÁLÁSOK


scrollWave:							;hullám scrollozása a memóriában (a csorduló effekt miatt - ha lesz rá időm - így jobb)
	ld hl,wave+39
	ld a,(hl)						;mentjük az első karaktert
	
	ld hl,wave+38
	ld de,wave+39
	ld bc,39
	lddr						
	
	ld hl,wave+0
	ld (hl),a
	ret



printWave:							;hullám kirajzolása, DE=hová
	ld hl,wave
	ld bc,40*2
	ldir
	ret
	

initTitlescreen:				
	ld hl,titlescreen				;kezdőképernyő kipakolása
	ld de,SCREEN+8+5*40	
	ld bc,26
	ldir							;első sor

	ld a,0							;többi sor
printtsrows:
	ld bc,14						;ez lehetne egyszerűbb is, majd optimalizálom
	ex de,hl
	add hl,bc
	ex de,hl
	ld bc,26	
	ldir
	inc a
	cp 12
	jp nz, printtsrows
	
	ret
	
	
;#### játékképernyő előkészítése
initGameScreen:
	ld hl,score				;pontszám és rekord felirat
	ld de,SCREEN+4
	ld bc,30
	ldir
	
	
			
	ld hl,SCREEN+2*40		;felső sor megrajzolása
	ld de,SCREEN+3*40
	ld b,40
fillup:
	ld (hl),$98
	ld (de),$a0
	inc hl
	inc de
	djnz fillup

	ld hl,SCREEN+23*40		;alsó sor megrajzolása
	ld de,SCREEN+24*40
	ld b,40
filldown:
	ld (hl),$a0
	ld (de),$93
	inc hl
	inc de
	djnz filldown

	ld hl,pbvonas			;pleasurebytes.games felulvonas
	ld de,SCREEN+1*40+11
	ld bc,19
	ldir

	ld hl,pbtext			;pleasurebytes.games felirat
	ld de,SCREEN+2*40+11
	ld bc,19
	ldir
	
	ld hl,pexytext			;pexy.io felirat
	ld de,SCREEN+23*40+30
	ld bc,7
	ldir
	
	ret

;#### lassító rutin
slowDown:					 ;egyszerű lassító rutin 2 ciklusban
    ld b,0x35					 ;0 -> 256 ciklus
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
	ld a,10
makegosound1:
	push af
	ld h,6	
	ld l,a
	call 0x1d84
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
	call 0x1d84
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
	call 0x1d84
	pop af
	inc a
	inc a
	cp 160
	jp nz, makegosound3
	ret


printGameOverText:
	ld hl,gotext	
	ld de,SCREEN+11*40+14
	ld bc,12
	ldir
	
	ld de,SCREEN+12*40+14
	ld bc,12
	ldir

	ld de,SCREEN+13*40+14
	ld bc,12
	ldir	

	ld de,SCREEN+14*40+14
	ld bc,12
	ldir

	ld de,SCREEN+15*40+14
	ld bc,12
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
fbird:				db $2e,$f2,$92,$92	;madár 2 fázisa
					db $2e,$f2,$7b,$7d
		
gameover:			db 0				;game over flag		
					
score:				db $d0,$cf,$ce,$d4,$d3,$da,$c1,$cd,$ba," 000000     ", $d3,$da,$c9,$ce,$d4,$ba, " 01"


titlescreen:
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$91,$1d,$ef,$20,$20,$20,$20,$20
db $20,$20,$20,$7c,$7d,$7c,$7d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$7c,$7d,$7c,$7d,$20,$20,$20,$20,$20,$20
db $20,$20,$7c,$7d,$20,$7b,$20,$20,$20,$20,$20,$20,$20,$20,$20,$7c,$7d,$20,$7b,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$7b,$7a,$20,$20,$7a,$20,$20,$20,$20,$20,$2c,$20,$20,$7b,$7a,$20,$20,$7a,$2c,$20,$20,$20,$20,$20
db $20,$20,$20,$7b,$7a,$7c,$7d,$41,$50,$4b,$4f,$44,$4f,$20,$20,$20,$7b,$7a,$7c,$7d,$4f,$4b,$41,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $2c,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$2c,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $49,$52,$54,$41,58,$20,$4b,$4f,$4c,$4d,$41,$20,$4b,$4f,$52,$4e,$45,$4c,$20,$28,$4b,$4f,$2d,$4b,$4f,$29
db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$20,$20,$2c,$20,$20,$2c,$20,$2c,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$49,$52,$41,$4e,$59,$49,$54,$41,$53,58,$20,$d3,$d0,$c1,$c3,$c5,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$20,$2c,$20,$2c,$20,$20,$20,$20,$20,$2c,$20,$2c,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
db $20,$20,$20,$4a,$41,$54,$45,$4b,$20,$49,$4e,$44,$49,$54,$41,$53,$41,58,$20,$c3,$d2,$20,$20,$20,$20,$20

wave:
db $20,$99,$9a,$9b,$9c,$9d,$9e,$9f,$9f,$a0,$a0,$a0,$9f,$9f,$9e,$9d,$9c,$9b,$9a,$99
db $20,$99,$9a,$9b,$9c,$9d,$9e,$9f,$9f,$a0,$a0,$a0,$9f,$9f,$9e,$9d,$9c,$9b,$9a,$99
db $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
db $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0

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
db 127,146,146,146,146,146,146,146,146,146,146,128
db 231, 74, 65, 84, 69, 75, 32, 86, 69, 71, 69,238
db 231, 32, 32, 32, 32, 32, 32, 32, 32,153,153,238
db 231, 84, 79, 86, 65, 66, 66, 58,238,195,210,238
db 126,153,153,153,153,153,153,153,153,153,153,129

pbvonas:
db $9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a
pbtext:
db $d0,$cc,$c5,$c1,$d3,$d5,$d2,$c5,$c2,$d9,$d4,$c5,$d3,$ae,$c7,$c1,$cd,$c5,$d3
pexytext:
db $d0,$c5,$d8,$d9,$ae,$c9,$cf
vege:
db $19,$74