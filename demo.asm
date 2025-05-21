
; Number Guessing Game for EMU8086 with CSV logging and 5-second time limit
; COM file format (org 100h)
org 100h
jmp start

; =============== DATA SECTION ===============
target db ?
guess dw ?
attempts db ?
player_name db 20 dup(?)  ; Buffer for player name
name_length db 0          ; Length of entered name
score dw 0                ; Player's score
level db 0               ; Difficulty level (1-3)
result db 0               ; 0=lose, 1=win

; Time-related variables
start_time dw ?
current_time dw ?
timeout_msg db 07h, 0Dh, 0Ah, "Time's up! That attempt took too long.", 0Dh, 0Ah, "$" ; Beep + message

; File handling variables
filename db "scoress.csv",0
filehandle dw ?
buffer db 50 dup(?)      ; Buffer for CSV line
newline_str db 0Dh, 0Ah  ; CR+LF for file

; Messages
welcome_msg db 0Dh, 0Ah, "Welcome to the Number Guessing Game!", 0Dh, 0Ah, "$"

main_menu db 0Dh, 0Ah, "Main Menu:", 0Dh, 0Ah
          db "1. Start Game", 0Dh, 0Ah
          db "2. Instructions", 0Dh, 0Ah
          db "3. View Scores", 0Dh, 0Ah
          db "4. Exit", 0Dh, 0Ah
          db "Enter your choice (1-4): $"

instructions_msg db 0Dh, 0Ah, "Instructions:", 0Dh, 0Ah
                db "Guess a number between 1 and 100.", 0Dh, 0Ah
                db "You have limited attempts based on difficulty.", 0Dh, 0Ah
                db "Each guess must be made within 5 seconds.", 0Dh, 0Ah
                db "The game will tell you if your guess is too high or low.", 0Dh, 0Ah
                db "Good luck!", 0Dh, 0Ah, "$"

name_prompt db 0Dh, 0Ah, "Enter your name (max 19 chars): $"
difficulty_menu db 0Dh, 0Ah, "Select Difficulty Level:", 0Dh, 0Ah
               db "1. Easy (10 attempts)", 0Dh, 0Ah
               db "2. Medium (7 attempts)", 0Dh, 0Ah
               db "3. Hard (5 attempts)", 0Dh, 0Ah
               db "Enter your choice (1-3): $"

msg1 db 0Dh, 0Ah, "Guess a number between 1 and 100: $"
msg2 db 0Dh, 0Ah, "Too low! Try again.", 0Dh, 0Ah, "$"
msg3 db 0Dh, 0Ah, "Too high! Try again.", 0Dh, 0Ah, "$"
correct_msg db 0Dh, 0Ah, "Congratulations! You guessed correctly!", 0Dh, 0Ah, "$"
game_over_msg db 0Dh, 0Ah, "Game Over! No more attempts.", 0Dh, 0Ah, "$"
attempt_rem db 0Dh, 0Ah, "Remaining attempts: $"
newline db 0Dh, 0Ah, "$"
scores_header db "Name,Level,Score,Result", 0Dh, 0Ah, "$"
correct_number_msg db 0Dh, 0Ah, "The correct number was: $"

; =============== CODE SECTION ===============
start:
    ; Display welcome message
    mov dx, offset welcome_msg
    mov ah, 9
    int 21h

main_menu_loop:
    ; Display main menu
    mov dx, offset main_menu
    mov ah, 9
    int 21h

    ; Get user choice
    mov ah, 1
    int 21h

    ; Process choice
    cmp al, '1'
    je start_game
    cmp al, '2'
    je show_instructions
    cmp al, '3'
    je show_scores
    cmp al, '4'
    je exit_program
    jmp main_menu_loop  ; Invalid choice, try again

start_game:
    ; Get player name
    mov dx, offset name_prompt
    mov ah, 9
    int 21h
    
    mov di, offset player_name
    mov [name_length], 0
    
read_name:
    mov ah, 1
    int 21h
    
    cmp al, 0Dh      ; Check for Enter key
    je name_done
    
    cmp [name_length], 19 ; Max 19 characters
    jge read_name
    
    mov [di], al     ; Store character
    inc di
    inc [name_length]
    jmp read_name
    
name_done:
    mov byte ptr [di], 0 ; Null-terminate the name
    
    ; Display difficulty menu
    mov dx, offset difficulty_menu
    mov ah, 9
    int 21h

    ; Get difficulty choice
    mov ah, 1
    int 21h

    ; Set difficulty parameters
    cmp al, '1'
    je easy_mode
    cmp al, '2'
    je medium_mode
    cmp al, '3'
    je hard_mode
    jmp start_game  ; Invalid choice, try again

easy_mode:
    mov [attempts], 10
    mov [level], 1
    jmp game_setup

medium_mode:
    mov [attempts], 7
    mov [level], 2
    jmp game_setup

hard_mode:
    mov [attempts], 5
    mov [level], 3
    jmp game_setup

game_setup:
    call generate_randomnumber
    mov [target], al
    mov [score], 0
    jmp game_loop

show_instructions:
    mov dx, offset instructions_msg
    mov ah, 9
    int 21h
    jmp main_menu_loop

show_scores:
    ; Display scores from file
    call display_csv_file
    jmp main_menu_loop

game_loop:
    ; Check if attempts remain
    cmp [attempts], 0
    jle game_over

    ; Prompt for guess
    mov dx, offset msg1
    mov ah, 9
    int 21h

    ; Read number with timeout
    call read_num
    cmp ax, 0FFFFh  ; Check for timeout
    je timeout_penalty
    
    mov [guess], ax
    inc [score]  ; Increment score (attempts used)

    ; Compare with target
    mov al, byte ptr [target]
    cmp byte ptr [guess], al
    jl too_low
    jg too_high
    je correct_guess

timeout_penalty:
    ; Display beep and timeout message (combined)
    mov dx, offset timeout_msg
    mov ah, 9
    int 21h
    
    dec [attempts]
    call display_attempts
    jmp game_loop

too_low:
    mov dx, offset msg2
    mov ah, 9
    int 21h
    jmp decrement_attempt

too_high:
    mov dx, offset msg3
    mov ah, 9
    int 21h
    jmp decrement_attempt

correct_guess:
    mov dx, offset correct_msg
    mov ah, 9
    int 21h
    mov [result], 1  ; Set result to win
    call save_to_csv
    jmp main_menu_loop

decrement_attempt:
    dec [attempts]
    call display_attempts
    jmp game_loop

game_over:
    mov dx, offset game_over_msg
    mov ah, 9
    int 21h
    
    ; Display the correct number
    mov dx, offset correct_number_msg
    mov ah, 9
    int 21h
    
    ; Convert target number to ASCII and display
    mov al, [target]
    xor ah, ah
    call word_to_ascii
    
    ; Display the number
    mov si, offset word_ascii_buf
display_number:
    lodsb
    cmp al, 0
    je done_displaying
    mov dl, al
    mov ah, 2
    int 21h
    jmp display_number
    
done_displaying:
    ; New line
    mov dx, offset newline
    mov ah, 9
    int 21h
    
    mov [result], 0  ; Set result to lose
    call save_to_csv
    jmp main_menu_loop

; =============== SUBROUTINES ================
get_current_time:
    ; Returns current time in ticks (1 tick = ~55ms) in AX
    push cx
    push dx
    mov ah, 0
    int 1Ah        ; BIOS time function
    mov ax, dx     ; Low word of tick count in DX
    pop dx
    pop cx
    ret

check_timeout:
    ; Checks if 5 seconds (91 ticks) have passed since start_time
    ; Returns: CF set if timeout occurred
    push ax
    push bx
    push dx
    
    call get_current_time
    mov bx, ax          ; Current time in BX
    mov ax, [start_time]
    sub bx, ax          ; BX = elapsed ticks
    
    ; 5 seconds = ~91 ticks (91.1 to be precise)
    cmp bx, 91
    jb no_timeout
    
    ; Timeout occurred
    stc
    jmp timeout_done
    
no_timeout:
    clc
    
timeout_done:
    pop dx
    pop bx
    pop ax
    ret

read_num:
    ; Reads a number from keyboard with timeout, returns in AX
    push bx
    push cx
    push dx
    
    mov bx, 0       ; Initialize result
    mov cx, 0       ; Digit counter
    
    ; Start timer
    call get_current_time
    mov [start_time], ax
    
read_loop:
    ; Check for timeout
    call check_timeout
    jc read_timeout
    
    ; Check if key is available
    mov ah, 1
    int 16h
    jz read_loop    ; No key available
    
    ; Read the key
    mov ah, 0
    int 16h
    
    ; Check for Enter key
    cmp al, 0Dh
    je read_done
    
    ; Validate digit
    cmp al, '0'
    jb read_loop
    cmp al, '9'
    ja read_loop
    
    ; Echo the character
    mov dl, al
    mov ah, 2
    int 21h
    
    ; Convert to number and add to total
    sub al, '0'
    mov ah, 0
    push ax
    
    ; Multiply current total by 10
    mov ax, bx
    mov dx, 10
    mul dx
    mov bx, ax
    
    ; Add new digit
    pop ax
    add bx, ax
    inc cx
    jmp read_loop
    
read_timeout:
    mov ax, 0FFFFh
    pop dx
    pop cx
    pop bx
    ret
    
read_done:
    mov ax, bx
    pop dx
    pop cx
    pop bx
    ret
    
read_exit:
    pop dx
    pop cx
    pop bx
    ret

display_attempts:
    ; Displays remaining attempts
    push ax
    push bx
    push dx
    
    mov dx, offset attempt_rem
    mov ah, 9
    int 21h
    
    ; Convert number to ASCII and display
    mov al, [attempts]
    xor ah, ah
    mov bl, 10
    div bl
    
    ; Display tens digit (if any)
    cmp al, 0
    je skip_tens
    add al, '0'
    mov dl, al
    mov ah, 2
    int 21h
    
skip_tens:
    ; Display units digit
    add ah, '0'
    mov dl, ah
    mov ah, 2
    int 21h
    
    ; New line
    mov dx, offset newline
    mov ah, 9
    int 21h
    
    pop dx
    pop bx
    pop ax
    ret

generate_randomnumber:
    ; Generates random number 1-100, returns in AL
    push bx
    push cx
    push dx
    
    ; Get system timer count
    mov ah, 0
    int 1Ah
    
    ; Use it as seed
    mov ax, dx
    xor dx, dx
    mov cx, 100
    div cx
    
    ; Ensure number is 1-100
    inc dx
    mov al, dl
    
    pop dx
    pop cx
    pop bx
    ret

save_to_csv:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Try to open existing file (in append mode)
    mov ah, 3Dh        ; DOS open file function
    mov al, 2          ; Read/write access
    mov dx, offset filename
    xor cx, cx         ; Normal file attributes
    int 21h
    jnc append_to_file ; If file exists, append to it
    
    ; If file doesn't exist, create it
    mov ah, 3Ch        ; DOS create file function
    mov cx, 0          ; Normal file attributes
    mov dx, offset filename
    int 21h
    jc save_error      ; If carry, error creating file
    mov [filehandle], ax
    
    ; Write header to new file
    call write_header
    jmp write_record
    
append_to_file:
    mov [filehandle], ax
    
    ; Move file pointer to end (for appending)
    mov ah, 42h        ; DOS move file pointer function
    mov al, 2          ; Move relative to end of file
    mov bx, [filehandle]
    xor cx, cx         ; Offset high word = 0
    xor dx, dx         ; Offset low word = 0
    int 21h
    
write_record:
    ; Prepare CSV record in buffer
    mov di, offset buffer
    
    ; Copy player name
    mov si, offset player_name
    mov cl, [name_length]
    mov ch, 0
    jcxz name_empty
copy_name:
    lodsb
    stosb
    loop copy_name
    
name_empty:
    ; Add comma separator
    mov al, ','
    stosb
    
    ; Add level (1-3)
    mov al, [level]
    add al, '0'
    stosb
    mov al, ','
    stosb
    
    ; Add score (convert to ASCII)
    mov ax, [score]
    call word_to_ascii
    mov si, offset word_ascii_buf
copy_score:
    lodsb
    cmp al, 0
    je score_done
    stosb
    jmp copy_score
    
score_done:
    mov al, ','
    stosb
    
    ; Add result (0 or 1)
    mov al, [result]
    add al, '0'
    stosb
    
    ; Add CRLF
    mov ax, word ptr [newline_str]
    stosw
    
    ; Calculate record length
    mov cx, di
    sub cx, offset buffer
    
    ; Write buffer to file
    mov ah, 40h        ; DOS write to file function
    mov bx, [filehandle]
    mov dx, offset buffer
    int 21h
    
    ; Close file
    mov ah, 3Eh
    mov bx, [filehandle]
    int 21h
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret  
    
save_error:
    ; Just return if we can't save
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

write_header:
    ; Write CSV header to file
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 40h        ; DOS write to file function
    mov bx, [filehandle]
    mov cx, 25         ; Length of header string
    mov dx, offset scores_header
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

word_to_ascii:
    ; Converts word in AX to ASCII string in word_ascii_buf
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov di, offset word_ascii_buf
    mov bx, 10
    xor cx, cx         ; Digit counter
    
    ; Handle zero case
    test ax, ax
    jnz convert_loop
    mov byte ptr [di], '0'
    inc di
    jmp null_terminate
    
convert_loop:
    xor dx, dx
    div bx             ; Divide AX by 10
    add dl, '0'        ; Convert remainder to ASCII
    push dx            ; Store digit on stack
    inc cx             ; Increment digit count
    test ax, ax        ; Check if quotient is zero
    jnz convert_loop
    
store_digits:
    pop ax             ; Get digit from stack
    stosb              ; Store in buffer
    loop store_digits
    
null_terminate:
    mov byte ptr [di], 0 ; Null-terminate string
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

display_csv_file:
    ; Display contents of CSV file
    push ax
    push bx
    push cx
    push dx
    
    ; Try to open file
    mov ah, 3Dh        ; DOS open file function
    mov al, 0          ; Read-only access
    mov dx, offset filename
    int 21h
    jc display_error   ; If carry, file doesn't exist
    
    mov [filehandle], ax
    
    ; Display header
    mov dx, offset scores_header
    mov ah, 9
    int 21h
    
read_file_loop:
    ; Read from file
    mov ah, 3Fh        ; DOS read from file function
    mov bx, [filehandle]
    mov cx, 1          ; Read one byte at a time
    mov dx, offset buffer
    int 21h
    
    ; Check if we read anything
    cmp ax, 0
    je close_display_file
    
    ; Display the character
    mov dl, [buffer]
    mov ah, 2
    int 21h
    
    jmp read_file_loop
    
close_display_file:
    ; Close file
    mov ah, 3Eh
    mov bx, [filehandle]
    int 21h
    
display_error:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data for subroutines
word_ascii_buf db 6 dup(0)  ; Buffer for ASCII conversion

exit_program:
    ; Exit to DOS
    mov ax, 4C00h
    int 21h