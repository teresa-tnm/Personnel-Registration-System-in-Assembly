section .data
    ; Messages
    menu_msg db 'Menu:', 10, '1-Enregistrer', 10, '2-Lister', 10, '3-Supprimer', 10, '4-Afficher plus age/jeune', 10, '6-Quitter', 10, 'Choix: ', 0
    msg_prompt db 'Nom Age: ', 0
    msg_list db 'Liste des personnes:', 10, 0
    msg_delete_prompt db 'Entrez le numero a supprimer: ', 0
    msg_error_invalid db 'Numero invalide!', 10, 0
    msg_oldest db 'Plus agee: ', 0
    msg_youngest db 'Plus jeune: ', 0
    space db ' ', 0
    newline db 10, 0

    ; Données
    personnel times 680 db 0    ; 10 entrées (68 octets: 64 nom + 4 âge)
    count dd 0                  ; Nombre de personnes enregistrées
    input_buffer times 256 db 0 ; Tampon pour l'entrée utilisateur

section .text
global _start

_start:
    jmp main_loop

; Boucle principale
main_loop:
    mov ecx, menu_msg
    call print_str
    mov eax, 3
    mov ebx, 0
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
    je show_oldest_youngest
    cmp byte [input_buffer], '6'
    je quitter
    jmp main_loop

; 1 - Enregistrer une personne
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

; 2 - Lister les personnes
display_list:
    mov ecx, msg_list
    call print_str
    mov esi, personnel
    mov edx, 0          ; Index
    cmp dword [count], 0
    je display_done
display_loop:
    push edx            ; Sauvegarder l'index
    mov eax, edx        ; Afficher l'index
    call print_number
    mov ecx, space
    call print_str
    mov ecx, esi        ; Afficher le nom
    call print_str
    mov ecx, space
    call print_str
    mov eax, [esi + 64] ; Afficher l'âge
    call print_number
    mov ecx, newline
    call print_str
    pop edx             ; Restaurer l'index
    add esi, 68         ; Passer à l'enregistrement suivant
    inc edx
    cmp edx, [count]
    jl display_loop
display_done:
    jmp main_loop

; 3 - Supprimer une personne
supprimer:
    mov ecx, msg_delete_prompt
    call print_str
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 256
    int 0x80
    call str_to_int     ; Convertir l'entrée en entier (EAX)
    cmp eax, 0
    jl invalid_index
    cmp eax, [count]
    jge invalid_index
    mov ebx, 68
    imul ebx            ; EAX = index * 68
    mov edi, personnel
    add edi, eax        ; EDI = adresse de l'enregistrement
    mov esi, edi
    add esi, 68         ; ESI = prochain enregistrement
    mov ecx, [count]
    sub ecx, eax        ; ECX = nombre total après l'index
    dec ecx             ; Nombre d'enregistrements à décaler
    cmp ecx, 0
    jle shift_done
shift_loop:
    push ecx            ; Sauvegarder le compteur
    mov ecx, 68         ; 68 octets à copier
copy_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jnz copy_loop
    pop ecx             ; Restaurer le compteur
    dec ecx
    jnz shift_loop
shift_done:
    dec dword [count]
    call display_list   ; Afficher la liste mise à jour
    jmp main_loop
invalid_index:
    mov ecx, msg_error_invalid
    call print_str
    jmp main_loop

; 4 - Afficher la personne la plus âgée et la plus jeune
show_oldest_youngest:
    cmp dword [count], 0
    je empty_list       ; Liste vide
    mov esi, personnel  ; Début de la liste
    mov eax, [esi + 64] ; Âge de la première personne (max initial)
    mov ebx, eax        ; Âge min initial
    mov edi, 0          ; Index du plus âgé
    mov edx, 0          ; Index du plus jeune
    mov ecx, 1          ; Compteur d'index
    cmp ecx, [count]
    jge show_result     ; Une seule personne
scan_loop:
    mov eax, [esi + 64] ; Âge actuel (max candidat)
    cmp eax, [esi - 4]  ; Comparer avec le max actuel (-4 car ESI pointe déjà à l'âge)
    jg update_max
back_to_min:
    cmp eax, ebx        ; Comparer avec le min actuel
    jl update_min
next_entry:
    add esi, 68         ; Passer à l'entrée suivante
    inc ecx
    cmp ecx, [count]
    jl scan_loop
    jmp show_result
update_max:
    mov edi, ecx        ; Mettre à jour l'index du plus âgé
    mov eax, [esi + 64] ; Mettre à jour le max
    jmp back_to_min
update_min:
    mov edx, ecx        ; Mettre à jour l'index du plus jeune
    mov ebx, eax        ; Mettre à jour le min
    jmp next_entry
show_result:
    ; Afficher le plus âgé
    mov ecx, msg_oldest
    call print_str
    mov eax, edi        ; Index du plus âgé
    call print_number
    mov ecx, space
    call print_str
    mov ebx, 68
    imul ebx            ; Calculer l'adresse
    mov ecx, personnel
    add ecx, eax        ; Adresse du nom
    call print_str
    mov ecx, space
    call print_str
    mov eax, [ecx + 64] ; Âge
    call print_number
    mov ecx, newline
    call print_str

    ; Afficher le plus jeune
    mov ecx, msg_youngest
    call print_str
    mov eax, edx        ; Index du plus jeune
    call print_number
    mov ecx, space
    call print_str
    mov ebx, 68
    imul ebx            ; Calculer l'adresse
    mov ecx, personnel
    add ecx, eax        ; Adresse du nom
    call print_str
    mov ecx, space
    call print_str
    mov eax, [ecx + 64] ; Âge
    call print_number
    mov ecx, newline
    call print_str
    jmp main_loop
empty_list:
    mov ecx, msg_error_invalid ; Réutilisé pour "liste vide"
    call print_str
    jmp main_loop

; 6 - Quitter
quitter:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; Fonction : Lire et stocker l'entrée (nom et âge)
read_input:
    mov esi, input_buffer
    mov edi, esi
find_space:
    mov al, byte [esi]
    inc esi
    cmp al, ' '
    jne find_space
    dec esi
    mov byte [esi], 0   ; Terminer le nom
    inc esi             ; ESI = chaîne d'âge
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
    push eax            ; Sauvegarder l'âge
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
    mov byte [edi], 0   ; Null-terminate
    pop eax             ; Restaurer l'âge
    mov edi, personnel
    add edi, edx
    add edi, 64
    mov [edi], eax
    inc dword [count]
exit_read:
    ret

; Fonction : Convertir une chaîne en entier
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

; Fonction : Afficher une chaîne
print_str:
    push eax
    push ebx
    push edx
    mov eax, 4
    mov ebx, 1
    mov edx, 0
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

; Fonction : Afficher un nombre
print_number:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    mov esi, input_buffer + 255
    mov byte [esi], 0
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
