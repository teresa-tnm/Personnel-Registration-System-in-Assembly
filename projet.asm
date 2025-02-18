section .data
personnel times 680 db 0   ; 10 entrées (68 octets chacune: 64 nom + 4 âge)
count dd 0                 ; Compteur d'entrées actuelles
input_buffer times 256 db 0 ; Stockage de saisie
menu_msg db 'Menu:', 10, '1-Enregistrer', 10, '2-Lister', 10, '6-Quitter', 10, 'Choix: ', 0
msg_prompt db 'Nom Age: ', 0
msg_list db 'Liste:', 10, 0
space db ' ', 0
newline db 10, 0

section .text
global _start

_start:
    ; Boucle principale du programme
main_loop:
    ; Afficher le menu
    mov ecx, menu_msg
    call print_str

    ; Lire le choix de l'utilisateur
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 2
    int 0x80

    ; Valider et traiter le choix
    cmp byte [input_buffer], '1'
    je enregistrer
    cmp byte [input_buffer], '2'
    je lister
    cmp byte [input_buffer], '6'
    je quitter
    jmp main_loop

enregistrer:
    ; Demander le nom et l'âge
    mov ecx, msg_prompt
    call print_str

    ; Lire l'entrée
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 256
    int 0x80

    ; Analyser et stocker l'entrée
    call read_input
    jmp main_loop

lister:
    ; Afficher la liste
    call display_list
    jmp main_loop

quitter:
    ; Quitter le programme
    mov eax, 1
    xor ebx, ebx
    int 0x80

read_input:
    ; Trouver le séparateur (espace)
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

    ; Convertir l'âge en entier (EAX)
    xor eax, eax
    xor ebx, ebx

convert_age:
    mov bl, byte [esi]
    cmp bl, 0           ; Vérifier le terminateur nul
    je store_entry
    cmp bl, 10          ; Vérifier la nouvelle ligne
    je store_entry
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    inc esi
    jmp convert_age

store_entry:
    ; Calculer le décalage de stockage
    mov edx, [count]
    cmp edx, 10
    jge exit
    imul edx, 68
    
    ; Sauvegarder l'âge dans la pile
    push eax  ; <-- FIX: Save age before name copy

    ; Copier le nom (max 63 octets)
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
    
    ; Restaurer l'âge depuis la pile
    pop eax  ; <-- FIX: Restore age after name copy
    
    ; Stocker l'âge à l'offset 64
    mov edi, personnel
    add edi, edx
    add edi, 64
    mov [edi], eax
    
    inc dword [count]
exit:
    ret

display_list:
    ; Afficher l'en-tête de la liste
    mov ecx, msg_list
    call print_str

    mov esi, personnel
    mov ecx, [count]
    cmp ecx, 0
    je done

display_loop:
    ; Sauvegarder le compteur et l'adresse actuelle
    push ecx
    push esi
    
    ; Afficher le nom
    mov ecx, esi
    call print_str

    ; Afficher l'espace
    mov ecx, space
    call print_str

    ; Afficher l'âge - correction ici
    mov ecx, esi        ; Adresse de base de l'entrée
    add ecx, 64         ; Ajouter 64 pour obtenir l'emplacement de l'âge
    mov eax, dword [ecx] ; Charger la valeur de l'âge dans eax (explicitement comme dword)
    call print_number

    ; Afficher nouvelle ligne
    mov ecx, newline
    call print_str
    
    ; Restaurer l'adresse et passer à l'entrée suivante
    pop esi
    add esi, 68
    
    ; Restaurer le compteur et boucler
    pop ecx
    dec ecx
    cmp ecx, 0
    jne display_loop

done:
    ret

print_str:
    ; ECX=chaîne (terminée par nul)
    mov edx, 0
str_len:
    cmp byte [ecx + edx], 0
    je print
    inc edx
    jmp str_len
print:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

print_number:
    ; EAX=nombre
    mov edi, input_buffer
    add edi, 11
    mov byte [edi], 0
    dec edi
    
    ; Vérifier si zéro
    cmp eax, 0
    jne convert
    dec edi
    mov byte [edi], '0'
    jmp print_num
    
convert:
    mov ebx, 10
convert_loop:
    xor edx, edx
    idiv ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    cmp eax, 0
    jne convert_loop

print_num:
    mov ecx, edi
    call print_str
    ret
