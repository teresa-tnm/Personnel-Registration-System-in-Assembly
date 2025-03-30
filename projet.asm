section .data
    menu_msg db 'Menu:', 10, '1-Enregistrer', 10, '2-Lister', 10, '3-Supprimer', 10, '4-Plus age/jeune', 10, '5-Age moyen', 10, '6-Quitter', 10, 'Choix: ', 0  ; Le menu avec des sauts de ligne 
    msg_prompt db 'Nom Age: ', 0  ; Message pour demander nom et l âge
    msg_list db 'Liste des personnes:', 10, 0  ;  afficher la liste des personnes
    msg_delete_prompt db 'Entrez le numero a supprimer: ', 0  ; Demande quel numéro a supprimer
    msg_error_invalid db 'Numero invalide!', 10, 0  ; Erreur si le numéro ne existe pas
    msg_no_person db 'Aucune personne enregistree!', 10, 0  ; afficher ca si la liste est vide
    msg_oldest db 'Plus agee: ', 0  ; affiche la personne la plus âgée
    msg_youngest db 'Plus jeune: ', 0  ; affiche la personne la plus jeune
    msg_avg db 'Age en moyenne:', 10, 0  ;calcule l’âge moyen des personnes enregistrées
    open_paren db '(', 0  ; Parenthèse ouvrante pour la liste d’âges
    close_paren db ')', 10, 0  ; Parenthèse fermante avec saut de ligne
    space db ' ', 0  ; Un simple espace pour le formatage
    newline db 10, 0  ;  saut de ligne

    ; Espace pour stocker les données
    personnel times 680 db 0  ; 10 entrées, 68 octets chacune (64 pour le nom, 4 pour l’âge), donc 10 * 68 = 680
    count dd 0  ; Compteur du nombre de personnes, commence à 0
    input_buffer times 256 db 0  ; Tampon pour l’entrée utilisateur

section .text
global _start

_start:
    jmp main_loop  ;  la boucle principale

;la boucle principale 
main_loop:
    mov ecx, menu_msg  ; Je charge le message du menu dans ECX
    call print_str  ; J’appelle ma fonction pour l’afficher
    mov eax, 3  ; Numéro 3 pour l’appel système de lecture
    mov ebx, 0  ; Descripteur 0 = entrée standard 
    mov ecx, input_buffer  ; On stocke l’entrée dans le tampon
    mov edx, 256  ; Longueur max de l’entrée, comme mon tampon
    int 0x80  ; Appel système pour lire ce que l’utilisateur tape
    cmp byte [input_buffer], '1'  ; Est-ce que c’est '1' ?
    je enregistrer  ; Si oui, on va enregistrer la personne
    cmp byte [input_buffer], '2'  ; Peut-être '2' ?
    je display_list  ; pour lister les personnes enregistrée
    cmp byte [input_buffer], '3'  ; Et '3' ?
    je supprimer  ; pour supprimer quelqu’un
    cmp byte [input_buffer], '4'  ; '4' maintenant ?
    je plus_age_jeune  ; pour montrer le plus âgé et le plus jeune
    cmp byte [input_buffer], '5'  ; '5' peut-être ?
    je age_moyen  ; pour calculer l’âge moyen
    cmp byte [input_buffer], '6'  ; Enfin '6' ?
    je quitter  ;pour quitter
    jmp main_loop  ; Sinon, on recommence la boucle

; Option 1 : Enregistrer une personne
enregistrer:
    mov ecx, msg_prompt  ; J’affiche le message "Nom Age: "
    call print_str  ;imprime le
    mov eax, 3  ; Appel système pour lire quelque chose
    mov ebx, 0  ; lire a partir de clavier
    mov ecx, input_buffer  ; Stocke dans le tampon
    mov edx, 256  ; Taille max de l’entrée
    int 0x80  ; Lis ce que l’utilisateur tape
    call read_input  ; Traite l’entrée pour la sauvegarder
    jmp main_loop  ; Retour au menu

; Option 2 : Lister toutes les personnes
display_list:
    mov ecx, msg_list  ; Affiche "Liste des personnes:"
    call print_str  ; print it 
    cmp dword [count], 0  ; Vérifie s’il y a des personnes enregistrées
    je no_person_list  ; Si count = 0, on va afficher le message "vide"
    mov esi, personnel  ; Pointe au début du tableau des personnes
    mov edx, 0  ; Index commence à 0
display_loop:
    push edx  ; Sauve l’index pour ne pas le perdre
    mov eax, edx  ; Charge l’index pour l’afficher
    call print_number  ; Affiche le numéro de l’index
    mov ecx, space  ; Ajoute un espace après l’index
    call print_str  ; Imprime l’espace
    mov ecx, esi  ; Pointe sur le nom de la personne
    call print_str  ; Affiche le nom
    mov ecx, space  ; Ajoute un autre espace
    call print_str  ; Imprime l’espace
    mov eax, [esi + 64]  ; Charge l’âge (64 octets après le nom)
    call print_number  ; Affiche l’âge
    mov ecx, newline  ; Passe à la ligne suivante
    call print_str  ; Imprime le saut de ligne
    pop edx  ; Restaure l’index
    add esi, 68  ; Passe à la personne suivante (68 octets)
    inc edx  ; Incrémente l’index
    cmp edx, [count]  ; A-t-on affiché tout le monde ?
    jl display_loop  ; Si non, continue la boucle
    jmp display_done  ; Sinon, termine
no_person_list:
    mov ecx, msg_no_person  ; Charge le message "Aucune personne enregistrée!"
    call print_str  ; Affiche ce message quand la liste est vide
display_done:
    jmp main_loop  ; Retour au menu principal

; Option 3 : Supprimer une personne
supprimer:
    mov ecx, msg_delete_prompt  ; Demande quel numéro à supprimer
    call print_str  ; Affiche la demande
    mov eax, 3  ; Lecture de l’entrée
    mov ebx, 0  ; Depuis le clavier
    mov ecx, input_buffer  ; Stocke dans le tampon
    mov edx, 256  ; Longueur max
    int 0x80  ; Lis l’entrée
    call str_to_int  ; Convertit en entier dans EAX
    push eax         ; Sauvegarde l’index
    cmp eax, 0       ; Est-ce < 0 ?
    jl invalid_index ; Si oui, erreur
    cmp eax, [count] ; Est-ce >= nombre de personnes ?
    jge invalid_index ; Si oui, erreur aussi
    pop eax          ; Restaure l’index dans EAX
    mov edx, eax     ; Sauve l’index dans EDX pour le garder
    mov ebx, 68      ; Chaque entrée fait 68 octets
    imul eax, ebx    ; Multiplie l’index par 68, résultat dans EAX (offset)
    mov edi, personnel ; Début du tableau
    add edi, eax     ; Pointe sur la personne à supprimer
    mov esi, edi     ; Source = personne suivante
    add esi, 68      ; Avance à l’entrée suivante
    mov ecx, [count] ; Nombre total de personnes
    sub ecx, edx     ; Soustrait l’index (en entrées, pas octets) pour avoir le nombre d’entrées à décaler
    cmp ecx, 0       ; Quelque chose à décaler ?
    jle shift_done   ; Sinon, fini
shift_loop:
    push ecx         ; Sauve le compteur extérieur
    mov ecx, 68      ; 68 octets à copier
copy_loop:
    mov al, [esi]    ; Prend un octet de la source
    mov [edi], al    ; Met dans la destination
    inc esi          ; Octet suivant de la source
    inc edi          ; Octet suivant de la destination
    dec ecx          ; Un octet de moins
    jnz copy_loop    ; Continue si pas fini
    pop ecx          ; Restaure le compteur
    dec ecx          ; Une entrée de moins à décaler
    jnz shift_loop   ; Continue si reste à faire
shift_done:
    dec dword [count] ; Diminue le compteur de personnes
    call display_list ; Affiche la liste mise à jour
    jmp main_loop     ; Retour au menu
invalid_index:
    pop eax           ; Restaure la pile si erreur
    mov ecx, msg_error_invalid ; Message d’erreur
    call print_str    ; Affiche-le
    jmp main_loop     ; Retour au menu

; Option 4 : Afficher la personne la plus âgée et la plus jeune
plus_age_jeune:
    cmp dword [count], 0  ; Y a-t-il des personnes ?
    je no_person  ; Sinon, erreur
    mov esi, personnel  ; Commence avec la première personne
    mov edi, esi  ; Plus âgé = première personne pour l’instant
    mov [input_buffer], esi  ; Plus jeune = première aussi, stocké dans le tampon
    mov eax, [esi + 64]  ; Prend l’âge de la première
    mov ebx, eax  ; Âge max = premier âge
    mov [input_buffer + 4], eax  ; Âge min = premier âge aussi
    mov edx, 1  ; Compteur commence à 1 (premier déjà fait)
    mov esi, personnel + 68  ; Passe à la deuxième personne
find_loop:
    cmp edx, [count]  ; Fin de la liste ?
    jge display_result  ; Si oui, affiche les résultats
    mov eax, [esi + 64]  ; Charge l’âge actuel
    cmp eax, ebx  ; Plus grand que le max ?
    jle check_younger  ; Sinon, vérifie le min
    mov ebx, eax  ; Nouveau max
    mov edi, esi  ; Met à jour le pointeur du plus âgé
check_younger:
    cmp eax, [input_buffer + 4]  ; Plus petit que le min ?
    jge next_person  ; Sinon, passe au suivant
    mov [input_buffer + 4], eax  ; Nouveau min
    mov [input_buffer], esi  ; Met à jour le pointeur du plus jeune
next_person:
    add esi, 68  ; Personne suivante
    inc edx  ; Incrémente le compteur
    jmp find_loop  ; Continue la recherche
display_result:
    mov ecx, msg_oldest  ; Affiche "Plus agee: "
    call print_str  ; Imprime-le
    mov ecx, edi  ; Nom du plus âgé
    call print_str  ; Affiche le nom
    mov ecx, space  ; Espace
    call print_str  ; Imprime l’espace
    mov eax, [edi + 64]  ; Âge du plus âgé
    call print_number  ; Affiche l’âge
    mov ecx, newline  ; Saut de ligne
    call print_str  ; Imprime-le
    mov ecx, msg_youngest  ; Affiche "Plus jeune: "
    call print_str  ; Imprime-le
    mov esi, [input_buffer]  ; Charge le pointeur du plus jeune
    mov ecx, esi  ; Nom du plus jeune
    call print_str  ; Affiche le nom
    mov ecx, space  ; Espace
    call print_str  ; Imprime l’espace
    mov eax, [esi + 64]  ; Âge du plus jeune
    call print_number  ; Affiche l’âge
    mov ecx, newline  ; Saut de ligne
    call print_str  ; Imprime-le
    jmp main_loop  ; Retour au menu
no_person:
    mov ecx, msg_no_person  ; Message si vide
    call print_str  ; Affiche-le
    jmp main_loop  ; Retour au menu

; Option 5 : Afficher l’âge moyen
age_moyen:
    cmp dword [count], 0  ; Des personnes enregistrées ?
    je no_person_avg  ; Sinon, erreur
    mov esi, personnel  ; Début de la liste
    mov edx, 0  ; Compteur à 0
    mov eax, 0  ; Somme commence à 0
sum_loop:
    cmp edx, [count]  ; Fin de la liste ?
    jge calc_average  ; Si oui, calcule la moyenne
    add eax, [esi + 64]  ; Ajoute l’âge à la somme
    add esi, 68  ; Passe à la suivante
    inc edx  ; Compteur +1
    jmp sum_loop  ; Continue
calc_average:
    mov ebx, [count]  ; Diviseur = nombre de personnes
    xor edx, edx  ; Efface EDX pour la division (sinon ça plante !)
    idiv ebx  ; Divise somme par count, résultat dans EAX
    push eax  ; Sauve la moyenne
    mov ecx, msg_avg  ; Affiche "Age en moyenne:"
    call print_str  ; Imprime-le
    pop eax  ; Récupère la moyenne
    call print_number  ; Affiche la moyenne
    mov ecx, open_paren  ; Parenthèse ouvrante
    call print_str  ; Imprime-la
    mov esi, personnel  ; Recommence pour la liste d’âges
    mov edx, 0  ; Réinitialise le compteur
age_list_loop:
    cmp edx, [count]  ; Fin des âges ?
    jge end_age_list  ; Si oui, termine
    mov eax, [esi + 64]  ; Charge l’âge
    call print_number  ; Affiche-le
    inc edx  ; Compteur +1
    cmp edx, [count]  ; Dernier âge ?
    jge skip_space  ; Si oui, pas d’espace
    mov ecx, space  ; Ajoute un espace
    call print_str  ; Imprime l’espace
skip_space:
    add esi, 68  ; Personne suivante
    jmp age_list_loop  ; Continue
end_age_list:
    mov ecx, close_paren  ; Parenthèse fermante
    call print_str  ; Imprime-la
    jmp main_loop  ; Retour au menu
no_person_avg:
    mov ecx, msg_no_person  ; Message si vide
    call print_str  ; Affiche-le
    jmp main_loop  ; Retour au menu

; Option 6 : Quitter le programme
quitter:
    mov eax, 1  ; Appel système 1 = sortie
    xor ebx, ebx  ; Code de sortie 0
    int 0x80  ; Fin du programme, à bientôt !

; Fonction aide : Traiter l’entrée nom et âge
read_input:
    mov esi, input_buffer  ; Pointe sur l’entrée utilisateur
    mov edi, esi  ; Copie pour le nom
find_space:
    mov al, byte [esi]  ; Prend un caractère
    inc esi  ; Avance
    cmp al, ' '  ; C’est un espace ?
    jne find_space  ; Sinon, cherche encore
    dec esi  ; Recule avant l’espace
    mov byte [esi], 0  ; Termine le nom avec un 0
    inc esi  ; Pointe sur l’âge
    xor eax, eax  ; Réinitialise EAX pour l’âge
    xor ebx, ebx  ; Réinitialise EBX aussi
convert_age:
    mov bl, byte [esi]  ; Prend un chiffre
    cmp bl, 0  ; Fin de l’entrée ?
    je store_entry  ; Si oui, stocke
    cmp bl, 10  ; Saut de ligne ?
    je store_entry  ; Si oui, stocke
    sub bl, '0'  ; Convertit de ASCII à nombre
    imul eax, 10  ; Décale les chiffres précédents
    add eax, ebx  ; Ajoute le nouveau chiffre
    inc esi  ; Caractère suivant
    jmp convert_age  ; Continue
store_entry:
    mov edx, [count]  ; Nombre actuel de personnes
    cmp edx, 10  ; Plus de place ?
    jge exit_read  ; Si oui, sors
    imul edx, 68  ; Calcule l’offset (count * 68)
    push eax  ; Sauve l’âge
    mov edi, personnel  ; Destination dans le tableau
    add edi, edx  ; Pointe sur le nouvel emplacement
    mov esi, input_buffer  ; Source = entrée
    mov ecx, 63  ; Max 63 caractères pour le nom
copy_name:
    mov al, byte [esi]  ; Prend un caractère
    cmp al, 0  ; Fin du nom 
    je name_done  ; Si oui, termine
    mov byte [edi], al  ; Stocke le caractère
    inc esi  ; Caractère suivant source
    inc edi  ; Caractère suivant destination
    dec ecx  ; Un de moins à copier
    jnz copy_name  ; Continue si pas fini
name_done:
    mov byte [edi], 0  ; Termine le nom avec un 0
    pop eax  ; Récupère l’âge
    mov edi, personnel  ; Retour au début
    add edi, edx  ; Pointe sur l’emplacement
    add edi, 64  ; L’âge va 64 octets après
    mov [edi], eax  ; Stocke l’âge
    inc dword [count]  ; Une personne de plus
exit_read:
    ret  ; Fin de la fonction

; Fonction aide : Convertir une chaîne en entier
str_to_int:
    mov esi, input_buffer  ; Pointe sur l’entrée
    xor eax, eax  ; Résultat à 0
    xor ebx, ebx  ; Registre temporaire à 0
convert_loop:
    mov bl, [esi]  ; Prend un chiffre
    cmp bl, 0  ; Fin de la chaîne 
    je convert_done  ; Si oui, termine
    cmp bl, 10  ; Saut de ligne 
    je convert_done  ; Si oui, termine
    sub bl, '0'  ; Convertit en nombre
    imul eax, 10  ; Décale à gauche
    add eax, ebx  ; Ajoute le chiffre
    inc esi  ; Chiffre suivant
    jmp convert_loop  ; Continue
convert_done:
    ret  ; Retourne avec EAX

; Fonction aide : Afficher une chaîne
print_str:
    push eax  ; Sauve EAX
    push ebx  ; Sauve EBX
    push edx  ; Sauve EDX
    mov eax, 4  ; Appel système 4 = écriture
    mov ebx, 1  ; Sortie standard
    mov edx, 0  ; Longueur commence à 0
strlen_loop:
    cmp byte [ecx + edx], 0  ; Fin de la chaîne ?
    je strlen_done  ; Si oui, affiche
    inc edx  ; Caractère suivant
    jmp strlen_loop  ; Continue à compter
strlen_done:
    int 0x80  ; Affiche la chaîne
    pop edx  ; Restaure EDX
    pop ebx  ; Restaure EBX
    pop eax  ; Restaure EAX
    ret  ; Fin de l’affichage

; Fonction aide : Afficher un nombre
print_number:
    push eax  ; Sauve EAX
    push ebx  ; Sauve EBX
    push ecx  ; Sauve ECX
    push edx  ; Sauve EDX
    push esi  ; Sauve ESI
    mov esi, input_buffer + 255  ; Fin du tampon
    mov byte [esi], 0  ; Null-terminate
    mov ebx, 10  ; Diviseur 10
    mov ecx, 0   ; Compteur pour éviter test
convert_num:
    xor edx, edx  ; Efface EDX pour idiv
    idiv ebx      ; Divise EAX par 10, quotient dans EAX, reste dans EDX
    add dl, '0'   ; Convertit le reste en ASCII
    dec esi       ; Recule dans le tampon
    mov [esi], dl ; Stocke le chiffre
    inc ecx       ; Compte les chiffres
    cmp eax, 0    ; Vérifie si quotient = 0
    jne convert_num ; Continue si non zéro
    mov ecx, esi  ; Pointe sur le début du nombre
    call print_str ; Affiche-le
    pop esi       ; Restaure ESI
    pop edx       ; Restaure EDX
    pop ecx       ; Restaure ECX
    pop ebx       ; Restaure EBX
    pop eax       ; Restaure EAX
    ret           ; Fin
