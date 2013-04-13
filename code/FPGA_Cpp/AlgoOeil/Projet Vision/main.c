#include <time.h>
#include <math.h>
#include <stdio.h>    /* Ajouter ...\c6000\cgtools\lib\rts6701.lib  au projet */   
#include "c:\apps\ti\c6000\imglib\include\histogram.h"
#include "defs.h"

#define TAILLE_HISTOGRAMME 256
#define MAX_IMAGE_SIZE 320*251
// 120*120
//#define ID_ZONES

int nbr_pixels;

// pour l'identification de zones
  #define NBR_ZONES_MAX 50
  //int zones_x[NBR_ZONES_MAX];
  //int zones_y[NBR_ZONES_MAX];
  //float zones_taille_zone[NBR_ZONES_MAX];
  //int zones_surface_zone[NBR_ZONES_MAX];
  float zones_rapport[NBR_ZONES_MAX];
  int zones_x_inf[NBR_ZONES_MAX];
  int zones_x_sup[NBR_ZONES_MAX];
  int zones_y_inf[NBR_ZONES_MAX];
  int zones_y_sup[NBR_ZONES_MAX];
  //int zones[NBR_ZONES_MAX]; // numéros des zones pour le tri

/* histogrammes de l'image (pour la recherche du seuil optimal de segmentation) */    
#pragma DATA_ALIGN(histogramme,8);
#pragma DATA_ALIGN(histogramme_cumule,8);
#pragma DATA_ALIGN(histogramme_filtre,8);
unsigned short histogramme[TAILLE_HISTOGRAMME];
unsigned short histogramme_cumule[TAILLE_HISTOGRAMME];
unsigned short histogramme_filtre[TAILLE_HISTOGRAMME];

//short int histogramme2_temp[TAILLE_HISTOGRAMME*4];
//short int histogramme2[TAILLE_HISTOGRAMME];

extern IMAGE_LOCATION unsigned char raster[];
extern short nbr_lignes;
extern short nbr_colonnes;      
extern short diametre_x;
extern short diametre_y;
extern short centre_x_db;
extern short centre_y_db;
extern short num_image;


unsigned char b_inf, b_sup;

int temp;

float centre_x;
float centre_y;

#ifdef CALCULER_IMAGE_SEUILLEE
  //#pragma DATA_ALIGN("image_seuil", 8);
  IMAGE_LOCATION unsigned char image_seuil[MAX_IMAGE_SIZE]; // buffer pour l'image seuillée (taille max fixée)
#endif
#define TAILLE_IMAGE_SOUS_ECH MAX_IMAGE_SIZE/(8*8)
unsigned char image_sous_ech[TAILLE_IMAGE_SOUS_ECH]; // buffer pour l'image sous-ech.
                                                     // taille de bloc de min 4x4
unsigned char image_sous_ech_marque[TAILLE_IMAGE_SOUS_ECH]; // marquage de l'image sous-éch. (permet de voir si on est déjà passé par une case lors du parcours de zone




init_recherche_seuil_optimal() {
/* ------------------------------------------------
 * Initialisation de la recherche du seuil optimal
 * pour la segmentation de l'image.
 *
 * Les opérations suivantes sont effectuées :
 *     1) calcul de l'histogramme de l'image
 *     2) calcul de l'histogramme cumulé
 *     3) filtrage de l'histogramme (médian + passe-bas)
 *
 * Input :
 *   raster (contient les pixels de l'image)
 *   nbr_lignes
 *   nbr_colonnes
 * Output : 
 *   -
 * Modifies :
 *   histogramme[] : histogramme filtré
 *   histogramme_cumule[] : histogramme cumulé
 *   histogramme_filtre[] : histogramme filtré médian uniquement (var. tempopraire)
 */                      

/* Versions d'algorithmes (par ordre de vitesse croissante) :
     HISTO       : 1..3  (versions 2 et 3 pas identiques à la 1 pour les images 27 et 30)
     CUMUL_HISTO : 1..4
     PASSE_BAS   : 1..3
*/ 
 #define ALGO_VERSION_HISTO       3
 #define ALGO_VERSION_CUMUL_HISTO 4
 #define ALGO_VERSION_PASSE_BAS   3
 
 /* définition des données pour les filtres */
 #define ORDRE_FILTRE_MEDIAN 5
 #define ORDRE_FILTRE_PASSE_BAS 3
 #define ORDRE_FILTRE_PASSE_BAS_UPPER_POW2 4
 #define ORDRE_FILTRE_MEDIAN_DIV2 ORDRE_FILTRE_MEDIAN / 2
 #define ORDRE_FILTRE_PASSE_BAS_DIV2 ORDRE_FILTRE_PASSE_BAS / 2
 
 /* variables locales */
 //unsigned int nbr_pixels_8; // nombre de pixels multiple de 8 

 // variables pour le calcul de l'histogramme
 #if   ALGO_VERSION_HISTO==3
   int n_histo; // compteur de boucles
   unsigned int word1;
   unsigned char i1_1, i1_2, i1_3, i1_4;
   unsigned int* raster_temp;
   unsigned int h1,h2,h3,h4;
 #elif ALGO_VERSION_HISTO==2
   int n_histo; // compteur de boucles
   unsigned int word1, word2;
   unsigned char i1_1, i1_2, i1_3, i1_4;
   unsigned char i2_1, i2_2, i2_3, i2_4;
   unsigned int* raster_temp;  // adresse des 8 pixels à transférer
   unsigned int h1,h2,h3,h4,h5,h6,h7,h8;
 #elif ALGO_VERSION_HISTO==1
   int n_histo; // compteur de boucles
   unsigned char pixel;  // couleur du pixel courant
 #endif


 // variables pour le calcul de l'histogramme cumulé
 #if   ALGO_VERSION_CUMUL_HISTO==4
   int n_cumul; // compteur de boucles
   unsigned short somme_cumulee; // nombre de pixels cumule
   unsigned short s0,s1,s2,s3,ss0;
 #elif ALGO_VERSION_CUMUL_HISTO==3
   int n_cumul; // compteur de boucles
   unsigned short somme_cumulee; // nombre de pixels cumule
   unsigned short s0,s1,s2,s3;
 #elif ALGO_VERSION_CUMUL_HISTO==2
   int n_cumul; // compteur de boucles
   unsigned short somme_cumulee; // nombre de pixels cumule
 #elif ALGO_VERSION_CUMUL_HISTO==1
   int n_cumul; // compteur de boucles
 #endif

 
 // variables pour le filtre médian
 #if ORDRE_FILTRE_MEDIAN==5
    // code spécial pour le filtre médian d'ordre 5 (plus efficace)
    int n_median; // compteur de boucles
    unsigned short r0,r1,r2,r3,r4,r5,r10; // pour le median
    unsigned short min01234, max; // pour le median
 #else
   unsigned char  k,m; /* compteur de boucles pour le median */
   unsigned short filtre_median[ORDRE_FILTRE_MEDIAN];
   unsigned short temp_median; // variable d'échange du filtre median
   unsigned int   index;  // pour le calcul du filtre median
 #endif


 // variables pour le filtre passe-bas
 #if   ALGO_VERSION_PASSE_BAS==3
   int n_passe_bas; // compteur de boucle
   unsigned short somme_passe_bas; // somme pour la moyenne
   unsigned int next_to_remove1; // pour le calcul du filtre passe-bas
   unsigned int next_to_remove2; // pour le calcul du filtre passe-bas
   unsigned int next_to_remove3; // pour le calcul du filtre passe-bas
   unsigned int next_to_remove4; // pour le calcul du filtre passe-bas
 #elif ALGO_VERSION_PASSE_BAS==2
   int n_passe_bas; // compteur de boucle
   unsigned short somme_passe_bas; // somme pour la moyenne
   unsigned int next_to_remove; // prochain nombre à retirer de la somme
 #elif ALGO_VERSION_PASSE_BAS==1
   int n_passe_bas; // compteur de boucle
   int j; // compteur de boucles
   unsigned short somme_passe_bas; // somme pour la moyenne
 #endif  



  /* calcul de l'histogramme
     ----------------------- */
  #if ALGO_VERSION_HISTO==3
  // v3 : 33166 cycles (130x96) (déroulement de boucle 4x)
  for (n_histo=TAILLE_HISTOGRAMME-1; n_histo>=0; n_histo--) histogramme[n_histo]=0;
  raster_temp=(unsigned int*)raster;  
  for (n_histo=0; n_histo<nbr_pixels/4; n_histo++) {
    word1 = raster_temp[0];
    raster_temp++;
    i1_1 = (word1     ) & 0xFF;
    i1_2 = (word1 >>8 ) & 0xFF;
    i1_3 = (word1 >>16) & 0xFF;
    i1_4 = (word1 >>24)       ;
    h1 = histogramme[i1_1];
    h2 = histogramme[i1_2];
    h3 = histogramme[i1_3];
    h4 = histogramme[i1_4];
    histogramme[i1_1] = h1+1;
    histogramme[i1_2] = h2+1;
    histogramme[i1_3] = h3+1;
    histogramme[i1_4] = h4+1;
  }
  // finir avec les 0 à 3 derniers pixels de l'image (pas obligatoire puisqu'la pupille n'y est certainement pas)
  /*index_dernier_pixel = (nbr_pixels>>2)<<2;
  for (n_histo=index_dernier_pixel; n_histo<nbr_pixels; n_histo++) {
    histogramme[raster[n_histo]]++;
  } */

  #elif ALGO_VERSION_HISTO==2
  // v2 : 34751 cycles (130x96) (déroulement de boucle 8x)
  for (n_histo=TAILLE_HISTOGRAMME-1; n_histo>=0; n_histo--) histogramme[n_histo]=0;
  raster_temp = (unsigned int*)raster;
  // ATTENTION : il faudrait prendre en compte tous les pixels (ici les 0..7 derniers pixels ne sont pas pris en compte, suivant le nombre de pixels de l'image)
  for (n_histo = 0; n_histo<nbr_pixels/8; n_histo++) { // calcul de l'histogramme (lecture de 8 pixels à la fois)
    word1 = raster_temp[0]; // lecture des 4 premiers pixels
    word2 = raster_temp[1]; // lecture des 4 seconds pixels (en //)
    raster_temp += 2;
    i1_1 = (word1     ) & 0xFF; // extraction des 8 pixels
    i1_2 = (word1 >>8 ) & 0xFF;
    i1_3 = (word1 >>16) & 0xFF;
    i1_4 = (word1 >>24)       ;
    i2_1 = (word2     ) & 0xFF;
    i2_2 = (word2 >>8 ) & 0xFF;
    i2_3 = (word2 >>16) & 0xFF;
    i2_4 = (word2 >>24)       ;

    h1 = histogramme[i1_1]; // mise à jour de l'histogramme (pas de ++ pour maximiser le //)
    h2 = histogramme[i1_2];
    h3 = histogramme[i1_3];
    h4 = histogramme[i1_4];
    histogramme[i1_1] = h1+1;
    histogramme[i1_2] = h2+1;
    histogramme[i1_3] = h3+1;
    histogramme[i1_4] = h4+1;
    h5 = histogramme[i2_1];
    h6 = histogramme[i2_2];
    h7 = histogramme[i2_3];
    h8 = histogramme[i2_4];
    histogramme[i2_1] = h5+1;
    histogramme[i2_2] = h6+1;
    histogramme[i2_3] = h7+1;
    histogramme[i2_4] = h8+1;     
  }

  
  #elif ALGO_VERSION_HISTO==1
  // v1 : 89304 cycles (130x96)
  for (n_histo=TAILLE_HISTOGRAMME-1; n_histo>=0; n_histo--) histogramme[n_histo]=0;
  for (n_histo = 0; n_histo<nbr_pixels; n_histo++) {
    pixel = raster[n_histo];
    histogramme[pixel]=histogramme[pixel]+1;   //  pas de changement avec a=a+1
  }         
  #endif

  /*
  // Ca fait planter le debugger (crash)
  for (n=TAILLE_HISTOGRAMME*4-1; n>=0; n--) histogramme2_temp[n]=0;
  nbr_pixels_8 = ((nbr_pixels+7)/8)*8; // rendre nbr_pixels multiple de 8
  histogram(raster, nbr_pixels_8, +1, histogramme2, histogramme2_temp);
  */


  /* calcul de l'histogramme cumulé
     ------------------------------ */
  #if ALGO_VERSION_CUMUL_HISTO==4
  // v4 : 569 cycles (déroulement de boucle+optimisation des sommes)
  somme_cumulee=0;
  for (n_cumul=0; n_cumul<TAILLE_HISTOGRAMME; n_cumul+=4) {
    s0 = histogramme[n_cumul+0];
    s1 = histogramme[n_cumul+1];
    s2 = histogramme[n_cumul+2];
    s3 = histogramme[n_cumul+3];  
    ss0 = somme_cumulee+s0;    
    histogramme_cumule[n_cumul+0]=ss0;
    histogramme_cumule[n_cumul+1]=ss0+s1;
    histogramme_cumule[n_cumul+2]=ss0+s1+s2;
    histogramme_cumule[n_cumul+3]=ss0+s1+s2+s3;
    somme_cumulee = ss0+s1+s2+s3;
  }


  #elif ALGO_VERSION_CUMUL_HISTO==3
  // v3 : 570 cycles (déroulement de boucle)
  somme_cumulee=0;
  for (n_cumul=0; n_cumul<TAILLE_HISTOGRAMME; n_cumul+=4) {
    s0 = histogramme[n_cumul+0];
    s1 = histogramme[n_cumul+1];
    s2 = histogramme[n_cumul+2];
    s3 = histogramme[n_cumul+3];
    histogramme_cumule[n_cumul+0]=somme_cumulee+s0;
    histogramme_cumule[n_cumul+1]=somme_cumulee+s0+s1;
    histogramme_cumule[n_cumul+2]=somme_cumulee+s0+s1+s2;
    histogramme_cumule[n_cumul+3]=somme_cumulee+s0+s1+s2+s3;
    somme_cumulee += s0+s1+s2+s3;
  }


  #elif ALGO_VERSION_CUMUL_HISTO==2
  // v2 : 572 cycles (somme cumulée en registre)
  somme_cumulee=0;
  for (n_cumul=0; n_cumul<TAILLE_HISTOGRAMME; n_cumul++) {
    somme_cumulee += histogramme[n_cumul];
    histogramme_cumule[n_cumul]=somme_cumulee;
  }


  #elif ALGO_VERSION_CUMUL_HISTO==1
  // v1 : 1919 cycles
  histogramme_cumule[0]=histogramme[0];
  for (n_cumul=1; n_cumul<TAILLE_HISTOGRAMME; n_cumul++) {
    histogramme_cumule[n_cumul]=histogramme_cumule[n_cumul-1]+histogramme[n_cumul];
  }
  #endif


  /* filtre médian */
  #if ORDRE_FILTRE_MEDIAN==5
  // v2 : 21370 cycles (déroulement de boucle pour n=5)
  for (n_median=0; n_median<ORDRE_FILTRE_MEDIAN_DIV2; n_median++) histogramme_filtre[n_median]=0;
  for (n_median=TAILLE_HISTOGRAMME-ORDRE_FILTRE_MEDIAN_DIV2; n_median<TAILLE_HISTOGRAMME; n_median++) histogramme_filtre[n_median]=0;
  r0=histogramme[0];
  r1=histogramme[1];
  r2=histogramme[2];
  r3=histogramme[3];
  r4=histogramme[4];
  for (n_median=ORDRE_FILTRE_MEDIAN_DIV2; n_median<TAILLE_HISTOGRAMME-ORDRE_FILTRE_MEDIAN_DIV2; n_median++) {
    //copie des valeurs
    r5=histogramme[n_median+4-ORDRE_FILTRE_MEDIAN_DIV2];
    r10=0; // nbr de valeurs triées
    
    //tri des valeurs
    // recherche de la 1ère plus petite valeur
    //max=0; // max est la valeur de la 1ère case
    min01234=r0;
    if (r1<=min01234) min01234 = r1;
    if (r2<=min01234) min01234 = r2;
    if (r3<=min01234) min01234 = r3;
    if (r4<=min01234) min01234 = r4;
    if (r0==min01234) r10++;
    if (r1==min01234) r10++;
    if (r2==min01234) r10++;
    if (r3==min01234) r10++;
    if (r4==min01234) r10++;
                                         //min01234 est la plus petite valeur du tableau
                                         // donc elle devrait aller dans la 1ère case
    // recherche de la 2ème plus petite valeur
    if (r10<=2) {
      max=min01234; // max est la valeur de la 1ère case
      min01234=0xFFFF;
      if ((r0>max) && (r0<=min01234)) min01234 = r0;
      if ((r1>max) && (r1<=min01234)) min01234 = r1;
      if ((r2>max) && (r2<=min01234)) min01234 = r2;
      if ((r3>max) && (r3<=min01234)) min01234 = r3;
      if ((r4>max) && (r4<=min01234)) min01234 = r4;
      if (r0==min01234) r10++;
      if (r1==min01234) r10++;
      if (r2==min01234) r10++;
      if (r3==min01234) r10++;
      if (r4==min01234) r10++;
                               // min01234 est maintenant la 2ème plus petite valeur du tableau
                               // donc elle devrait aller dans la 2ème case
      // recherche de la 3ème plus petite valeur du tableau
      if (r10<=2) {
        max=min01234; // max est la valeur de la 2ère case
        min01234=0xFFFF;
        if ((r0>max) && (r0<=min01234)) min01234 = r0;
        if ((r1>max) && (r1<=min01234)) min01234 = r1;
        if ((r2>max) && (r2<=min01234)) min01234 = r2;
        if ((r3>max) && (r3<=min01234)) min01234 = r3;
        if ((r4>max) && (r4<=min01234)) min01234 = r4;
                                // min01234 est maintenant la 3ème plus petite valeur du tableau
                                // donc elle devrait aller dans la troisièème case
      }//end if
    }//end if        
    
    // décalage des valeurs pour le prochain bin de l'histogramme
    r0=r1;
    r1=r2;
    r2=r3;
    r3=r4;
    r4=r5;                                                       
    
    histogramme_filtre[n_median]=min01234; // pour un filtre médian n=5, la case du milieu est la 3ème CQFD
  }//end for


  #else   // filtre médian d'ordre != 5   
  // v1 : 35324 cycles (tri à bulles)
  for (i=0; i<ORDRE_FILTRE_MEDIAN_DIV2; i++) histogramme_filtre[i]=0;
  for (n=TAILLE_HISTOGRAMME-ORDRE_FILTRE_MEDIAN_DIV2; n<TAILLE_HISTOGRAMME; n++) histogramme_filtre[n]=0;
  for (i=ORDRE_FILTRE_MEDIAN_DIV2; i<TAILLE_HISTOGRAMME-ORDRE_FILTRE_MEDIAN_DIV2; i++) {
    //copie des valeurs
    for (j=0; j<ORDRE_FILTRE_MEDIAN; j++) {
      index = i+j-ORDRE_FILTRE_MEDIAN_DIV2;
      temp_median = histogramme[index];
      filtre_median[j]=temp_median;
    }//end for
    //tri des valeurs (juste la moitié, ça suffit puisqu'on prend l'élément milieu)
    for (k=0; k<ORDRE_FILTRE_MEDIAN_DIV2; k++) {
      for (m=k+1; m<ORDRE_FILTRE_MEDIAN; m++) {
        if (filtre_median[m]<filtre_median[k]) {
          // échange des valeurs
          temp_median = filtre_median[k];
          filtre_median[k] = filtre_median[m];
          filtre_median[m] = temp_median;
        }
      }
    }
    histogramme_filtre[i]=filtre_median[ORDRE_FILTRE_MEDIAN_DIV2]; //filtre médian
  }//end for
  #endif

  

  /* filtre passe-bas (moyenne)
     -------------------------- */
  #if ALGO_VERSION_PASSE_BAS==3
  // v3 : 873 cycles (déroulement de boucle pour n=3)
  #if ORDRE_FILTRE_PASSE_BAS_DIV_2==1
  // pour le filtre d'ordre 3, il n'y a pas besoin de boucle
  histogramme[0]=0;
  histogramme[255]=0;
  #else
  for (n_passe_bas=0; n_passe_bas<ORDRE_FILTRE_PASSE_BAS_DIV2; n_passe_bas++) histogramme[n_passe_bas]=0;
  for (n_passe_bas=(TAILLE_HISTOGRAMME-ORDRE_FILTRE_PASSE_BAS_DIV2); n_passe_bas<TAILLE_HISTOGRAMME; n_passe_bas++) histogramme[n_passe_bas]=0;
  #endif
  next_to_remove1 = histogramme_filtre[0];
  next_to_remove2 = histogramme_filtre[1];
  next_to_remove3 = histogramme_filtre[2];
  somme_passe_bas = next_to_remove1+next_to_remove1+next_to_remove2;
  for (n_passe_bas=ORDRE_FILTRE_PASSE_BAS_DIV2; n_passe_bas<(TAILLE_HISTOGRAMME-ORDRE_FILTRE_PASSE_BAS_DIV2); n_passe_bas++) {
    next_to_remove4 = histogramme_filtre[n_passe_bas+ORDRE_FILTRE_PASSE_BAS_DIV2];
    somme_passe_bas += next_to_remove3;
    somme_passe_bas -= next_to_remove1;
    next_to_remove1 = next_to_remove2;
    next_to_remove2 = next_to_remove3;
    next_to_remove3 = next_to_remove4;
    histogramme[n_passe_bas]=somme_passe_bas;
  }//end for
  
  
  #elif ALGO_VERSION_PASSE_BAS==2
  // v2 : 890 cycles
  somme_passe_bas = histogramme_filtre[0];
  next_to_remove = histogramme_filtre[0];
  for (n_passe_bas=0; n_passe_bas<ORDRE_FILTRE_PASSE_BAS-1; n_passe_bas++) { // initialiser le filtre (somme des n premiers éléments)
      somme_passe_bas += histogramme_filtre[n_passe_bas];
  }//end for                          
  // maintenant : somme_passe_bas = 2*h[0]+h[1..n-2]
  #if ORDRE_FILTRE_PASSE_BAS_DIV_2==1
  // pour le filtre d'ordre 3, il n'y a pas besoin de boucle
  histogramme[0]=0;
  histogramme[255]=0;
  #else
  for (n_passe_bas=0; n_passe_bas<ORDRE_FILTRE_PASSE_BAS_DIV2; n_passe_bas++) histogramme[n_passe_bas]=0;
  for (n_passe_bas=(TAILLE_HISTOGRAMME-ORDRE_FILTRE_PASSE_BAS_DIV2); n_passe_bas<TAILLE_HISTOGRAMME; n_passe_bas++) histogramme[n_passe_bas]=0;
  #endif
  for (n_passe_bas=ORDRE_FILTRE_PASSE_BAS_DIV2; n_passe_bas<(TAILLE_HISTOGRAMME-ORDRE_FILTRE_PASSE_BAS_DIV2); n_passe_bas++) {
    // somme des échantillons
    somme_passe_bas+=histogramme_filtre[n_passe_bas+ORDRE_FILTRE_PASSE_BAS_DIV2-1]; // on ajoute le nouvel élément de la moyenne
    somme_passe_bas-=next_to_remove; // on enlève le plus ancien élément de la moyenne
    next_to_remove = histogramme_filtre[n_passe_bas-ORDRE_FILTRE_PASSE_BAS_DIV2];
    histogramme[n_passe_bas]=(somme_passe_bas+ORDRE_FILTRE_PASSE_BAS-1)/ORDRE_FILTRE_PASSE_BAS_UPPER_POW2;  //filtre passe bas (+ordre_filtre_passe_bas-1 pour arrondir à 1)
      // on divise par une puissance de 2 parce que du point de vue de l'histogramme, ça ne change rien (histogramme plus tassé)
      // par contre, la division est remplacée par un shift => plus rapide
  }//end for

    
  #elif ALGO_VERSION_PASSE_BAS==1
  // v1 : 9552 cycles
  for (n_passe_bas=ORDRE_FILTRE_PASSE_BAS_DIV2; n_passe_bas<(TAILLE_HISTOGRAMME-ORDRE_FILTRE_PASSE_BAS_DIV2); n_passe_bas++) {
    // somme des échantillons
    somme_passe_bas=0;
    for (j=-ORDRE_FILTRE_PASSE_BAS_DIV2; j<=ORDRE_FILTRE_PASSE_BAS_DIV2; j++) {
      somme_passe_bas += histogramme_filtre[n_passe_bas+j];
    }//end for
    histogramme[n_passe_bas]=(somme_passe_bas+ORDRE_FILTRE_PASSE_BAS-1)/ORDRE_FILTRE_PASSE_BAS;  //filtre passe bas (+ordre_filtre_passe_bas-1 pour arrondir à 1)
  }//end for
  #endif
}/* -----------------------------------------------------
end init_recherche_seuil_optimal */




           
           
           
im_hist_get_lobe(unsigned short* histogramme,
                 unsigned char num_lobe,
                 unsigned char sens,
                 unsigned char* b_inf,
                 unsigned char* b_sup) {
/* ---------------------------------------------------------------------
 * retourne les bornes du lobe spécifié
 * init_recherche_seuil_optimal() doit avoir ete appelé avant
 *
 * Input : 
 *   paramètres de la fonction
 * Output :
 *   histogramme (modifié)
 *   b_sup         
 *   b_inf
  */
  unsigned short i;
  unsigned char num_lobe_int; // compteur de lobe

  if (sens==0) {
    // recherche du lobe depuis la couleur 0 de l'histogramme

    // filtrage des couleurs non significatives (nbr de pixels trop faibles)
    for (i=0; i<TAILLE_HISTOGRAMME; i++) {  // 279 cycles
      if (histogramme[i]<=1) histogramme[i] = 0;
    }//end for
  
    //recherche du début du premier lobe (gradient!=0)
    i=0;
    while (histogramme[i]==0) {
      i++;
    }//end while
  
    // recherche du n-ème lobe
    for (num_lobe_int=num_lobe; num_lobe_int>0; num_lobe_int--) {
      *b_inf = i-1; // début du lobe
   
      // recherche du sommet du lobe (montée)
      while (i<256 && histogramme[i]>=histogramme[i-1]) {
        i++;
      }//end while
      // recherche de la fin du lobe (descente)
      while (i<256 && histogramme[i]<histogramme[i-1]) { 
        i++;
      }//end while
      *b_sup = i-1; // fin du lobe
    }//end while

   
  } else {
    // recherche du lobe à partir de la couleur 255->0
    ////////////////////////////////////////////////////////////////////////
 
    // correction d'histogramme nécessaire car les lampes sont souvent petites (i.e. peu de pixels)
    for (i=0; i<TAILLE_HISTOGRAMME; i++) {
      if (histogramme[i]!=0) {
        if (histogramme[i]<=6) {
          histogramme[i]=6;
        }//end if
      }//end if
    }//end for

    // recherche du début du premier lobe
    i=254;  // fin de l'histogramme 
    while (histogramme[i]==0) {
      i--;
    }//end while

    // recherche du n-ème lobe
    num_lobe_int = 1;
    while (num_lobe_int<=num_lobe) {
      *b_sup = i+1; // début du lobe
        // recherche du sommet du lobe (montée)
      while (i>0 && histogramme[i]>=histogramme[i+1]) {
        i--;
      }//end while
      // recherche de la fin du lobe (descente)
      while (i>0 && histogramme[i]<histogramme[i+1]) {
        i--;
      }//end while
      *b_inf = i+1;
  
      // passer au lobe suivant
      num_lobe_int++;
    }//end while

  }//end if
    
}/* ---------------------------------------------------------------------------
end im_hist_get_lobe */









calculer_seuil_optimal(unsigned char* b_inf,
                       unsigned char* b_sup) {
/* -----------------------------------------------------------------------------
 * Calcul du seuil optimal pour la segmentation de l'image à partir
 * de l'histogramme cumulé et des bornes du premier lobe.
 *
 * Procède de manière dichotomique jusqu'à optiner une image seuillée contenant
 * moins de 10% des pixels à '1'.
 *
 * Input : 
 *   paramètres : b_inf, b_sup
 *   var. globales : nbr_lignes, nbr_colonnes, histogramme_cumule
 * Output :
 *   b_inf_out, b_sup_out
 */
  unsigned int limite = nbr_lignes*nbr_colonnes/10; // limite = 10 % des pixels
  short m, m2; // index de couleur du point milieu (pour la dichotomie)
  unsigned char b_inf2, b_sup2; // index de couleur pour la dichotomie
  char i; // compteur de boucle
  
  // correction du seuil (pour les images mal illuminées)
  //image mal illuminée : plus de x pixels<seuil (x est défini en % de la taille de l'image)
  b_inf2 = *b_inf;
  b_sup2 = *b_sup;
  
  m = -1;
  for (i=7; i>0; i--) {  // max 7 dichotomies car couleur_max=env 128 et 2^7=128
    m2 = m;
    m=(b_sup2+b_inf2+1)/2; // +1 pour l'arrondi
    if (m==m2) break; // le seuil n'a pas changé => on le garde
    if ((histogramme_cumule[m]-histogramme_cumule[*b_inf])>limite) {
      // on est en dessus de la limite
      b_sup2 = m;
      //System.out.println((histogramme_cumule[m]-histogramme_cumule[*b_inf])+" pixels sous le seuil indiqué");
    } else {
      if ((histogramme_cumule[m]-histogramme_cumule[*b_inf])<limite) {
        // on est en dessous de la limite
        b_inf2 = m;
        //System.out.println((h_cumul[m]-h_cumul[*b_inf])+" pixels sous le seuil indiqué");
      } else {
        // on est au bon compte => OK
        break;
      }//end if
    }//end if
  }//end for
  *b_sup = m;
  //System.out.println(histogramme_cumule[*b_sup]+" pixels sous le seuil indiqué");
}/* ---------------------------------------------------------------------
end calculer_seuil_optimal */


                                                     
                                                     
                                                     


seuillage(unsigned char* image,
          unsigned char* image_seuillee,
          unsigned int   n,
          unsigned char  seuil) {
/* ------------------------------------------------------------------------
 * Effectue le seuillage de l'image. ('image seuillee' a les pixels à '1'
 * pour toutes les couleurs < 'seuil').
 * 'n' est le nombre de pixels de l'image         
 */
 unsigned int i;

 for (i=0; i<n; i++) {
   image_seuillee[i]=image[i]<seuil; // 1 si image[0]<seuil, 0 sinon
 }
}/* ----------------------------------------------------------------------
end seuillage */


                                                   
                                                   
                                                   



get_barycentre(unsigned char* image_seuil,      
               short nbr_colonnes,
               short nbr_lignes,
               short x_inf,
               short x_sup,
               short y_inf,
               short y_sup,
               float* centre_x,
               float* centre_y) {
/* ----------------------------------------------------------------------------
 * calcule le barycentre entre les pixels (x_inf, y_inf) et (x_sup, y_sup)
 * Le centre calculé est donné dans (centre_x, centre_y)
 */

  // variables
  int somme_x = 0; // somme des coordonnées X des pixels à '1'
  int somme_y = 0; // somme des coordonnées Y des pixels à '1'
  int nbr_pixels = 0; // nombre de pixels à '1' sur l'image
  int num_colonne, num_ligne; // compteurs de boucles
  int i; // index du pixel                  
  
  i = y_inf * nbr_colonnes;
  for (num_ligne=y_inf; num_ligne<y_sup; num_ligne++) {
    for (num_colonne=x_inf; num_colonne<x_sup; num_colonne++) {
      if (image_seuil[i+num_colonne]==1) {
        somme_x += num_colonne;
        somme_y += num_ligne;
        nbr_pixels++;
      }//end if
    }//end for (num_colonne)
    i += nbr_colonnes; // passer à la ligne suivante
  }//end for (num_lignes)
                          
  if (nbr_pixels == 0) {
    // aucun pixel dans l'image => centre = [-1 -1]  (sinon il y a une division par 0)
    *centre_x = -1;
    *centre_y = -1;
  } else {
    // calcul du centre
    *centre_x = (float)somme_x / (float)nbr_pixels;
    *centre_y = (float)somme_y / (float)nbr_pixels;
  }//end if

}/* -------------------------------------------------------------------------
end get_barycentre */








get_barycentre_seuil(unsigned char* image,      
               short nbr_colonnes,
               short nbr_lignes,
               short x_inf,
               short x_sup,
               short y_inf,
               short y_sup,
               float* centre_x,
               float* centre_y,
               unsigned char seuil) {
/* ----------------------------------------------------------------------------
 * calcule le barycentre entre les pixels (x_inf, y_inf) et (x_sup, y_sup)
 * Le centre calculé est donné dans (centre_x, centre_y)
 *
 * Le calcul ne se fait pas sur l'image seuillée mais sur l'image originale 
 * avec indication du seuil
 */

  // variables
  int somme_x = 0; // somme des coordonnées X des pixels à '1'
  int somme_y = 0; // somme des coordonnées Y des pixels à '1'
  int nbr_pixels = 0; // nombre de pixels à '1' sur l'image
  int num_colonne, num_ligne; // compteurs de boucles
  int i; // index du pixel

 
/*  
  unsigned int* raster_temp;                  
  unsigned int word1;       
  unsigned char i1_1, i1_2, i1_3, i1_4;
  unsigned int inc_x;
  unsigned int cmp1, cmp2, cmp3, cmp4;

  i = y_inf * nbr_colonnes;
  // x_inf/sup doivent être multiples de 8
  x_inf = x_inf/4;
  x_sup = x_sup/4;
  for (num_ligne=y_inf; num_ligne<y_sup; num_ligne++) {
    raster_temp = (unsigned int*)raster + i;
    for (num_colonne=x_inf; num_colonne<x_sup; num_colonne++) {
      word1 = raster_temp[0];
      raster_temp++;             
      inc_x = num_colonne*4;
      i1_1 = (word1     ) & 0xFF; // extraction des 8 pixels
      i1_2 = (word1 >>8 ) & 0xFF;
      i1_3 = (word1 >>16) & 0xFF;
      i1_4 = (word1 >>24)       ;
      cmp1 = i1_1 < seuil;
      cmp2 = i1_2 < seuil;
      cmp3 = i1_3 < seuil;
      cmp4 = i1_4 < seuil;
      if (cmp1) {
        somme_x += inc_x+0;
        somme_y += num_ligne;
        nbr_pixels++;
      }//end if
      if (cmp2) {
        somme_x += inc_x+1;
        somme_y += num_ligne;
        nbr_pixels++;
      }//end if
      if (cmp3) {
        somme_x += inc_x+2;
        somme_y += num_ligne;
        nbr_pixels++;
      }//end if
      if (cmp4) {
        somme_x += inc_x+3;
        somme_y += num_ligne;
        nbr_pixels++;
      }//end if
    }//end for (num_colonne)
    i += nbr_colonnes; // passer à la ligne suivante
  }//end for (num_lignes)
*/

  i = y_inf * nbr_colonnes;
  for (num_ligne=y_inf; num_ligne<y_sup; num_ligne++) {
    for (num_colonne=x_inf; num_colonne<x_sup; num_colonne++) {
      if (image[i+num_colonne]<seuil) {
        somme_x += num_colonne;
        somme_y += num_ligne;
        nbr_pixels++;
      }//end if
    }//end for (num_colonne)
    i += nbr_colonnes; // passer à la ligne suivante
  }//end for (num_lignes)

  if (nbr_pixels == 0) {
    // aucun pixel dans l'image => centre = [-1 -1]  (sinon il y a une division par 0)
    *centre_x = -1;
    *centre_y = -1;
  } else {
    // calcul du centre
    *centre_x = (float)somme_x / (float)nbr_pixels;
    *centre_y = (float)somme_y / (float)nbr_pixels;
  }//end if

}/* -------------------------------------------------------------------------
end get_barycentre_seuil */













add_ligne(unsigned char* image_sous_ech, unsigned char* image_sous_ech_marque,
          unsigned int Xm, unsigned int Ym,
          int x, int y,
          unsigned int  x_inf,  unsigned int  x_sup,  unsigned int  y_inf,  unsigned int  y_sup,
          unsigned int* x_inf2, unsigned int* x_sup2, unsigned int* y_inf2, unsigned int* y_sup2,
          int* surface_zone) {
/* -----------------------------------------------------------------------------
*/
    // retourne [x_inf x_sup y_inf y_sup surface_zone] 
    //System.out.println("  add_ligne("+x+" "+y+")");
    int xmin=x;
    int xmax=x;
    int xx; // index x du pixel voisin d'une nouvelle ligne (plus haute ou plus basse)
    int surface_haut, surface_bas; // surface en haut/en bas de la la ligne courante

    
    //recherche de la borne gauche de la ligne
    while (image_sous_ech[xmin+Xm*y]==1 && image_sous_ech_marque[xmin+Xm*y]==0) {
      image_sous_ech_marque[xmin+Xm*y]=1;
      xmin--;
      if (xmin<0) break;
    }//end while
    xmin++;

    //recherche de la borne droite de la ligne
    image_sous_ech_marque[xmax+Xm*y]=0;
    while (image_sous_ech[xmax+Xm*y]==1 && image_sous_ech_marque[xmax+Xm*y]==0) {
      image_sous_ech_marque[xmax+Xm*y]=1;
      xmax++;
      if (xmax>=Xm) break;
    }//end while
    xmax--;


    *surface_zone = xmax-xmin+1;
    //System.out.println("  xmin="+xmin+" xmax="+xmax+" longueur_ligne="+surface_zone);

    //System.out.println(x_inf+" "+x_sup+" "+y_inf+" "+y_sup);
    //System.out.println(xmin+" "+xmax+" "+y+" "+y);

    //calcul des bornes de la zone
    if (xmax>x_sup) x_sup=xmax;
    if (xmin<x_inf) x_inf=xmin;
    if (y>y_sup) y_sup=y;
    if (y<y_inf) y_inf=y;

    //System.out.println(x_inf+" "+x_sup+" "+y_inf+" "+y_sup);
    
    // toute la ligne est maintenant marquée. On va la parcourir pour essayer
    // de trouver un pixel au dessus ou au dessous qui ne soit pas marqué, ce
    // qui permettra de trouver une autre ligne
    xx = xmin;
    while (xx<=xmax) {
      if (y-1>=0) {
        if (image_sous_ech_marque[xx+Xm*(y-1)]==0 && image_sous_ech[xx+Xm*(y-1)]==1) {
          add_ligne(image_sous_ech, image_sous_ech_marque, 
                    Xm, Ym,
                    xx,y-1,
                    x_inf,   x_sup,  y_inf,  y_sup,
                    &x_inf, &x_sup, &y_inf, &y_sup,
                    &surface_haut);
          *surface_zone += surface_haut;
        }//end if
      }//end if
      if (y+1<Ym) {
        if (image_sous_ech_marque[xx+Xm*(y+1)]==0 && image_sous_ech[xx+Xm*(y+1)]==1) {
          add_ligne(image_sous_ech, image_sous_ech_marque, 
                    Xm, Ym,
                    xx,y+1,
                    x_inf,   x_sup,  y_inf,  y_sup,
                    &x_inf, &x_sup, &y_inf, &y_sup,
                    &surface_bas);
          *surface_zone += surface_bas;
        }//end if
      }//end if
      xx += 1;
    }//end while

  *x_inf2 = x_inf;
  *x_sup2 = x_sup;
  *y_inf2 = y_inf;
  *y_sup2 = y_sup;


    //System.out.println("result="+x_inf+" "+x_sup+" "+y_inf+" "+y_sup);
}/* ---------------------------------------------------------------------------
end add_ligne */





            
            
get_barycentre_id_zones(unsigned char* A,
                        unsigned char seuil,
                        float* centre_x,
                        float* centre_y) {
/* -----------------------------------------------------------------------------
 * Recherche du barycentre mais avec une identification de zones préalable
 *
 * Le nombre de zones maximal est spécifié par NBR_ZONES_MAX. Si l'image
 * sous-échantillonnée contient davantage de zones, les moins bonnes zones
 * sont remplacées (l'algorithme est dans ce cas plus lent puisqu'il faut 
 * rechercher les zones à remplacer). Par conséquent, si il y a suffisamment
 * de mémoire, il y a intérêt à avoir un nombre de zones potentielles le plus
 * grand possible.
 */                     
  // taille_carre = taille du carré de sous-échantillonnage
  //                (puissance de 2 pour une vitesse optimale)
  //                8 est un bon compromis entre le temps de calcul et la
  //                capacité de détecter des zones
  #define taille_carre 8
  // pourcentage = pourcentage de remplissage du bloc pour que le pixel sous-ech
  //                 0='1' si   0% de pixels
  //               128='1' si 100% de pixels
  //                (puissance de 2 pour une vitesse optimale)
  //               128 donne de très bon résultats sur l'erreur de type 1
  #define pourcentage 20
  unsigned short XX2 = nbr_colonnes/taille_carre;
  unsigned short YY2 = nbr_lignes  /taille_carre;
  
  // variables pour le sous-échantillonnage
  unsigned short x,y,xx,yy,x2,y2; // compteur de boucles
  unsigned char etat_element; // état du pixel sous-éch. ('0' ou '1')
  unsigned short nbr_elements_1; // nombre d'éléments à '1' dans le bloc

  // variables pour la recherche de zones
  // x, y, taille_zone, surface_zone, bornes (stockées pour le calcul du barycentre)
  //unsigned int i; // compteur de boucles
  unsigned short nbr_zones = 0; //nombre de zones découvertes sur l'image sous-échantillonnée  
  //float taille_zone; // taille de la diagonale de la zone en pixels
  //int tmp_zone; // numéro de zone temporaire pour l'échange (tri)
  unsigned int x_inf, x_sup, y_inf, y_sup; // bornes de la zone
  int x_inf2, x_sup2, y_inf2, y_sup2; // bornes de clipping 
  int surface_zone; // surface de la zone en pixels
  unsigned int i; // compteur de boucle
  unsigned int num_zone; // numéro de la zone courante

  // variables pour la recherche de la meilleure zone
  float meilleur_rapport;
  unsigned int meilleure_zone;                       
  

  // Sous échantillonnage    
  // 24246 cycles (130x96)
  for (yy=0; yy<YY2; yy++) {
    for (xx=0; xx<XX2; xx++) {
      etat_element=1; // état de l'élément (par défaut, il est allumé)
      nbr_elements_1 = 0;
      //adr_y = 0;
      for (y2=0; y2<taille_carre; y2++) {
        for (x2=0; x2<taille_carre; x2++) {
          if (A[xx*taille_carre + x2+nbr_colonnes*(yy*taille_carre + y2)]<seuil) {
            nbr_elements_1++;
          }
        }//end for x2
      }//end for y2
      // si x % des pixels du bloc sont à '1' alors le pixel
      // sous-échantillonné est mis à '1'
      if (nbr_elements_1<pourcentage*taille_carre*taille_carre/128) etat_element=0; 
      image_sous_ech[xx+XX2*yy]=etat_element;
      image_sous_ech_marque[xx+XX2*yy]=0; // initialiser le masque
    }//end for y 
  }//end for x
 
  // Après sous échantillonnage, il ne reste que quelques zones (normalement
  // moins que dans l'image seuillée initiale, idéalement une zone unique
  // correspondant à la pupille). Le nombre de pixels étant relativement
  // réduit, il est possible de caractériser les zones en dimension :
  // plus la forme de la zone s'éloigne d'un disque, plus le rapport taille/surface
  // est petit. Si l'on classe les zones en fonction de leur rapport taille/surface,
  // on peut déterminer la pupille en choississant la zone ayant le rapport le plus
  // grand (en réalité, le rapport le plus grand serait un carré). La taille est
  // définie par SQRT((xmax-xmin)^2+(ymax-ymin)^2).
  //
  // Pour identifier une zone, on procède de la manière suivante :
  //  1) création d'une table des pixels déjà examinés (=marqué).
  //  2) parcours de l'image sous échantillonnée jusqu'à un pixel à '1' non marqué
  //  3) parcours de la zone (connexité 4) en marquant les pixels à '1', de manière récursive
  //     (Le nombre de récursions est au maximum de m, m étant la taille de l'image sous-éch)
  //
  // Ensuite, on connait le pixel de départ de la zone dans les coordonnée de
  // l'image sous-échantillonnée et il ne reste plus qu'à identifier la zone 
  // correspondante dans l'image seuillée. Le barycentre n'est alors calculé que
  // sur une seule zone.
  //
  // La complexité de cet algorithme est de l'ordre d'un parcours d'image pour
  // le sous-échantillonnage, d'un parcours de l'image sous-échantillonnée pour
  // la classification des zones et d'un parcours de zone pour la préparation 
  // au barycentre. Au total : O(M+m+M/10) avec M la surface de l'image, m la
  // surface échantillonnée et M/10 la zone identifiée comme la pupille (rappel:
  // la pupille fait environ 10% de la surface de l'image). Cela équivaut à
  // environ 1.2*M opérations.
  //
  // Au total, on est bien loin de la complexité de l'érosion qui est de O(M*N)
  // (env. 3600*M opérations) : environ 3000 fois moins de calcul.
  //
  x=0;
  y=0;
  
  while (1==1) {
    if (image_sous_ech[x+XX2*y]==1 && image_sous_ech_marque[x+XX2*y]==0) {
      // début d'une zone => on traite la zone
        
      // la zone est parcourue en connectivité 4 :
      //
      //         3
      //       2 x 4
      //         1 
      //System.out.println("nouvelle zone : ");
      add_ligne(image_sous_ech, image_sous_ech_marque, XX2,YY2, x,y,XX2, 0, YY2, 0, &x_inf, &x_sup, &y_inf, &y_sup, &surface_zone);
        
      //taille_zone=sqrtf((float)((x_sup-x_inf+1)*(x_sup-x_inf+1))+(float)((y_sup-y_inf+1)*(y_sup-y_inf+1))); //taille de la diagonale de la zone en pixels

      // sauvegarde des données de la zone
      num_zone = nbr_zones;
      if (nbr_zones>=NBR_ZONES_MAX) {
        // erreur : trop de zones => on remplace la moins bonne zone (rapport le plus élevé)
        meilleur_rapport = zones_rapport[0];  
        meilleure_zone = 0;
        for (i=1; i<nbr_zones; i++) {// recherche de la moins bonne zone
          if (zones_rapport[i]>meilleur_rapport) {
            meilleure_zone = i;
            meilleur_rapport=zones_rapport[i];
          }//end if
        }//end for i
        
        num_zone = meilleure_zone;
      } else {
        // il reste de la place pour les zones => on la place dans l'ordre
        nbr_zones++;
      }//end if (trop de zones)
      
      //zones_x[num_zone]=x;
      //zones_y[num_zone]=y;
      //zones_taille_zone[num_zone]=taille_zone;
      //zones_surface_zone[num_zone]=surface_zone;
      zones_x_inf[num_zone]=x_inf;
      zones_x_sup[num_zone]=x_sup;
      zones_y_inf[num_zone]=y_inf;
      zones_y_sup[num_zone]=y_sup;
      //zones_rapport[num_zone]=taille_zone/surface_zone;
      zones_rapport[num_zone]=fabsf(surface_zone/(float)((x_sup-x_inf+1)*(y_sup-y_inf+1))-3.1415/(float)4);
      // rapport idéal = Pi/4 pour une ellipse

    } else {
      // pas une nouvelle zone => on continue
      image_sous_ech_marque[x+XX2*y]=1; // on marque la case
      x++; // on passe à la case suivante
      if (x>=XX2) {
        // on passe à la ligne suivante
        x=0;
        y++;
      }//end if
    }//end if
    if (y>=YY2)  break; //toute l'image a été traitée
  }//end while

 
  // tri des zones par rapport croissant (tri à bulles)
  /*
  // tri pas nécessaire : on utilise seulement la 1ère zone
  for (i=0; i<nbr_zones; i++) zones[i]=i; // initialisation des numéros de zones
  for (x=0; x<nbr_zones-1; x++) {
    for (y=x+1; y<nbr_zones; y++) {
      if (zones_rapport[zones[y]]<zones_rapport[zones[x]]) { // && zones_surface_zone[zones[x]]<X2*Y2/10
        // échange des valeurs
        tmp_zone = zones[x];
        zones[x]=zones[y];
        zones[y]=tmp_zone;
      }//end if
    }//end for y
  }//end for x   
  meilleure_zone = zones[0]; // la meilleure zone est le première triée
  */

  meilleur_rapport = zones_rapport[0];  
  meilleure_zone = 0;
  for (x=1; x<nbr_zones; x++) {
    //if (zones_rapport[x]>meilleur_rapport) {
    if (zones_rapport[x]<meilleur_rapport) {
      meilleure_zone = x;
      meilleur_rapport=zones_rapport[x];
    }//end if
  }//end for x
  
  // affichage des zones
  /*for (x=0; x<nbr_zones; x++) {
    printf("%i %f f i %i %i %i %i\n",x,
                      zones_rapport[x],
                      //zones_taille_zone[x],
                      //zones_surface_zone[x],
                      zones_x_inf[x],
                      zones_x_sup[x],
                      zones_y_inf[x],
                      zones_y_sup[x]);
  }//end for i
   */ 
  //calcul des bornes de la zone de l'image initiale pour le barycentre (+/-1 pour agrandir la zone de recherche)
  // Note : normalement, il faudrait prendre un pixel de la zone sur l'image
  //        seuillée et faire une recherche de région, ce qui détermine la bonne
  //        zone. Ici, on fait l'approximation d'une zone carrée, ce qui ne devrait
  //        pas etre trop faux, compte tenu de la forme de la pupille.
  if (nbr_zones==0) {
    puts("WARNING : Aucune zone trouvee (=> reduire 'taille_carre' ou\n"
         "          diminuer le taux de remplissage du bloc).\n"
         "          Le barycentre a ete calcule sur toute l'image");

    // calcul du barycentre (sur toute l'image puisqu'on a pas de zones)
    get_barycentre_seuil(A, nbr_colonnes, nbr_lignes, 0, nbr_colonnes,0, nbr_lignes, centre_x, centre_y, seuil);
  } else {
    x_inf2 = (zones_x_inf[meilleure_zone]-2)*taille_carre; // +/-2 pour être sûr d'avoir la pupille incluse
    x_sup2 = (zones_x_sup[meilleure_zone]+2)*taille_carre;
    y_inf2 = (zones_y_inf[meilleure_zone]-2)*taille_carre;
    y_sup2 = (zones_y_sup[meilleure_zone]+2)*taille_carre;
    if (x_inf2<0)  x_inf2=0;
    if (y_inf2<0)  y_inf2=0;
    if (x_sup2>=nbr_colonnes) x_sup2=nbr_colonnes-1;
    if (y_sup2>=nbr_lignes) y_sup2=nbr_lignes-1;

    // calcul du barycentre (uniquement sur la zone spécifiée)
    //get_barycentre_seuil(A, nbr_colonnes, nbr_lignes, y_inf2, y_sup2,x_inf2, x_sup2, centre_x, centre_y, seuil);
    get_barycentre_seuil(A, nbr_colonnes, nbr_lignes, x_inf2, x_sup2, y_inf2, y_sup2, centre_x, centre_y, seuil);
  }//end if
    
}/* ----------------------------------------------------------------------------
end get_barycentre_id_zones */








terminer() {   /* routine factice pour permettre d'exécuter le code jusqu'à la fin par GEL_Go(terminer); */
  static volatile int fake;
  fake++; 
  
}


                                          
main() {     
  FILE* f;  
  time_t temps_initial;
  time_t temps_final;      
  float temps;
 /* #define LED1_on           0x0E000000
  #define LED2_on           0x0D000000
  #define LED3_on           0x0B000000
  #define LEDs_off          0x07000000
  volatile int* LEDs = (int*)0x90080000;
*LEDs = LEDs_off;*/  
  
  
  
  nbr_pixels = nbr_colonnes*nbr_lignes;
  printf("taille = %d x %d\n", nbr_colonnes, nbr_lignes);

  // calcul du seuil optimal pour la segmentation d'image
  time(&temps_initial);             

#define NBR_BOUCLES 100000
  // 5000 boucles en externe, 50000 en interne
  temp=0;
  for (temp=0; temp<NBR_BOUCLES; temp++) {
    init_recherche_seuil_optimal();
    im_hist_get_lobe(histogramme, 1, 0, &b_inf, &b_sup);
    calculer_seuil_optimal(&b_inf, &b_sup);

    // seuillage de l'image                          
    #ifdef ID_ZONES
      get_barycentre_id_zones(raster, b_sup+1, &centre_x, &centre_y);
    #else
      #ifdef CALCULER_IMAGE_SEUILLEE
        seuillage(raster, image_seuil, nbr_pixels, b_sup+1);
        get_barycentre(image_seuil, nbr_colonnes, nbr_lignes, 0, nbr_colonnes,0, nbr_lignes, &centre_x, &centre_y);
      #else
        get_barycentre_seuil(raster, nbr_colonnes, nbr_lignes, 0, nbr_colonnes,0, nbr_lignes, &centre_x, &centre_y, b_sup+1);
      #endif
    #endif

  }//end for

  time(&temps_final);              
  temps = (temps_final-temps_initial)*1000/(float)NBR_BOUCLES;
  printf("duree = %f [ms]\n", temps);

  printf("centre = (%f, %f)\n", centre_x, centre_y);
  
  // ecriture du résultat dans un fichier
  f = fopen("c:\\apps\\ti\\myprojects\\eye_tracker\\timing_tms2.txt","a");   // for append
  fprintf(f, "%i\t%i\t%i\t%f\t%f\t%f\t%i\t%i\t%i\t%i\n",num_image, nbr_colonnes, nbr_lignes, temps, centre_x, centre_y, centre_x_db, centre_y_db, diametre_x, diametre_y);
  fflush(f);
  fclose(f);
   
  terminer();
}/* end main */
