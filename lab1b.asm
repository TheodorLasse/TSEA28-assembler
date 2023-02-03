;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Mall för lab1 i TSEA28 Datorteknik Y
;;
;; 210105 KPa: Modified for distance version
;;

	;; Ange att koden är för thumb mode
	.thumb
	.text
	.align 2

	;; Ange att labbkoden startar här efter initiering
	.global	main
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Ange vem som skrivit koden
;;               student LiU-ID: thela038
;; + ev samarbetspartner LiU-ID: filjo653
;;
;; Placera programmet här

main:				; Start av programmet

	bl  inituart
	bl  initGPIOF
	bl  initGPIOE
	bl initblink

	bl createcode
activate:
	bl activatealarm
clear:
	bl clearinput
key:
	bl getkey
	cmp r4, #0xF
	beq enteredcode
	cmp r4, #9
	bgt clear
	bl addkey
	b key

enteredcode:
	bl checkcode
	cmp r4, #0
	bne correctcode
	adr r4, str_fel
	mov r5, #13
	bl printstring
	b clear

correctcode:
	bl deactivatealarm
waitloop:
	bl getkey
	cmp r4, #0xA
	bne waitloop
	b activate

end:
	nop
	b end

str_fel:
	.align 4
	.string "Felaktig kod!",10,13

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Pekare till strängen i r4
; Längd på strängen i r5
; Utargument: Inga
;
; Funktion: Skriver ut strängen mha subrutinen printchar
printstring:
; Förberedelseuppgift: Skriv denna subrutin!
	push {lr}
	mov r3,#0x0
printloop: ;Loopar igenom alla karaktärer i strängen
	ldrb r0,[r4] ;laddar en karaktär från strängen i r0
	bl printchar
	add r4, r4, #1
	add r3, r3, #1
	cmp r3, r5
	bne printloop
	mov r0, #0x0d
	bl printchar
	mov r0, #0x0a
	bl printchar
	pop{lr}
	bx lr


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Funktion: Tänder grön lysdiod (bit 3 = 1, bit 2 = 0, bit 1 = 0)
deactivatealarm:
; FÖrberedelseuppgift: Skriv denna subrutin!
	mov r8, #0
	mov r0,#0x08
	mov r1,#(GPIOF_GPIODATA & 0xffff) ;hämtar ena delen av adressen
	movt r1,#(GPIOF_GPIODATA >> 16) ;hämtar andra delen av adressen
	strb r0,[r1] ;skriver till io enheten
	bx lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Förstör r0, r1
; Funktion: Tänder röd lysdiod (bit 3 = 0, bit 2 = 0, bit 1 = 1)
activatealarm:
; Förberedelseuppgift: Skriv denna subrutin!
	mov r8, #1
	mov r0,#0x02
	mov r1,#(GPIOF_GPIODATA & 0xffff) ;hämtar ena delen av adressen
	movt r1,#(GPIOF_GPIODATA >> 16) ;hämtar andra delen av adressen
	strb r0,[r1] ;skriver till io enheten
	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Tryckt knappt returneras i r4
getkey:
; Förberedelseuppgift: Skriv denna subrutin!
	push {lr}
	bl blink
	pop {lr}

	mov r1,#(GPIOE_GPIODATA & 0xffff)
	movt r1,#(GPIOE_GPIODATA >> 16)
	ldrb r4, [r1] ;läs från io enheten och lagra i r4
	ands r5, r4, #0x10
	beq getkey ;om stroben inte är hög
getkeyloop: ;vänta på att stroben blir låg
	push {lr}
	bl blink
	pop {lr}

	ldrb r4, [r1]
	ands r5, r4, #0x10
	bne getkeyloop ;vänta på att den blir låg

	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: r7 sparas cykel nummer
; Utargument:
; förstör r2, r0
blink:
	mov r2,#(GPIOF_GPIODATA & 0xffff) ;hämtar ena delen av adressen
	movt r2,#(GPIOF_GPIODATA >> 16) ;hämtar andra delen av adressen
	cmp r8, #0
	bne updateblink
	bx lr

lightsoff:
	mov r0,#0x0
	strb r0,[r2] ;skriver till io enheten
	bx lr
lightson:
	mov r0,#0x03
	strb r0,[r2] ;skriver till io enheten
	mov r7, #0
	bx lr
updateblink:
	add r7, r7, #1
	cmp r7, r9
	beq lightsoff
	cmp r7, r10
	beq lightson
	bx lr
initblink:
	mov r9,#(750000 & 0xffff) ;hämtar ena delen av adressen
	movt r9,#(750000 >> 16) ;hämtar andra delen av adressen
	mov r10,#(1500000 & 0xffff) ;hämtar ena delen av adressen
	movt r10,#(1500000 >> 16) ;hämtar andra delen av adressen
	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Vald tangent i r4
; Utargument: Inga
;
; Funktion: Flyttar innehållet på 0x20001000-0x20001002 framåt en byte
; till 0x20001001-0x20001003. Lagrar sedan innehållet i r4 på
; adress 0x20001000.
addkey:
; Förberedelseuppgift: Skriv denna subrutin!
	mov r3,#(0x20001003 & 0xffff) ;läser in alla adresser till minnet
	movt r3,#(0x20001003 >> 16)
	mov r2,#(0x20001002 & 0xffff)
	movt r2,#(0x20001002 >> 16)
	mov r1,#(0x20001001 & 0xffff)
	movt r1,#(0x20001001 >> 16)
	mov r0,#(0x20001000 & 0xffff)
	movt r0,#(0x20001000 >> 16)

	ldrb r5, [r2] ;skyfflar runt värdena på koden
	strb r5, [r3]
	ldrb r5, [r1]
	strb r5, [r2]
	ldrb r5, [r0]
	strb r5, [r1]
	strb r4, [r0] ;sätter värdet till nya knapptrycket

	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Inga
;
; Funktion: S¨?atter inneh??allet p??a 0x20001000-0x20001003 till 0xFF
clearinput:
; F¨?orberedelseuppgift: Skriv denna subrutin!
	mov r3,#(0x20001003 & 0xffff)
	movt r3,#(0x20001003 >> 16)
	mov r2,#(0x20001002 & 0xffff)
	movt r2,#(0x20001002 >> 16)
	mov r1,#(0x20001001 & 0xffff)
	movt r1,#(0x20001001 >> 16)
	mov r0,#(0x20001000 & 0xffff)
	movt r0,#(0x20001000 >> 16)

	mov r5, #0xFF ;skriver 0xFF till adresserna
	strb r5, [r3]
	strb r5, [r2]
	strb r5, [r1]
	strb r5, [r0]
	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Returnerar 1 i r4 om koden var korrekt, annars 0 i r4
checkcode:
; F¨?orberedelseuppgift: Skriv denna subrutin!
	mov r0,#(0x20001010 & 0xffff)
	movt r0,#(0x20001010 >> 16)
	ldr r2, [r0] ;laddar korrekt kod

	mov r1,#(0x20001000 & 0xffff)
	movt r1,#(0x20001000 >> 16)
	ldr r3, [r1] ;laddar inskriven kod
	cmp r2, r3
	bne wrongcode ;om koderna inte är samma är det fel kod

	mov r4, #1
	bx lr

wrongcode:
	mov r4, #0
	bx lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inargument: Inga
; Utargument: Returnerar koden till addresserna 0x20001010-0x20001013
createcode: ;skapar en kod på rätt adresser
	mov r3,#(0x20001013 & 0xffff)
	movt r3,#(0x20001013 >> 16)
	mov r2,#(0x20001012 & 0xffff)
	movt r2,#(0x20001012 >> 16)
	mov r1,#(0x20001011 & 0xffff)
	movt r1,#(0x20001011 >> 16)
	mov r0,#(0x20001010 & 0xffff)
	movt r0,#(0x20001010 >> 16)

	mov r5, #1
	strb r5, [r3]
	mov r5, #2
	strb r5, [r2]
	mov r5, #3
	strb r5, [r1]
	mov r5, #4
	strb r5, [r0]
	bx lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,
;;;
;;; Allt här efter ska inte ändras
;;;
;;; Rutiner för initiering
;;; Se labmanual för vilka namn som ska användas
;;;
	
	.align 4

;; 	Initiering av seriekommunikation
;;	Förstör r0, r1 
	
inituart:
	mov r1,#(RCGCUART & 0xffff)		; Koppla in serieport
	movt r1,#(RCGCUART >> 16)
	mov r0,#0x01
	str r0,[r1]

	mov r1,#(RCGCGPIO & 0xffff)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x01
	str r0,[r1]		; Koppla in GPIO port A

	nop			; vänta lite
	nop
	nop

	mov r1,#(GPIOA_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOA_GPIOAFSEL >> 16)
	mov r0,#0x03
	str r0,[r1]		; pinnar PA0 och PA1 som serieport

	mov r1,#(GPIOA_GPIODEN & 0xffff)
	movt r1,#(GPIOA_GPIODEN >> 16)
	mov r0,#0x03
	str r0,[r1]		; Digital I/O på PA0 och PA1

	mov r1,#(UART0_UARTIBRD & 0xffff)
	movt r1,#(UART0_UARTIBRD >> 16)
	mov r0,#0x08
	str r0,[r1]		; Sätt hastighet till 115200 baud
	mov r1,#(UART0_UARTFBRD & 0xffff)
	movt r1,#(UART0_UARTFBRD >> 16)
	mov r0,#44
	str r0,[r1]		; Andra värdet för att få 115200 baud

	mov r1,#(UART0_UARTLCRH & 0xffff)
	movt r1,#(UART0_UARTLCRH >> 16)
	mov r0,#0x60
	str r0,[r1]		; 8 bit, 1 stop bit, ingen paritet, ingen FIFO
	
	mov r1,#(UART0_UARTCTL & 0xffff)
	movt r1,#(UART0_UARTCTL >> 16)
	mov r0,#0x0301
	str r0,[r1]		; Börja använda serieport

	bx  lr

; Definitioner för registeradresser (32-bitars konstanter) 
GPIOHBCTL	.equ	0x400FE06C
RCGCUART	.equ	0x400FE618
RCGCGPIO	.equ	0x400fe608
UART0_UARTIBRD	.equ	0x4000c024
UART0_UARTFBRD	.equ	0x4000c028
UART0_UARTLCRH	.equ	0x4000c02c
UART0_UARTCTL	.equ	0x4000c030
UART0_UARTFR	.equ	0x4000c018
UART0_UARTDR	.equ	0x4000c000
GPIOA_GPIOAFSEL	.equ	0x40004420
GPIOA_GPIODEN	.equ	0x4000451c
GPIOE_GPIODATA	.equ	0x400240fc
GPIOE_GPIODIR	.equ	0x40024400
GPIOE_GPIOAFSEL	.equ	0x40024420
GPIOE_GPIOPUR	.equ	0x40024510
GPIOE_GPIODEN	.equ	0x4002451c
GPIOE_GPIOAMSEL	.equ	0x40024528
GPIOE_GPIOPCTL	.equ	0x4002452c
GPIOF_GPIODATA	.equ	0x4002507c
GPIOF_GPIODIR	.equ	0x40025400
GPIOF_GPIOAFSEL	.equ	0x40025420
GPIOF_GPIODEN	.equ	0x4002551c
GPIOF_GPIOLOCK	.equ	0x40025520
GPIOKEY		.equ	0x4c4f434b
GPIOF_GPIOPUR	.equ	0x40025510
GPIOF_GPIOCR	.equ	0x40025524
GPIOF_GPIOAMSEL	.equ	0x40025528
GPIOF_GPIOPCTL	.equ	0x4002552c

;; Initiering av port F
;; Förstör r0, r1, r2
initGPIOF:
	mov r1,#(RCGCGPIO & 0xffff)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x20		; Koppla in GPIO port F
	str r0,[r1]
	nop 			; Vänta lite
	nop
	nop

	mov r1,#(GPIOHBCTL & 0xffff)	; Använd apb för GPIO
	movt r1,#(GPIOHBCTL >> 16)
	ldr r0,[r1]
	mvn r2,#0x2f		; bit 5-0 = 0, övriga = 1
	and r0,r0,r2
	str r0,[r1]

	mov r1,#(GPIOF_GPIOLOCK & 0xffff)
	movt r1,#(GPIOF_GPIOLOCK >> 16)
	mov r0,#(GPIOKEY & 0xffff)
	movt r0,#(GPIOKEY >> 16)
	str r0,[r1]		; Lås upp port F konfigurationsregister

	mov r1,#(GPIOF_GPIOCR & 0xffff)
	movt r1,#(GPIOF_GPIOCR >> 16)
	mov r0,#0x1f		; tillåt konfigurering av alla bitar i porten
	str r0,[r1]

	mov r1,#(GPIOF_GPIOAMSEL & 0xffff)
	movt r1,#(GPIOF_GPIOAMSEL >> 16)
	mov r0,#0x00		; Koppla bort analog funktion
	str r0,[r1]

	mov r1,#(GPIOF_GPIOPCTL & 0xffff)
	movt r1,#(GPIOF_GPIOPCTL >> 16)
	mov r0,#0x00		; använd port F som GPIO
	str r0,[r1]

	mov r1,#(GPIOF_GPIODIR & 0xffff)
	movt r1,#(GPIOF_GPIODIR >> 16)
	mov r0,#0x0e		; styr LED (3 bits), andra bitar är ingångar
	str r0,[r1]

	mov r1,#(GPIOF_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOF_GPIOAFSEL >> 16)
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	mov r1,#(GPIOF_GPIOPUR & 0xffff)
	movt r1,#(GPIOF_GPIOPUR >> 16)
	mov r0,#0x11		; svag pull-up för tryckknapparna
	str r0,[r1]

	mov r1,#(GPIOF_GPIODEN & 0xffff)
	movt r1,#(GPIOF_GPIODEN >> 16)
	mov r0,#0xff		; alla pinnar som digital I/O
	str r0,[r1]

	bx lr


;; Initiering av port E
;; Förstör r0, r1
initGPIOE:
	mov r1,#(RCGCGPIO & 0xffff)    ; Clock gating port (slå på I/O-enheter)
	movt r1,#(RCGCGPIO >> 16)
	ldr r0,[r1]
	orr r0,r0,#0x10		; koppla in GPIO port B
	str r0,[r1]
	nop			; vänta lite
	nop
	nop

	mov r1,#(GPIOE_GPIODIR & 0xffff)
	movt r1,#(GPIOE_GPIODIR >> 16)
	mov r0,#0x0		; alla bitar är ingångar
	str r0,[r1]

	mov r1,#(GPIOE_GPIOAFSEL & 0xffff)
	movt r1,#(GPIOE_GPIOAFSEL >> 16)
	mov r0,#0		; alla portens bitar är GPIO
	str r0,[r1]

	mov r1,#(GPIOE_GPIOAMSEL & 0xffff)
	movt r1,#(GPIOE_GPIOAMSEL >> 16)
	mov r0,#0x00		; använd inte analoga funktioner
	str r0,[r1]

	mov r1,#(GPIOE_GPIOPCTL & 0xffff)
	movt r1,#(GPIOE_GPIOPCTL >> 16)
	mov r0,#0x00		; använd inga specialfunktioner på port B	
	str r0,[r1]

	mov r1,#(GPIOE_GPIOPUR & 0xffff)
	movt r1,#(GPIOE_GPIOPUR >> 16)
	mov r0,#0x00		; ingen pullup på port B
	str r0,[r1]

	mov r1,#(GPIOE_GPIODEN & 0xffff)
	movt r1,#(GPIOE_GPIODEN >> 16)
	mov r0,#0xff		; alla pinnar är digital I/O
	str r0,[r1]

	bx lr


;; Utskrift av ett tecken på serieport
;; r0 innehåller tecken att skriva ut (1 byte)
;; returnerar först när tecken skickats
;; förstör r0, r1 och r2 
printchar:
	mov r1,#(UART0_UARTFR & 0xffff)	; peka på serieportens statusregister
	movt r1,#(UART0_UARTFR >> 16)
loop1:
	ldr r2,[r1]			; hämta statusflaggor
	ands r2,r2,#0x20		; kan ytterligare tecken skickas?
	bne loop1			; nej, försök igen
	mov r1,#(UART0_UARTDR & 0xffff)	; ja, peka på serieportens dataregister
	movt r1,#(UART0_UARTDR >> 16)
	str r0,[r1]			; skicka tecken
	bx lr




