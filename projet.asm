#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>

#include "memoire2.h"
#include "list.h" //vous pouvez remplacer par votre implémentation de liste favorite

enum blocLibre { Libre, Utilise};

struct bloc {
  int debut;
  int taille;
  enum blocLibre drapeau;
};

struct memoire {
  int tailleMot;
  int nbMots;
  list listBlocs;
};

memoire creerMemoire(int tailleMot, int nbMots) {
  // Allouer un espace mémoire pour le bloc principal
  memoire m = malloc(sizeof(struct memoire));
  m->tailleMot = tailleMot;
  m->nbMots = nbMots;
  m->listBlocs = NULL;

  // Créer un bloc libre contenant tous les mots
  struct bloc *b = malloc(sizeof(struct bloc));
  b->debut = 1;
  b->taille = nbMots;
  b->drapeau = Libre;

  // Ajouter ce bloc à la liste des blocs
  m->listBlocs = creer_list(b);

  return m;
}


bloc allocationMemoire(memoire mem, int tailleAAllouer) {
  list l = mem->listBlocs;
  while (l != NULL) {
      struct bloc *b = l->objet;

      // Vérifier si le bloc est libre et assez grand
      if (b->drapeau == Libre && b->taille >= tailleAAllouer) {
          // Allouer la mémoire en coupant le bloc si nécessaire
          if (b->taille > tailleAAllouer) {
              struct bloc *nouveauBloc = malloc(sizeof(struct bloc));
              nouveauBloc->debut = b->debut + tailleAAllouer;
              nouveauBloc->taille = b->taille - tailleAAllouer;
              nouveauBloc->drapeau = Libre;

              b->taille = tailleAAllouer; // Le bloc utilisé a maintenant la taille demandée
              b->drapeau = Utilise;

              // Insérer le nouveau bloc libre dans la liste
              inserer_objet(l, nouveauBloc, 2);  // Insertion après le bloc utilisé
          } else {
              b->drapeau = Utilise; // Bloc entier utilisé
          }

          return b;
      }

      l = l->suivant;
  }

  return NULL; // Pas assez d'espace libre
}


void liberationMemoire(memoire mem, bloc blocALiberer) {
  list l = mem->listBlocs;
  list precedent = NULL;
  while (l != NULL) {
      struct bloc *b = l->objet;
      
      // Vérifier si c'est le bloc à libérer
      if (b == blocALiberer) {
          b->drapeau = Libre;

          // Regrouper les blocs libres adjacents
          if (l->suivant != NULL) {
              struct bloc *next = l->suivant->objet;
              if (next->drapeau == Libre && next->debut == b->debut + b->taille) {
                  // Fusionner les blocs adjacents
                  b->taille += next->taille;
                  l = liberer_objet(l, 2); // Supprimer le bloc suivant
              }
          }
          
          if (precedent != NULL) {
              struct bloc *prev = precedent->objet;
              if (prev->drapeau == Libre && prev->debut + prev->taille == b->debut) {
                  // Fusionner avec le bloc précédent
                  prev->taille += b->taille;
                  l = liberer_objet(l, 1); // Supprimer le bloc actuel
              }
          }

          return;
      }

      precedent = l;
      l = l->suivant;
  }

  fprintf(stderr, "Erreur : Le bloc à libérer n'existe pas.\n");
}

void defragmenterMemoire(memoire mem) {
  list l = mem->listBlocs;
  int adresseCourante = 1; // Adresse de début de la mémoire

  while (l != NULL) {
      struct bloc *b = l->objet;
      
      if (b->drapeau == Utilise) {
          // Déplacer le bloc utilisé au début
          b->debut = adresseCourante;
          adresseCourante += b->taille;
      }
      
      l = l->suivant;
  }
}
