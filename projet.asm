section .data
    menuStr     db "Menu: 1-Enregistrer, 2-Lister, 6-Quitter", 0xA, 0
    menuStr_len equ $ - menuStr
    prompt      db "Entrez nom et age: ", 0xA, 0
    prompt_len  equ $ - prompt
    listHeader  db "Liste des personnes:", 0xA, 0
    listHeader_len equ $ - listHeader
    spaceStr    db " ", 0
    newlineStr  db 0xA, 0
    newlineStr_len equ $ - newlineStr

    inputBuffer db 64 dup(0)         ; Tampon pour l'entrée utilisateur
    nameBuffer  db 32 dup(0)         ; Tampon temporaire pour le nom
    numBuffer   db 12 dup(0)         ; Tampon pour la conversion d'un nombre en chaîne

    maxPersons      equ 10
    personRecordSize equ 36         ; 32 octets pour le nom, 4 pour l'âge
    personRecords   db maxPersons * personRecordSize dup(0)
    personCount     dd 0

section .text
global _start

_start:
menu_loop:
    ; Afficher le menu
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, menuStr
    mov     edx, menuStr_len
    int     0x80

    ; Lire le choix (2 octets : chiffre et saut de ligne)
    mov     eax, 3
    mov     ebx, 0
    mov     ecx, inputBuffer
    mov     edx, 2
    int     0x80

    cmp     byte [inputBuffer], '1'
    je      register_person
    cmp     byte [inputBuffer], '2'
    je      list_persons
    cmp     byte [inputBuffer], '6'
    je      exit_program
    jmp     menu_loop

; -------------------------
; 1. Enregistrer du personnel
; -------------------------
register_person:
    ; Clear nameBuffer
    mov     edi, nameBuffer
    mov     ecx, 32
    xor     al, al
    rep stosb

    ; Afficher le prompt "Entrez nom et age: "
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, prompt
    mov     edx, prompt_len
    int     0x80

    ; Lire l'entrée utilisateur
    mov     eax, 3
    mov     ebx, 0
    mov     ecx, inputBuffer
    mov     edx, 64
    int     0x80

    ; Extraire le nom : copier les caractères jusqu'à l'espace ou le saut de ligne
    mov     esi, inputBuffer
    mov     edi, nameBuffer
parse_name:
    cmp     byte [esi], ' '
    je      parse_age
    cmp     byte [esi], 0xA
    je      parse_age
    mov     al, [esi]
    mov     [edi], al
    inc     esi
    inc     edi
    jmp     parse_name

; Conversion de la chaîne de l'âge
parse_age:
    cmp     byte [esi], ' '
    je      skip_space
    cmp     byte [esi], 0xA
    je      store_record
    jmp     parse_age2
skip_space:
    inc     esi
parse_age2:
    cmp     byte [esi], ' '
    je      skip_space
    cmp     byte [esi], 0xA
    je      store_record

    xor     eax, eax         ; EAX = 0 pour accumuler l'âge
parse_age_loop:
    mov     bl, [esi]
    cmp     bl, '0'
    jb      finish_age
    cmp     bl, '9'
    ja      finish_age
    imul    eax, eax, 10     ; age = age * 10
    sub     bl, '0'
    add     eax, ebx        ; age += chiffre
    inc     esi
    jmp     parse_age_loop
finish_age:
    ; L'âge est maintenant dans EAX

store_record:
    ; Vérifier qu'il reste de la place pour un nouvel enregistrement
    mov     ebx, [personCount]
    cmp     ebx, maxPersons
    jae     registration_full

    ; Calculer l'adresse de stockage : personRecords + (personCount * personRecordSize)
    mov     ecx, ebx
    imul    ecx, personRecordSize
    mov     edx, personRecords
    add     edx, ecx

    ; Copier nameBuffer (32 octets) dans le champ nom du nouvel enregistrement
    mov     esi, nameBuffer
    mov     edi, edx
    mov     ecx, 32
copy_name:
    mov     al, [esi]
    mov     [edi], al
    inc     esi
    inc     edi
    loop    copy_name

    ; Stocker l'âge dans le champ situé à offset 32
    mov     [edx+32], eax

    ; Incrémenter le compteur d'enregistrements
    mov     eax, [personCount]
    inc     eax
    mov     [personCount], eax

    jmp     menu_loop

registration_full:
    ; Si le tableau est plein, retour au menu (peut être amélioré par un message)
    jmp     menu_loop

; -------------------------
; 2. Lister des personnes enregistrées
; -------------------------
list_persons:
    ; Afficher l'en-tête "Liste des personnes:"
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, listHeader
    mov     edx, listHeader_len
    int     0x80

    xor     ecx, ecx       ; Index = 0
list_loop:
    mov     eax, [personCount]
    cmp     ecx, eax
    jge     end_list

    ; Afficher le numéro d'enregistrement (index + 1)
    mov     eax, ecx
    inc     eax
    call    print_number

    ; Afficher un espace
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, spaceStr
    mov     edx, 1
    int     0x80

    ; Calculer l'adresse de l'enregistrement : personRecords + (ecx * personRecordSize)
    mov     ebx, ecx
    imul    ebx, personRecordSize
    mov     esi, personRecords
    add     esi, ebx

    ; Afficher le nom (32 octets)
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, esi
    mov     edx, 32
    int     0x80

    ; Afficher un espace
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, spaceStr
    mov     edx, 1
    int     0x80

    ; Afficher l'âge (situé à offset 32)
    mov     eax, [esi+32]
    call    print_number

    ; Afficher un saut de ligne
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, newlineStr
    mov     edx, newlineStr_len
    int     0x80

    inc     ecx
    jmp     list_loop

end_list:
    jmp     menu_loop

; -------------------------
; Subroutine : print_number
; Convertit le nombre dans EAX en une chaîne décimale dans numBuffer et l'affiche.
print_number:
    push    ebx
    push    ecx
    push    edx
    push    edi

    ; Initialiser la conversion à partir de numBuffer+11
    mov     edi, numBuffer
    add     edi, 11
    mov     byte [edi], 0    ; Terminateur NUL
    xor     ecx, ecx         ; Compteur de chiffres

    cmp     eax, 0
    jne     pn_loop
    ; Si le nombre est 0, écrire "0"
    mov     byte [numBuffer+10], '0'
    mov     edi, numBuffer+10
    jmp     pn_print

pn_loop:
    xor     edx, edx         ; Préparer EDX pour idiv
    mov     ebx, 10
    idiv    ebx              ; EAX = quotient, EDX = reste
    add     dl, '0'
    dec     edi
    mov     [edi], dl
    inc     ecx
    cmp     eax, 0
    jne     pn_loop

pn_print:
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, edi
    ; Calculer la longueur : (numBuffer+11) - edi
    mov     edx, numBuffer
    add     edx, 11
    sub     edx, edi
    int     0x80

    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    ret

exit_program:
    mov     eax, 1
    xor     ebx, ebx
    int     0x80