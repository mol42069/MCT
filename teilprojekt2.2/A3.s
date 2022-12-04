; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   Peter Raab                               | Datum:  03.09.2021           |
; |--------------------------------------------------------------------------------------|
; | Version:     V1.0            | Projekt:               | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:     Basisprojekt                                                            |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     03.09.2021     Peter Raab        Initial version                                 |
; |                                                                                      |
; ========================================================================================

; ------------------------------- includierte Dateien ------------------------------------
    INCLUDE STM32G4xx_REG_ASM.inc
; ------------------------------- exportierte Variablen ------------------------------------


; ------------------------------- importierte Variablen ------------------------------------		
		

; ------------------------------- exportierte Funktionen -----------------------------------		
	EXPORT  main

			
; ------------------------------- importierte Funktionen -----------------------------------


; ------------------------------- symbolische Konstanten ------------------------------------


; ------------------------------ Datensection / Variablen -----------------------------------

	AREA 	daten, data
		
array DCB 63, 6, 91, 79, 102, 109, 125, 7, 127, 111


; ------------------------------- Codesection / Programm ------------------------------------

; ---------------------------------- up_delay / DELAY ---------------------------------------
	
	AREA up_delay, code
	
	ldr r4, =0xFA0	; FA0 ist eine ms 
	mul r3, r2, r4	; wir multiplizieren FA0 mit r2 aka. wieviele ms delay wir haben wollen
	
delay	
	sub r3, #1		; hier ziehen wir immer eins ab für jeden loop bis r3 = 0 ist und dann ist das delay vorbei.
	cmp r3, #0
	beq loop		; muss dahin wo das delay sein soll
	b delay
	
; -------------------------------- up_display / AUSGABE -------------------------------------

	AREA up_display, code
		; r0 = zahl
		; r1 = welches display
		ldr r6, =GPIOA_ODR
		ldr r4, =array
		ldrb r5, [r4, r0]	; wir holen den wert im array mit einem ofset von r0 
		cmp r1, #0			; wenn r1 = 1 dann ändern wir das 8te bit zu 1 damit wir links ausgeben
		beq rechts
		add r5, #0x80
rechts
		str r5, [r6]		; wenn r1 = 0 überspringen wir das addieren
		
		b backfromdisp

	AREA	main_s, code
	
	


			
; -----------------------------------  Einsprungpunkt - --------------------------------------

main PROC

   ; Initialisierungen
	ldr r0, =RCC_AHB2ENR
	ldr r1, =5
	str r1, [r0]			; wir speichern r1 in das register damit die clock für port-A und C aktiviert wird.	
	
	
	ldr r0, =GPIOA_MODER
	ldr r1, [r0]
	ldr r2, =0xABFF0000
	and r1, r2
	ldr r2, =0xABFF5555
	orr r1, r2
	str r1, [r0]			; wir setzten bei GPIOA_MODER die ersten 8 Pins auf ouput-mode
	
	ldr r0, =GPIOC_MODER
	ldr r2, =0xFFFFFFF0
	str r2, [r0]
	
	ldr r0, =array
	ldr r1, =0x4F5B063F
	str r1, [r0, #0]
	ldr r1, =0x077D6D66
	str r1, [r0, #4]
	ldr r1, =0x6F7F
	str r1, [r0, #8]
	
	
loop

	ldr r0, =GPIOC_IDR
	ldr r3, [r0]
	cmp r3, #0x1
	bne start
	cmp r3, #0x2
	bne stoppressed
	cmp r11, #2
	beq backfadd

start

	ldr r0, =0				; wir initialisieren r0, r1 und r2 für den rest des programmes
	ldr r1, =0
	ldr r2, =0xA			; r2 für wieviele ms das delay seien soll
	ldr r7, =0				; der time-counter zählt die insgesammt vergangene zeit.
	ldr r10, =10
	ldr r8, =11
	ldr r11, =0
	
	sub r8, #1
	
	cmp r8, #0
	beq addition
stoppressed
	ldr r11, =2

backfadd
	
	b up_display
	
backfromdisp
	
; wir switchen bei jedem loop r1 von 1 zu 0 und andersherum

	udiv r0, r7, r10
	cmp r1, #1
	beq r1is1
	
	add r1, #1
	b continue

r1is1
	mul r0, r10
	sub r0, r7, r0
	ldr r1, =0

continue

	b up_delay
	
	
	
addition
	add r7, #1
	ldr r8, =11
	cmp r7, #100
	beq reset
	b backfadd
	
reset
	ldr r7, =0
	ldr r0, =0
	ldr r1, =0
	b loop
	
	
	ENDP				


   END
		
