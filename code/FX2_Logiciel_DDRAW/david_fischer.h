//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du H            : david_fischer
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

#define INITGUID
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <process.h>
//#include <mmsystem.h>

#include <iostream>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winbase.h>
#include <windowsx.h>
#include <string.h>

#define ERR_NO_OK                 0
#define ERR_NO_UTILISATEUR        1

// ERREURS FENETRE

#define ERR_NO_FENETRE_CLASSE     2
#define ERR_NO_FENETRE_CREATE     3

// ERREURS DIRECT DRAW

#define ERR_NO_CREATION           2
#define ERR_NO_COOPERATION        3
#define ERR_NO_MODE_ACTIF         4
#define ERR_NO_MODE_AFFICHAGE     5
#define ERR_NO_PRIMAIRE           6
#define ERR_NO_BACKBUFFER         7
#define ERR_NO_CLIPPER            8
#define ERR_NO_CLIPPER_HWND       9
#define ERR_NO_CLIPPER_PRIMAIRE   10

#define ERR_NO_AFFICHE            11
 
using namespace std;

typedef unsigned __int8  uint8;
typedef unsigned __int16 uint16;
typedef unsigned __int32 uint32;

struct RVB_HSL
{
    union { uint8 R; uint8 H; };
    union { uint8 V; uint8 S; };
    union { uint8 B; uint8 L; };
};

struct BVRA { uint8 B,V,R,A; };

struct Pos2v8b  { uint8  X,Y; };
struct Pos2v16b { uint16 X,Y; };
struct Pos2v32f { float  X,Y; };

// UTILE

void ut_ToHex (uint8 pOctet, char* pHexa);

Pos2v32f ut_Coords32f (Pos2v16b pCoords, uint16 pSrcDebX, uint16 pSrcFinX,
                                         uint16 pSrcDebY, uint16 pSrcFinY);
                                       
Pos2v16b ut_Coords16b (Pos2v32f pCoords, uint16 pDstDebX, uint16 pDstFinX,
                                         uint16 pDstDebY, uint16 pDstFinY);

Pos2v8b ut_Coords8b (Pos2v32f pCoords, uint8 pDstDebX, uint8 pDstFinX,
                                       uint8 pDstDebY, uint8 pDstFinY);

RVB_HSL ut_HSL_a_RVB (RVB_HSL pHSL, float fH, float fS, float fL);

void ut_ChargerBitmap (HBITMAP* pBitmap, char* pNomBMP);
void ut_FermerBitmap  (HBITMAP  pBitmap);

// FENETRE

#ifdef DAVID_FENETRE

HWND fe_GetHandle ();

uint16 fe_GetPosL    ();
uint16 fe_GetPosH    ();
uint16 fe_GetLargeur ();
uint16 fe_GetHauteur ();

bool fe_GetActive ();
bool fe_GetFocus  ();

uint16 fe_GetLargeurEcran ();
uint16 fe_GetHauteurEcran ();

uint8 fe_GetErrNo ();

char* fe_GetErrTxt ();

void fe_Message (char* pMessage);

bool fe_Initialise (HINSTANCE pInstance,
				   char*	 pNomClasse,
				   char*	 pTitreClasse,
				   uint16    pPosL,	uint16 pLargeur,
				   uint16    pPosH, uint16 pHauteur,
                   void (*pNettoyage)(),
                   void (*pAffichage)(),
                   void (*pMessageFenetre)
                   (HWND hWnd, unsigned uMsg, WPARAM wParam, LPARAM lParam));

bool fe_Finalise (uint8 pErrNo);

int fe_Boucle ();

#endif

// DIRECT DRAW

#ifdef DAVID_DIRECT_DRAW

uint8  dx_GetNombreSurfaces ();
uint16 dx_GetResolutionX    ();
uint16 dx_GetResolutionY    ();
uint16 dx_GetBitsParPixel   ();
bool   dx_GetPleinEcran     ();
bool   dx_GetTailleFenetre  ();
DWORD  dx_GetModeCoop       ();

uint16 dx_GetPitch ();
BVRA*  dx_GetEcran ();

HRESULT dx_GetErrDd ();
uint8   dx_GetErrNo ();

char* dx_GetErrTxt ();

bool dx_Initialise (uint8  pNombreSurfaces,
                    HWND   pFenetre,
                    uint16 pResolutionX,
                    uint16 pResolutionY,
                    uint16 pBitsParPixel,
                    uint16 pFrequence,
                    bool   pPleinEcran,
                    bool   pTailleFenetre,
                    void   (*pRestaure)());

bool dx_Finalise (uint8 pErrNo);

bool dx_Affiche  ();
void dx_Restaure ();

bool dx_Efface (uint8 Rouge, uint8 Vert, uint8 Bleu);

bool dx_AccessMemoire (bool pVerrou);

bool dx_CopieBVRA (BVRA* pImage, uint16 pPosX, uint16 pTailleX,
                                 uint16 pPosY, uint16 pTailleY);

bool dx_NombreGDI (float pNombre, uint8 pDecimales,
                   uint16 pPosX, uint16 pPosY, COLORREF pCouleur);
                   
bool dx_NombreGDI (uint32 pNombre, uint16 pPosX,
                                   uint16 pPosY, COLORREF pCouleur);

bool dx_TexteGDI (char* pTexte, uint16 pPosX,
                                uint16 pPosY, COLORREF pCouleur);

bool dx_CreerSurface (uint8 pNoSurface, uint16 pTailleX, uint16 pTailleY);

bool dx_CopieBitmap (uint8 pNoSurface,
                     HBITMAP pBitmap, uint16 pPosX, uint16 pTailleX,
                                      uint16 pPosY, uint16 pTailleY);

bool dx_CopieBitmap (HBITMAP pBitmap, uint16 pPosX, uint16 pTailleX,
                                      uint16 pPosY, uint16 pTailleY);

bool dx_SurfaceChargeBMP (uint8 pNoSurface, char* pNomBMP,
                          uint16 pTailleX, uint16 pTailleY);

bool dx_SurfaceRestaureBMP (uint8 pNoSurface, char* pNomBMP);

bool dx_SurfaceCopie (uint8 pNoSurface, uint16 pPosX, uint16 pPosY);

#endif
