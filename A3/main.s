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
	EXPORT	USART3_IRQHandler

			
; ------------------------------- importierte Funktionen -----------------------------------


; ------------------------------- symbolische Konstanten ------------------------------------


; ------------------------------ Datensection / Variablen -----------------------------------


; ------------------------------- Codesection / Programm ------------------------------------
	AREA 	daten,data

received DCB 0

	AREA	main_s,code
	
; USSART3 interupt

USART3_IRQHandler PROC
	
	ldr r0, =USART3_ISR		; wir holen den wert im USART3_ISR
	ldr r1, [r0]
	
	and r2, r1, #0x20
	cmp r2, #0x20			; wenn das RXNE bit an ist springen wir zu rxne
	beq rxne
	
	and r1, r1, #0x8		; wenn das ore bit an ist springen wir zu rxne
	cmp r2, #0x8
	beq ore
	
	bx lr
	
rxne
	ldr r0, =USART3_RDR		; wir holen den wert aus USART3_RDR
	ldrb r1, [r0]
	and r1, r1, #0x7F
	ldr r0, =received		;wir speichern den wert den wir aus USART3_RDR haben in received
	strb r1, [r0]
	
	PUSH {lr}				; wir pushen lr damit wir sp�ter aus den interupt rauskommen
	
	bl sendtoPC				; danach gehen wir in das sendtoPC unterprogramm
	
	POP {lr}
	
	bx lr

ore

	bx lr
	


			
; -----------------------------------  Einsprungpunkt - --------------------------------------

sendtoPC PROC
	
	ldr r0, =received
	ldrb r1, [r0] 				; wir laden die daten aus received
	
	ldr r0, =USART1_TDR
	strb r1, [r0]				; wir speichern den inhalt von unserer variable 'received' in TDR
	
	bx lr
	
	ENDP

main PROC

   ; Initialisierungen
   bl init
	
loop	
	; da wir interupts haben brauchen wir nix hier

   B	loop	
  
   ENDP 

init PROC
	
	ldr r0, =RCC_AHB2ENR
	ldr r1, =5
	str r1, [r0]			; wir speichern r1 in das register damit die clock f�r port-A und port-C aktiviert wird.
	
	; USART 1 aktivieren 
	
	ldr r0, =RCC_APB2ENR
	ldr r1, =0x4000
	str r1, [r0]
	; USART 3 aktivieren
	ldr r0, =RCC_APB1ENR1
	ldr r1, =0x40000
	str r1, [r0]
	
	; GPIOA
	ldr r0, =GPIOA_MODER
	ldr r1, =0xABEBFFFF
	str r1, [r0]			
	
	; GPIOC
	ldr r0, =GPIOC_MODER
	ldr r1, =0xFFAFFFFF
	str r1, [r0]
	
	; USART 3 aktivieren		USART3 = Tastatur
	
	ldr r0, =USART3_CR1
	ldr r1, =0x42D
	str r1, [r0]
	
	ldr r0, =USART3_CR2
	ldr r1, =0x0
	str r1, [r0]
	
	ldr r0, =USART3_BRR
	ldr r1, =0x3415				; Baudrate 1200
	str r1, [r0]
	
	; USART 1 aktivieren		USART1 = zu PC
	
	ldr r0, =USART1_CR1
	ldr r1, =0x160D
	str r1, [r0]
	
	ldr r0, =USART1_CR2
	ldr r1, =0x2000
	str r1, [r0]
	
	ldr r0, =USART1_BRR
	ldr r1, =0x682				;baudrate = 9600
	str r1, [r0]
	
	
	ldr r0, =GPIOA_AFRH
	ldr r1, =0x770
	str r1, [r0]
	
	ldr r0, =GPIOC_AFRH
	ldr r1, =0x7700
	str r1, [r0]
	
	; interupt f�r USART 3
	
	ldr r0, =NVIC_ISER1
	ldr r1, =0x80
	str r1, [r0]
	
	bx lr
	
	
	ENDP

   END
		
