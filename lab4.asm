include final.mac
.MODEL	SMALL
.STACK	266
.DATA
	err_str		 DB 0AH,0DH,'--- ERROR ---',0DH,0AH
				 DB 'Input format: operand1 operator operand2',0DH,0AH
				 DB 'Valid operands are: signed decimal numbers',0DH,0AH 
				 DB 'Valid operators are one of: + - * / %',0DH,0AH,'$'
	input_str	 DB 'Enter an expression: ','$'
	operand1_str DB 'Operand 1: ','$'
	operand2_str DB 'Operand 2: ','$'
	operator_str DB 'Operator: ','$'
    newline      DB 0AH,0DH,'$'  
    buffer       DB 100   			; max number(100) of chars expected
	num          DB ?           	; returns the number of chars typed
	Act_Buf      DB 100 DUP ('$') 	; actual buffer w/ size=?max number?
	OPERAND1 	 DB 7 DUP('$')		; 7 bytes for 128d unsigned
	OPERAND2	 DB 7 DUP('$')	
	OPERATOR 	 DB ?				; 1 byte for the operator +,-,*,/,%
	space_count	 DB 0				; indicates first or second space in strings
	firstchar	 DB 1				; boolean for first character of op1, op2
	op1_sf		 DB 0				; sign bit for operator1
	op2_sf		 DB 0				; sign bit for operator 2
	
.CODE
	.STARTUP
MAIN	PROC FAR
	MOV  AX,@data
	MOV  DS,AX
    MOV  ES,AX
	MOV  AX,0000H
    MOV  CX,0000H
	
BEGIN_LOOP:
	PRINT_STR input_str
	
	GET_STR buffer
	PRINT_STR newline
	
	CALL INPUT
	
	; print operators and operands prior to operations
	PRINT_STR operand1_str
	PRINT_CHAR op1_sf
	PRINT_STR OPERAND1
	PRINT_STR newline
	PRINT_STR operand2_str
	PRINT_CHAR op2_sf
	PRINT_STR OPERAND2
	PRINT_STR newline
	PRINT_STR operator_str
	PRINT_CHAR OPERATOR
	PRINT_STR newline

	jmp BEGIN_LOOP

	.Exit
MAIN 	ENDP

; procedure to iterate through string, gather arguments and check validity
INPUT PROC NEAR
	MOV CL, NUM		; # of characters into CL
	MOV SI, OFFSET buffer+2
	MOV DI, OFFSET OPERAND1
	CLD
NEXTCHAR:
	DEC CL			; dec character count
	JZ RET1			; return if out of characters
	
	LODSB			; [SI] into AL
	
	; If first character of operand -> check for (-) sign
	CMP firstchar, 1
	JNZ CHKSPACE
	mov firstchar, 0
	CMP AL, '-'
	JNZ CHKSPACE
	; first or 2nd operand
	CMP space_count, 0
	jnz OP2
	mov op1_sf, '-'
	jmp nextchar
OP2:
	mov op2_sf, '-'
	jmp nextchar
	
CHKSPACE:
	; If current character is a space, check if the next character is an operator
	CMP AL, 20H		
	JZ CHECK_OPERATOR 
	
	; check if character is a digit 
	CMP AL, '9'
	JA ERR_LABEL
	CMP AL, '0' 
	JB ERR_LABEL
	
	; character is a digit	
	STOSB 			; AL into ES:[DI]
	JMP NEXTCHAR	; get next character
	
CHECK_OPERATOR:
	INC space_count
	CMP space_count, 2
	jz  NEXTCHAR 	; get next character if it's the second space
	ja 	ERR_LABEL	; more than 2 spaces
	LODSB			; otherwise get the operator -> load character [SI] into AL
	; check if operator is actually an operator
	CMP AL, '/'		
	jz OPERATOR_VALID
	CMP AL, '-'		
	jz OPERATOR_VALID
	CMP AL, '+'		
	jz OPERATOR_VALID
	CMP AL, '*' 
	jz OPERATOR_VALID
	CMP AL, '%'
	jz OPERATOR_VALID
	; operator invalid if we reach this point
ERR_LABEL:
	CALL CALC_ERR	; print error and exit
	
OPERATOR_VALID:
	MOV OPERATOR, AL
	MOV DI, offset operand2
	MOV firstchar, 1
	;current char is operand, check that next char is a space
	LODSB
	DEC CL
	CMP AL, 20H
	jnz ERR_LABEL	
	INC space_count
	jmp NEXTCHAR
	
RET1:
	RET
	
INPUT ENDP

CALC_ERR PROC NEAR
	PRINT_STR err_str
	RET_DOS			; Basically want to print a string and terminate.
	.Exit			; Not sure if we should use the .exit directive, the exit_dos interrupt or both?
CALC_ERR ENDP

END
	