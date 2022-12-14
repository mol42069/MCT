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

	AREA daten, data
array DCB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s,code
	


			
; ---------------------------------------  up_delay -----------------------------------------
up_delay PROC
	PUSH {r0, r1}		
	mov r0, #5				; wieviele ms das delay sein soll
	mov r1, #4000			; wieviele durchläufe 1 ms ist
	mul r0, r0, r1			; wir rechnen die summe von durchläufen aus die wir machen müssen
		
loop_delay

	sub r0, r0, #1
	cmp r0, #0
	bne loop_delay			; wir laufen durch den loop bis r0 = 0
	
	pop {r0, r1}
	bx lr
	
	ENDP

; ---------------------------------------  up_display ----------------------------------------

up_display PROC
	; r0 = zahl
	; r1 = welches display
	PUSH {r0, r1, r2}
	
	ldr r2, =GPIOA_ODR
	ldr r5, =array
	ldrb r5, [r5, r0]		; wir holen den wert im array mit einem ofset von r0 
	cmp r1, #0				; wenn r1 = 1 dann ändern wir das 8te bit zu 1 damit wir links ausgeben
	
	beq rechts
	
	add r5, #0x80
	
rechts
	str r5, [r2]			; wenn r1 = 0 überspringen wir das addieren
	
	pop {r0, r1, r2}
	
	bx lr
	ENDP
		
; -----------------------------------------  switch ------------------------------------------

switch PROC
	
	ldr r10, =10
	udiv r0, r2, r10		; wir dividieren r2 durch 10 um die 10er stelle zu bekommen
	cmp r1, #1	
	beq r1is1				; wenn r1 = 1 dann wird es auf der rechten seite ausgegeben
	
	add r1, #1				
	b continue				; ansonsten haben wir die 10er stelle bereits und sind fertig

r1is1
	mul r0, r10				; wir berechnen die einzerstelle da r1 = 1
	sub r0, r2, r0
	ldr r1, =0

continue
	
	bx lr
	
	ENDP
		
; ---------------------------------------  up_display ----------------------------------------

stop_loop PROC


s_loop	

	ldr r4, =GPIOC_IDR
	ldr r5, [r4]
	and r6, r5, #0x1
	cmp r6, #0x1			; wenn px0 gedrückt wurde gehen wir wieder in den mainloop
	bne loop
	and r6, r5, #0x3
	cmp r6, #0x3
	bne s_reset				; wenn px2 gedrückt wurde 

	bl switch				; aufrufen des switch
	
	bl up_display			; aufrufen des displays
	
	bl up_delay				; aufrufen des delays
	
	b s_loop
	
s_reset						; wir reseten bei reset button press

	ldr r3, =20
	ldr r2, =0
	
	b s_loop
	
	ENDP
		
; ---------------------------------------  initialize ----------------------------------------

initialize PROC
	
	ldr r0, =RCC_AHB2ENR
	ldr r1, =5
	str r1, [r0]			; wir speichern r1 in das register damit die clock für port-A aktiviert wird.	
	
	ldr r0, =GPIOA_MODER
	ldr r1, [r0]
	ldr r2, =0xABFF0000
	and r1, r2
	ldr r2, =0xABFF5555
	orr r1, r2
	str r1, [r0]			; wir setzten bei GPIOA_MODER die ersten 8 Pins auf ouput-mode
	
	ldr R0, =GPIOC_MODER
	ldr R1, [R0]
	ldr	R2, =0xFFFFFFC0		; Maskierung aller Pins außer dem ersten für die Tasten Px0, Px1 und Px2
	and R1, R1, r2
	ldr R2, =0xFFFFFFC0		; 1100 = C für den Inputmode in MODE0 0000 = 0 für Inputmode MODE0 & MODE1
	orr R1, R2
	str R1, [R0]
	
	ldr r0, =array			; wir initialisieren das array für die zahlen:
	ldr r1, =0x4F5B063F
	str r1, [r0, #0]
	ldr r1, =0x077D6D66
	str r1, [r0, #4]
	ldr r1, =0x6F7F
	str r1, [r0, #8]
	
	
	bx lr
	
	ENDP
		
; -----------------------------------  Einsprungpunkt - --------------------------------------

main PROC

   ; Initialisierungen
	bl initialize
	
	ldr r3, =20
	ldr r1, =0
	ldr r2, =0
	
	bl stop_loop
	
loop						; wiederholter Anwendungscode
	
	ldr r4, =GPIOC_IDR
	ldr r5, [r4]
	and r6, r5, #0x2
	cmp r6, #0x2			; if px1 pressed -> stop -> gehe zum stop_loop
	bne stop_loop
	
	sub r3, #1				; wir checken ob die zahl größer werden soll
	cmp r3, #0
	beq addition
	
	bl switch				; aufrufen des switch
	
	bl up_display			; aufrufen des displays
	
	bl up_delay				; aufrufen des delays
	
	cmp r2, #99			; wir checken ob wir bei 10s sind also wieder bei 00
	beq stop_loop

   B	loop	
  
addition					; wir vergrößern r2, da 100 ms vergangen sind
	ldr r3, =20
	add r2, #1
	bx lr	
  
   ENDP

   END
		
