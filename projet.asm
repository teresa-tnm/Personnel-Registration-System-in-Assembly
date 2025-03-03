section .data
    ; Menu and Messages
    menu_msg db 'Menu:', 10, '1-Enregistrer', 10, '2-Lister', 10, '3-Supprimer', 10, '4-Plus age/jeune', 10, '6-Quitter', 10, 'Choix: ', 0
    msg_prompt db 'Nom Age: ', 0
    msg_list db 'Liste des personnes:', 10, 0
    msg_delete_prompt db 'Entrez le numero a supprimer: ', 0
    msg_error_invalid db 'Numero invalide!', 10, 0
    msg_no_person db 'Aucune personne enregistree!', 10, 0
    msg_oldest db 'Plus agee: ', 0
    msg_youngest db 'Plus jeune: ', 0
    space db ' ', 0
    newline db 10, 0

    ; Data Storage
    personnel times 680 db 0    ; 10 entries (68 bytes each: 64 for name + 4 for age)
    count dd 0                  ; Number of registered persons
    input_buffer times 256 db 0 ; Buffer for user input

section .text
global _start

_start:
    jmp main_loop

; Main Loop
main_loop:
    mov ecx, menu_msg
    call print_str
    mov eax, 3              ; sys_read
    mov ebx, 0              ; stdin
    mov ecx, input_buffer
    mov edx, 256
    int 0x80
    cmp byte [input_buffer], '1'
    je enregistrer
    cmp byte [input_buffer], '2'
    je display_list
    cmp byte [input_buffer], '3'
    je supprimer
    cmp byte [input_buffer], '4'
    je plus_age_jeune
    cmp byte [input_buffer], '6'
    je quitter
    jmp main_loop

; 1 - Register a Person
enregistrer:
    mov ecx, msg_prompt
    call print_str
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 256
    int 0x80
    call read_input
    jmp main_loop

; 2 - List Persons
display_list:
    mov ecx, msg_list
    call print_str
    mov esi, personnel
    mov edx, 0              ; Index
    cmp dword [count], 0
    je display_done
display_loop:
    push edx
    mov eax, edx
    call print_number       ; Print index
    mov ecx, space
    call print_str
    mov ecx, esi            ; Print name
    call print_str
    mov ecx, space
    call print_str
    mov eax, [esi + 64]     ; Print age
    call print_number
    mov ecx, newline
    call print_str
    pop edx
    add esi, 68             ; Next record
    inc edx
    cmp edx, [count]
    jl display_loop
display_done:
    jmp main_loop

; 3 - Delete a Person
supprimer:
    mov ecx, msg_delete_prompt
    call print_str
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 256
    int 0x80
    call str_to_int         ; Convert input to integer (EAX)
    cmp eax, 0
    jl invalid_index
    cmp eax, [count]
    jge invalid_index
    mov ebx, 68
    imul ebx                ; EAX = index * 68
    mov edi, personnel
    add edi, eax            ; EDI = address of record to delete
    mov esi, edi
    add esi, 68             ; ESI = next record
    mov ecx, [count]
    sub ecx, eax            ; Number of records after index
    dec ecx
    cmp ecx, 0
    jle shift_done
shift_loop:
    push ecx
    mov ecx, 68             ; Bytes to copy
copy_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz copy_loop
    pop ecx
    dec ecx
    jnz shift_loop
shift_done:
    dec dword [count]
    call display_list
    jmp main_loop
invalid_index:
    mov ecx, msg_error_invalid
    call print_str
    jmp main_loop

; 4 - Display Oldest and Youngest Persons
plus_age_jeune:
    cmp dword [count], 0        ; Check if there are any persons
    je no_person

    ; Initialize with the first record
    mov esi, personnel          ; Start of list
    mov edi, esi                ; Oldest pointer = first record
    mov [input_buffer], esi     ; Youngest pointer = first record (stored in memory)
    mov eax, [esi + 64]         ; Age of first person
    mov ebx, eax                ; Max age = first age
    mov [input_buffer + 4], eax ; Min age = first age (stored in memory)

    ; Start loop from second record
    mov edx, 1                  ; Counter starts at 1 (first record already processed)
    mov esi, personnel + 68     ; Second record

find_loop:
    cmp edx, [count]            ; Compare counter with total count
    jge display_result          ; If counter >= count, exit loop
    mov eax, [esi + 64]         ; Load current age

    ; Check if current age is greater than max age
    cmp eax, ebx
    jle check_younger           ; If <= max age, skip to younger check
    mov ebx, eax                ; Update max age
    mov edi, esi                ; Update oldest pointer

check_younger:
    cmp eax, [input_buffer + 4] ; Compare with current min age
    jge next_person             ; If >= min age, skip update
    mov [input_buffer + 4], eax ; Update min age
    mov [input_buffer], esi     ; Update youngest pointer

next_person:
    add esi, 68                 ; Move to next record
    inc edx                     ; Increment counter
    jmp find_loop

display_result:
    ; Display oldest person
    mov ecx, msg_oldest         ; "Plus agee: "
    call print_str
    mov ecx, edi                ; Name of oldest
    call print_str
    mov ecx, space              ; " "
    call print_str
    mov eax, [edi + 64]         ; Age of oldest
    call print_number
    mov ecx, newline            ; "\n"
    call print_str

    ; Display youngest person
    mov ecx, msg_youngest       ; "Plus jeune: "
    call print_str
    mov esi, [input_buffer]     ; Load youngest pointer from memory
    mov ecx, esi                ; Name of youngest
    call print_str
    mov ecx, space              ; " "
    call print_str
    mov eax, [esi + 64]         ; Age of youngest
    call print_number
    mov ecx, newline            ; "\n"
    call print_str
    jmp main_loop

no_person:
    mov ecx, msg_no_person      ; "Aucune personne enregistree!"
    call print_str
    jmp main_loop

; 6 - Quit
quitter:
    mov eax, 1              ; sys_exit
    xor ebx, ebx
    int 0x80

; Helper Function: Read and Store Input (Name and Age)
read_input:
    mov esi, input_buffer
    mov edi, esi
find_space:
    mov al, byte [esi]
    inc esi
    cmp al, ' '
    jne find_space
    dec esi
    mov byte [esi], 0       ; Null-terminate name
    inc esi                 ; Point to age string
    xor eax, eax
    xor ebx, ebx
convert_age:
    mov bl, byte [esi]
    cmp bl, 0
    je store_entry
    cmp bl, 10
    je store_entry
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp convert_age
store_entry:
    mov edx, [count]
    cmp edx, 10
    jge exit_read
    imul edx, 68
    push eax                ; Save age
    mov edi, personnel
    add edi, edx
    mov esi, input_buffer
    mov ecx, 63
copy_name:
    mov al, byte [esi]
    cmp al, 0
    je name_done
    mov byte [edi], al
    inc esi
    inc edi
    dec ecx
    jnz copy_name
name_done:
    mov byte [edi], 0       ; Null-terminate name
    pop eax                 ; Restore age
    mov edi, personnel
    add edi, edx
    add edi, 64
    mov [edi], eax          ; Store age
    inc dword [count]
exit_read:
    ret

; Helper Function: Convert String to Integer
str_to_int:
    mov esi, input_buffer
    xor eax, eax
    xor ebx, ebx
convert_loop:
    mov bl, [esi]
    cmp bl, 0
    je convert_done
    cmp bl, 10
    je convert_done
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp convert_loop
convert_done:
    ret

; Helper Function: Print String
print_str:
    push eax
    push ebx
    push edx
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    mov edx, 0              ; Length counter
strlen_loop:
    cmp byte [ecx + edx], 0
    je strlen_done
    inc edx
    jmp strlen_loop
strlen_done:
    int 0x80
    pop edx
    pop ebx
    pop eax
    ret

; Helper Function: Print Number
print_number:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov esi, input_buffer + 255
    mov byte [esi], 0       ; Null-terminate
    mov ebx, 10
convert_num:
    dec esi
    xor edx, edx
    div ebx
    add dl, '0'
    mov [esi], dl
    test eax, eax
    jnz convert_num
    mov ecx, esi
    call print_str
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
