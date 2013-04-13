//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du C++          : main
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
// Comment compiler    : qmake -project / qmake
//                       ajouter -lddraw -lgdi32 / make
//=============================================================--

#define DAVID_FENETRE
#define DAVID_DIRECT_DRAW
#include "david_fischer.h"

#include <QApplication>

#include "include\CypressEzUSBDevice.h"

// DÉBUT MOYENNEUR

const int nDefCfgPerMoyX   = 6;
const int nDefCfgPerMoyY   = 4;
const int nDefCfgPerMoyPre = 1;
const int nDefCfgPerMoyDiv = 24;
	
const int nDefCfgDetMoyX   = 3;
const int nDefCfgDetMoyY   = 2;
const int nDefCfgDetMoyPre = 1;
const int nDefCfgDetMoyDiv = 6;
	
const int nPerPerX = 8;
const int nPerPerY = nPerPerX;
const int nDetDetX = 32;
const int nDetDetY = nDetDetX;
const int nPerDetX = 16;
const int nPerDetY = nPerDetX;
	
const int nDefCfgTailleX = 2*nDefCfgPerMoyX*(nPerPerX*2+nPerDetX);
const int nDefCfgTailleY = 2*nDefCfgPerMoyY*(nPerPerY*2+nPerDetY);

const int nFacteurX = 1280-nDefCfgTailleX-1;
const int nFacteurY = 1024-nDefCfgTailleY-1;
	
// FIN MOYENNEUR

const int TAILLE_RVB_X = nDefCfgTailleX/2;
const int TAILLE_RVB_Y = nDefCfgTailleY/2;

// TAILLE DES DIFFÉRENTS ÉLÉMENTS D'AFFICHAGE

const int TAILLE_ZONES_X = 256;
const int TAILLE_ZONES_Y = 286;

const int TAILLE_SOURIS_X = 432;
const int TAILLE_SOURIS_Y = 316;

const int TAILLE_VISEUR_X = 32;
const int TAILLE_VISEUR_Y = 32;

const int CENTRE_VISEUR2_X = TAILLE_VISEUR_X/2;
const int CENTRE_VISEUR2_Y = TAILLE_VISEUR_Y/2;

// IMAGE VISIBLE

const int FACTEUR_IMAGE = 4;
const int TAILLE_IMAGE_X = TAILLE_RVB_X*FACTEUR_IMAGE;
const int TAILLE_IMAGE_Y = TAILLE_RVB_Y*FACTEUR_IMAGE;

static BVRA ImageBVRA[TAILLE_IMAGE_Y][TAILLE_IMAGE_X];

// COUCHES

const int FACTEUR_COUCHE = 1;
const int TAILLE_COUCHE_X = TAILLE_RVB_X*FACTEUR_COUCHE;
const int TAILLE_COUCHE_Y = TAILLE_RVB_Y*FACTEUR_COUCHE;

static BVRA CouchesBVRA[3][TAILLE_COUCHE_X][TAILLE_COUCHE_Y];

// MARGES DE POSITIONNEMENT

const int MARGE_Y = 20;
const int MARGE_X = 20;

const int POS_IMAGE_X = MARGE_X;
const int POS_IMAGE_Y = MARGE_Y*2;

const int POS_COUCHES_X = POS_IMAGE_X+TAILLE_IMAGE_X+20;
const int POS_COUCHE1_Y = POS_IMAGE_Y;
const int POS_COUCHE2_Y = POS_COUCHE1_Y+(TAILLE_COUCHE_Y+40);
const int POS_COUCHE3_Y = POS_COUCHE2_Y+(TAILLE_COUCHE_Y+40);

const int POS_SOURIS_X = POS_IMAGE_X;
const int POS_SOURIS_Y = POS_IMAGE_Y+TAILLE_IMAGE_Y+20;

const int POS_ZONES_X = POS_SOURIS_X+TAILLE_SOURIS_X+20;
const int POS_ZONES_Y = POS_SOURIS_Y;

const int POS_STATS_X = POS_COUCHES_X;
const int POS_STATS_Y = POS_COUCHE3_Y+TAILLE_COUCHE_Y+40;

const int TAILLE_FENETRE_X = POS_COUCHES_X+TAILLE_COUCHE_X+MARGE_X;
const int TAILLE_FENETRE_Y = POS_SOURIS_Y+TAILLE_SOURIS_Y+MARGE_Y;

// POSITIONNEMENT DE LA SOURIS

static Pos2v32f OldSouris = {0.0,0.0};
static Pos2v32f CtrSouris = {0.0,0.0};

float fH = 1.0;
float fS = 1.0;
float fL = 1.0;

#include "main_fx2.h"
#include "main_titi.h"
#include "main_graphique.h"

//-----------------------------------------------------------------------------
// Name: Nettoyage()
// Desc: Nettoye les objets utilisés dès que nous avons fini...
//-----------------------------------------------------------------------------
void Nettoyage ()
{	
    fe_Finalise (0);
	dx_Finalise (0);
	
	//DeleteCriticalSection (&MutexBulk);
}

//-----------------------------------------------------------------------------
// Name: Restaure()
// Desc: Restaure les objets utilisés dès que nous les avons perdus...
//-----------------------------------------------------------------------------
void Restaure ()
{
    if (!dx_SurfaceRestaureBMP (0, "viseur1.bmp"))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de recharger viseur1.bmp");
        fclose  (Fichier);
        exit(-1);
     }
     
    if (!dx_SurfaceRestaureBMP (1, "viseur2.bmp"))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de recharger viseur2.bmp");
        fclose  (Fichier);
        exit(-1);
     }
     
    if (!dx_SurfaceRestaureBMP (2, "viseur2.bmp"))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de recharger viseur2.bmp");
        fclose  (Fichier);
        exit(-1);
     }
}

//-----------------------------------------------------------------------------
// Name: Affichage()
// Desc: Affiche les objets dès que nous devons les afficher...
//-----------------------------------------------------------------------------
void Affichage ()
{
    dx_Restaure ();
    
    if (!dx_Efface (0,0,0))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, dx_GetErrTxt ());
        fclose  (Fichier);
        exit(-1);
    }

    TraitementGraphique ((BVRA*)&ImageBVRA[0][0], FACTEUR_IMAGE, RVB);
    TraitementGraphique ((BVRA*)&CouchesBVRA[0][0][0], FACTEUR_COUCHE, C1);
    TraitementGraphique ((BVRA*)&CouchesBVRA[1][0][0], FACTEUR_COUCHE, C2);
    TraitementGraphique ((BVRA*)&CouchesBVRA[2][0][0], FACTEUR_COUCHE, C3);
    
    if (!dx_AccessMemoire (true))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, dx_GetErrTxt ());
        fclose  (Fichier);
        exit(-1);
     }

     dx_CopieBVRA ((BVRA*)&ImageBVRA[0][0], POS_IMAGE_X, TAILLE_IMAGE_X,
                                            POS_IMAGE_Y, TAILLE_IMAGE_Y);
                                                                          
     dx_CopieBVRA ((BVRA*)&CouchesBVRA[0][0][0], POS_COUCHES_X,TAILLE_COUCHE_X,
                                                 POS_COUCHE1_Y,TAILLE_COUCHE_Y);
                                            
     dx_CopieBVRA ((BVRA*)&CouchesBVRA[1][0][0], POS_COUCHES_X,TAILLE_COUCHE_X,
                                                 POS_COUCHE2_Y,TAILLE_COUCHE_Y);
                                            
     dx_CopieBVRA ((BVRA*)&CouchesBVRA[2][0][0], POS_COUCHES_X,TAILLE_COUCHE_X,
                                                 POS_COUCHE3_Y,TAILLE_COUCHE_Y);
                                                
     if (!dx_AccessMemoire (false))
     {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, dx_GetErrTxt ());
        fclose  (Fichier);
        exit(-1);
     }
     
     COLORREF C = 0x00FFFF;
     
     dx_TexteGDI  ("Projet de diplôme << Vision Stéréoscopique >> "
                   "par l'étudiant David Fischer (EIG-HES-TE3-2006)",160,6,C);
     
     // Informations sur les couches ------------------------------------------

     dx_TexteGDI("Couche R ou H    facteur =",POS_COUCHES_X,POS_COUCHE1_Y-18,C);
     dx_TexteGDI("Couche V ou S    facteur =",POS_COUCHES_X,POS_COUCHE2_Y-18,C);
     dx_TexteGDI("Couche B ou L    facteur =",POS_COUCHES_X,POS_COUCHE3_Y-18,C);
     
     dx_NombreGDI (fH, 2, 172+POS_COUCHES_X, POS_COUCHE1_Y-18, C);
     dx_NombreGDI (fS, 2, 172+POS_COUCHES_X, POS_COUCHE2_Y-18, C);
     dx_NombreGDI (fL, 2, 172+POS_COUCHES_X, POS_COUCHE3_Y-18, C);  
        
     // Position de la souris avec une marge -----------------------------------
     
     uint16 tDebX = POS_SOURIS_X+CENTRE_VISEUR2_X;
     uint16 tFinX = POS_SOURIS_X-CENTRE_VISEUR2_X+TAILLE_SOURIS_X;
     
     uint16 tDebY = POS_SOURIS_Y                +CENTRE_VISEUR2_Y;
     uint16 tFinY = POS_SOURIS_Y+TAILLE_SOURIS_Y-CENTRE_VISEUR2_Y;
     
     Pos2v16b OldS = ut_Coords16b (OldSouris, tDebX, tFinX, tDebY, tFinY);   
     Pos2v16b CtrS = ut_Coords16b (CtrSouris, tDebX, tFinX, tDebY, tFinY);

     dx_SurfaceCopie (0, POS_SOURIS_X, POS_SOURIS_Y);
     dx_SurfaceCopie (1, OldS.X-CENTRE_VISEUR2_X, OldS.Y-CENTRE_VISEUR2_Y);
     dx_SurfaceCopie (2, CtrS.X-CENTRE_VISEUR2_X, CtrS.Y-CENTRE_VISEUR2_Y);
     
     Pos2v8b PosSouris = ut_Coords8b (CtrSouris, 0, 255, 0, 255);
     
     // Informations sur le moyenneur ------------------------------------------
     
     dx_SurfaceCopie (3, POS_ZONES_X, POS_ZONES_Y);
  
     dx_NombreGDI ((uint32)(OldSouris.X*nFacteurX+4), POS_ZONES_X+175, 
                                                      POS_ZONES_Y+236, C);
     dx_NombreGDI ((uint32)(OldSouris.Y*nFacteurY+4), POS_ZONES_X+220,
                                                      POS_ZONES_Y+236, C);
     
     dx_NombreGDI ((uint32)(OldSouris.X*255),POS_ZONES_X+175,POS_ZONES_Y+252,C);
     dx_NombreGDI ((uint32)(OldSouris.Y*255),POS_ZONES_X+220,POS_ZONES_Y+252,C);
        
     dx_NombreGDI (PosSouris.X, POS_ZONES_X+175, POS_ZONES_Y+268, C);
     dx_NombreGDI (PosSouris.Y, POS_ZONES_X+220, POS_ZONES_Y+268, C);
     
     dx_NombreGDI (nDefCfgTailleX, POS_ZONES_X+185, POS_ZONES_Y+8, C);
     dx_NombreGDI (nDefCfgTailleY, POS_ZONES_X+230, POS_ZONES_Y+8, C);
     
     dx_NombreGDI (TAILLE_RVB_X, POS_ZONES_X+185, POS_ZONES_Y+24, C);
     dx_NombreGDI (TAILLE_RVB_Y, POS_ZONES_X+230, POS_ZONES_Y+24, C);
     
     dx_NombreGDI (nDetDetX, POS_ZONES_X+120, POS_ZONES_Y+128, C);
     dx_NombreGDI (nDetDetY, POS_ZONES_X+155, POS_ZONES_Y+128, C);
    
     dx_NombreGDI (nDefCfgDetMoyX, POS_ZONES_X+120, POS_ZONES_Y+144, C);
     dx_NombreGDI (nDefCfgDetMoyY, POS_ZONES_X+155, POS_ZONES_Y+144, C);  
        
     dx_NombreGDI (TAILLE_TITI_X, POS_ZONES_X+190, POS_ZONES_Y+180, C);
     dx_NombreGDI (TAILLE_TITI_Y, POS_ZONES_X+225, POS_ZONES_Y+180, C);
    
     dx_NombreGDI (nDefCfgPerMoyX, POS_ZONES_X+190, POS_ZONES_Y+196, C);
     dx_NombreGDI (nDefCfgPerMoyY, POS_ZONES_X+225, POS_ZONES_Y+196, C);
     
     // Statistiques du FX2 (flux USB2.0) --------------------------------------
    
     dx_TexteGDI  ("NoImage", POS_STATS_X, POS_STATS_Y, C);

     dx_NombreGDI (ImageTITI.NoImage, POS_STATS_X+120, POS_STATS_Y, C);
    
     dx_TexteGDI  ("Flux Bulk", POS_STATS_X,     POS_STATS_Y+32, C);
     dx_TexteGDI  ("Total",     POS_STATS_X+120, POS_STATS_Y+32, C);
     dx_TexteGDI  ("Bytes",     POS_STATS_X+170, POS_STATS_Y+32, C);
     
     dx_TexteGDI ("FX2_IMAGE",    POS_STATS_X, POS_STATS_Y+48, C);
     dx_TexteGDI ("FX2_PUPILLE",  POS_STATS_X, POS_STATS_Y+62, C);
     dx_TexteGDI ("FX2_CONTROLE", POS_STATS_X, POS_STATS_Y+78, C);

     dx_NombreGDI (BuffersBulk[FX2_IMAGE].Numero, POS_STATS_X+120,
                                                  POS_STATS_Y+48, C);
                                                  
     dx_NombreGDI (BuffersBulk[FX2_PUPILLE].Numero, POS_STATS_X+120,
                                                    POS_STATS_Y+62, C);
                                                    
     dx_NombreGDI (NbControle, POS_STATS_X+120, POS_STATS_Y+78, C);
     
     dx_NombreGDI (BuffersBulk[FX2_IMAGE].Nombre,   POS_STATS_X+170,
                                                    POS_STATS_Y+48, C);
                                                    
     dx_NombreGDI (BuffersBulk[FX2_PUPILLE].Nombre, POS_STATS_X+170,
                                                    POS_STATS_Y+62, C);
     
     // Informations générales (mode d'emploi...) ------------------------------
     dx_TexteGDI("Commandes clavier numérique",POS_STATS_X,POS_STATS_Y+110,C);
     dx_TexteGDI("Couches", POS_STATS_X,     POS_STATS_Y+126, C);
     dx_TexteGDI("R/H",     POS_STATS_X+70,  POS_STATS_Y+126, C);
     dx_TexteGDI("V/S",     POS_STATS_X+120, POS_STATS_Y+126, C);
     dx_TexteGDI("B/L",     POS_STATS_X+170, POS_STATS_Y+126, C);

     dx_TexteGDI("Fac. +0.1", POS_STATS_X,    POS_STATS_Y+142, C);
     dx_TexteGDI("7",        POS_STATS_X+76,  POS_STATS_Y+142, C);
     dx_TexteGDI("8",        POS_STATS_X+126, POS_STATS_Y+142, C);
     dx_TexteGDI("9",        POS_STATS_X+176, POS_STATS_Y+142, C);
     
     dx_TexteGDI("Fac. -0.1",POS_STATS_X,     POS_STATS_Y+158, C);
     dx_TexteGDI("4",        POS_STATS_X+76,  POS_STATS_Y+158, C);
     dx_TexteGDI("5",        POS_STATS_X+126, POS_STATS_Y+158, C);
     dx_TexteGDI("6",        POS_STATS_X+176, POS_STATS_Y+158, C);     

    if (!dx_Affiche ())
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, dx_GetErrTxt ());
        fclose  (Fichier);
        exit(-1);
    }
}

//-----------------------------------------------------------------------------
// Name: MessageFenetre(...)
// Desc: Gère les autres genre d'appels dès que nous en avons un...
//-----------------------------------------------------------------------------
void MessageFenetre (HWND hWnd, unsigned uMsg, WPARAM wParam, LPARAM lParam)
{   
    Pos2v16b PosSouris;
    
    switch (uMsg)
    {
    case WM_LBUTTONDOWN:

         if (wParam == MK_LBUTTON)
         {
             //ToControle (ut_Coords8b (CtrSouris, 0, 255, 0, 255));
             
             OldSouris = CtrSouris;
         }
         break;
         
    case WM_MOUSEMOVE:
         
         PosSouris.X = GET_X_LPARAM(lParam);
         PosSouris.Y = GET_Y_LPARAM(lParam);
         
         CtrSouris = ut_Coords32f (PosSouris,
                           POS_SOURIS_X, POS_SOURIS_X+TAILLE_SOURIS_X,
                           POS_SOURIS_Y, POS_SOURIS_Y+TAILLE_SOURIS_Y);

         break;
         
    case WM_KEYDOWN:
         
        switch (wParam)
	    {
        case VK_NUMPAD7: fH+=0.1; break;
        case VK_NUMPAD4: fH-=0.1; break;
        case VK_NUMPAD8: fS+=0.1; break;
        case VK_NUMPAD5: fS-=0.1; break;
        case VK_NUMPAD9: fL+=0.1; break;
        case VK_NUMPAD6: fL-=0.1; break;
        } 
        break;
    }     
}

//-----------------------------------------------------------------------------
// Name: Initialise(...)
// Desc: Initialise les objets dès que nous devons le faire...
//-----------------------------------------------------------------------------
void Initialise (HINSTANCE pInstance)
{
    InitializeCriticalSection (&MutexBulk);
    
    if (!fe_Initialise (pInstance,"salut_man", "salut_man",
                        50, TAILLE_FENETRE_X,
                        20, TAILLE_FENETRE_Y,
                        &Nettoyage,&Affichage,&MessageFenetre))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, fe_GetErrTxt ());
        fclose  (Fichier);
        exit(-1);
    }
	
	if (!dx_Initialise (4, fe_GetHandle(),0,0,32,0,false,true,&Restaure))
	{
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, dx_GetErrTxt ());
        fclose  (Fichier);
        exit(-1);
    }
    
    if (!dx_SurfaceChargeBMP (0, "viseur.bmp", TAILLE_SOURIS_X,
                                               TAILLE_SOURIS_Y))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de charger viseur.bmp");
        fclose  (Fichier);
        exit(-1);
    }
    
    if (!dx_SurfaceChargeBMP (1, "viseur2.bmp", TAILLE_VISEUR_X,
                                                TAILLE_VISEUR_Y))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de charger viseur2.bmp");
        fclose  (Fichier);
        exit(-1);
    }
    
    if (!dx_SurfaceChargeBMP (2, "viseur2.bmp", TAILLE_VISEUR_X,
                                                TAILLE_VISEUR_Y))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de charger viseur2.bmp");
        fclose  (Fichier);
        exit(-1);
    }
    
     if (!dx_SurfaceChargeBMP (3, "zones.bmp", TAILLE_ZONES_X,
                                               TAILLE_ZONES_Y))
    {
        FILE *Fichier = fopen ("erreurs.txt","w");
        fprintf (Fichier, "impossible de charger viseur2.bmp");
        fclose  (Fichier);
        exit(-1);
    }
    
    _beginthread (ToImageTiti,  0, NULL);
    //_beginthread (ToPosPupille, 0, NULL);
}

//-----------------------------------------------------------------------------
// Name: WinMain(...)
// Desc: Il était une fois... au commencement... windows nous appela!
//-----------------------------------------------------------------------------

int APIENTRY WinMain (HINSTANCE hInstance,
                      HINSTANCE hPrevInstance,
                      LPSTR     lpCmdLine,
                      int       nCmdShow)
{    
    Initialise (hInstance);
    
    return fe_Boucle ();
}
