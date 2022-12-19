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
	EXPORT TIM6_IRQHandler
	EXPORT TIM7_IRQHandler

			
; ------------------------------- importierte Funktionen -----------------------------------


; ------------------------------- symbolische Konstanten ------------------------------------


; ------------------------------ Datensection / Variablen -----------------------------------

	AREA daten, data
array DCB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
counter DCB 0
side DCB 0
number DCB 0
; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s,code
	

; ------------------------------------  TIM6 interupt ---------------------------------------

TIM6_IRQHandler PROC				; 100ms counter
	ldr r1, =TIM6_SR
	mov r3, #0
	str r3, [r1]
	
	; hochzählen
	
	ldr r0, =counter
	ldrb r1, [r0]
	add r1, #1
	str r1, [r0]
	
	bx LR
	
	ENDP
		
; ------------------------------------  TIM7 interupt ---------------------------------------

TIM7_IRQHandler PROC			; 10ms counter
	ldr r1, =TIM7_SR
	mov r3, #0
	str r3, [r1]
	
	
	ldr r0, =side
	ldrb r1, [r0]
	
	cmp r1, #1
	beq Tim_isone
	
	mov r1, #1				; wenn side 1 ist machen wir side zu 0 und gehen zurück
	str r1, [r0]
	bx lr
	
Tim_isone

	mov r1, #0				; wenn side 0 ist machen wir side zu 1 und gehen zurück
	str r1, [r0]
	
	bx lr
	
	ENDP
			
; ---------------------------------------  up_delay -----------------------------------------
up_delay PROC
	PUSH {r0, r1}		
	mov r0, #10				; wieviele ms das delay sein soll
	mov r1, #3600			; wieviele durchläufe 1 ms ist
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
	PUSH {r0, r1, r2, r5, r6}
	
	ldr r6, =number
	ldrb r0, [r6]
	
	ldr r6, =side
	ldrb r1, [r6]
	
	ldr r2, =GPIOA_ODR
	ldr r5, =array
	ldrb r5, [r5, r0]		; wir holen den wert im array mit einem ofset von r0 
	cmp r1, #1				; wenn r1 = 1 dann ändern wir das 8te bit zu 1 damit wir links ausgeben
	
	beq rechts
	
	add r5, #0x80
	
rechts
	str r5, [r2]			; wenn r1 = 0 überspringen wir das addieren
	
	pop {r0, r1, r2, r5, r6}
	
	bx lr
	ENDP
		
; -----------------------------------------  switch ------------------------------------------

switch PROC
	
	ldr r0, =counter		; wir holen den wert aus counter
	ldrb r2, [r0]
	
	ldr r0, =side			; wir holen den wert aus side
	ldrb r1, [r0]
	
	ldr r10, =10
	udiv r0, r2, r10		; wir dividieren r2 durch 10 um die 10er stelle zu bekommen
	cmp r1, #1	
	beq r1is1				; wenn r1 = 1 dann wird es auf der rechten seite ausgegeben
					
	b continue				; ansonsten haben wir die 10er stelle bereits und sind fertig

r1is1
	mul r0, r10				; wir berechnen die einzerstelle da r1 = 1
	sub r0, r2, r0

continue
	
	ldr r3, =number
	str r0, [r3]
	
	bx lr
	
	ENDP
		
; ---------------------------------------  up_display ----------------------------------------


		
; -----------------------------------  Einsprungpunkt - --------------------------------------

main PROC

   ; Initialisierungen
	bl initialize
	
	ldr r3, =10
	ldr r1, =0
	ldr r2, =0
	
	bl stop_loop

startpol
	
	ldr r7, =TIM6_DIER
	mov r8, #1
	str r8, [r7]
	
loop						; wiederholter Anwendungscode
	
	ldr r4, =GPIOC_IDR
	ldr r5, [r4]
	and r6, r5, #0x2
	cmp r6, #0x2			; if px1 pressed -> stop -> gehe zum stop_loop
	bne stop_loop
	
	
	
	bl switch				; aufrufen des switch
	
	bl up_display			; aufrufen des displays
	
	cmp r2, #99				; wir checken ob wir bei 10s sind also wieder bei 00
	beq reset

   B	loop	
  
addition					; wir vergrößern r2, da 100 ms vergangen sind
	ldr r3, =10
	add r2, #1
	bx lr	
	
reset 
	ldr r2, =0
	ldr r3, =counter
	str r2, [r3]
	
	bx lr
	
	
stop_loop

	ldr r7, =TIM6_DIER
	mov r8, #0
	str r8, [r7]
	
	
s_loop	

	ldr r4, =GPIOC_IDR
	ldr r5, [r4]
	and r6, r5, #0x1
	cmp r6, #0x1			; wenn px0 gedrückt wurde gehen wir wieder in den mainloop
	bne startpol
	and r6, r5, #0x4
	

	bl switch				; aufrufen des switch
	bl up_display			; aufrufen des displays
	
	cmp r6, #0x4
	bne s_reset				; wenn px2 gedrückt wurde 
	
	b s_loop
	
s_reset						; wir reseten bei reset button press
	ldr r2, =0
	ldr r3, =counter
	str r2, [r3]
	
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
	
	ldr r0, =counter			; wir initialisieren counter und side
	mov r1, #0
	ldr r1, [r0]
	
	ldr r0, =side
	mov r1, #0
	ldr r1, [r0]
	
	ldr r0, =number
	mov r1, #0
	ldr r1, [r0]
	
							; wir aktivieren timer 6 und 7		6 == 100ms; 7 == 10ms 
	ldr r0, =RCC_APB1ENR1
	ldr r1, =0x30
	str r1, [r0]
	
	ldr r0, =TIM6_PSC
	mov r1, #15999		; wir machen das hier 1000hz laufen
	str r1, [r0]
	
	ldr r0, =TIM6_ARR
	mov r1, #99			; es soll alle 100 ms auslösen also 10hz -> bei 99 stoppen da wir bei 0 anfangen
	str r1, [r0]
	
	ldr r0, =TIM7_PSC
	mov r1, #15999		; wir machen das hier 1000hz laufen  
	str r1, [r0]
	
	ldr r0, =TIM7_ARR
	mov r1, #9			; es soll alle 5 ms auslösen also 10hz -> bei 9 stoppen da wir bei 0 anfangen
	str r1, [r0]
	
	ldr r0, =TIM7_CR1
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =TIM6_CR1
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =NVIC_ICPR1
	mov r1, #(1<<22)
	str r1, [r0]
	
	ldr r0, =NVIC_ICPR1
	mov r1, #(1<<23)
	str r1, [r0]
	
	ldr r0, =NVIC_ISER1
	mov r1, #(1<<22)
	str r1, [r0]
	
	ldr r0, =NVIC_ISER1
	mov r1, #(1<<23)
	str r1, [r0]
	
	ldr r0, =TIM6_DIER
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =TIM7_DIER
	mov r1, #1
	str r1, [r0]
	
	; finished timer init
	

	
							

	bx lr
	
	ENDP

   END
		
