//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du C++          : DirectDraw
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

#define DAVID_DIRECT_DRAW
#include "david_fischer.h"

#include "include\ddraw.h"

#define COOP_FENETRE      DDSCL_NORMAL
#define COOP_PLEIN_ECRAN  DDSCL_EXCLUSIVE|DDSCL_FULLSCREEN|DDSCL_ALLOWREBOOT

char* ErrTxt[12] = {"DD - Tout est OK!\n",
                    "DD - Erreur de votre part!\n",
                    "DD - Erreur DirectDrawCreateEx\n",
                    "DD - Erreur SetCooperativeLevel\n",
                    "DD - Erreur GetDisplayMode\n",
                    "DD - Erreur SetDisplayMode\n",
                    "DD - Erreur CreateSurface-P\n",
                    "DD - Erreur CreateSurface-B\n",
                    "DD - Erreur CreateClipper\n",
                    "DD - Erreur SetHWnd-C\n",
                    "DD - Erreur SetClipper\n",
                    "DD - Erreur Flip ou Blt\n"};

static HWND                 Fenetre         = NULL;
static LPDIRECTDRAW7		DirectDraw7     = NULL;
static LPDIRECTDRAWSURFACE7 SurfacePrimaire = NULL;
static LPDIRECTDRAWSURFACE7 SurfaceBack     = NULL;
static LPDIRECTDRAWCLIPPER  SurfaceClipper  = NULL;

static DDSURFACEDESC2 SurfaceDesc;
static DDSCAPS2		  SurfaceCaps;

static DDBLTFX BlitFX;

// Gestion des Surfaces Utilisateur
static LPDIRECTDRAWSURFACE7* Surfaces = NULL;
static uint8 NombreSurfaces = 0;

static uint16 ResolutionX   = 0;
static uint16 ResolutionY   = 0;
static uint16 BitsParPixel  = 0;
static uint16 Frequence     = 0;
static bool  PleinEcran     = false;
static bool  TailleFenetre  = false; // Taille de la fenêtre comme résolution
static DWORD ModeCoop       = 0;     // dans la fenêtre?

static uint16 Pitch = 0;
static BVRA*  Ecran = NULL;

void (*Restaure)();

static HRESULT ErrDd = DD_OK;
static uint8   ErrNo = 0;

#define Nettoyage(x) if (x) { x->Release (); x = NULL; }

//-----------------------------------------------------------------------------
// Name: dx_Get...()
// Desc: Retourne certaines variables...
//-----------------------------------------------------------------------------

uint8  dx_GetNombreSurfaces () { return NombreSurfaces; };
uint16 dx_GetResolutionX    () { return ResolutionX;    };
uint16 dx_GetResolutionY    () { return ResolutionY;    };
uint16 dx_GetBitsParPixel   () { return BitsParPixel;   };
uint16 dx_GetFrequence      () { return Frequence;      };
bool   dx_GetPleinEcran     () { return PleinEcran;     };
bool   dx_GetTailleFenetre  () { return TailleFenetre;  };
DWORD  dx_GetModeCoop       () { return ModeCoop;       };

uint16 dx_GetPitch () { return Pitch; };
BVRA*  dx_GetEcran () { return Ecran; };

HRESULT dx_GetErrDd () { return ErrDd; };
uint8   dx_GetErrNo () { return ErrNo; };

//-----------------------------------------------------------------------------
// Name: dx_GetErrTxt()
// Desc: Retourne un texte décrivant l'erreur en cours
//-----------------------------------------------------------------------------

char Erreur_Tampon[64];

char* dx_GetErrTxt ()
{	
    _itoa (ErrDd, Erreur_Tampon, 16);
    
    memcpy ((void*)&Erreur_Tampon[strlen(Erreur_Tampon)],
            (const void*) &ErrTxt[ErrDd], strlen(ErrTxt[ErrDd])+1);
            
    return Erreur_Tampon;
}

//-----------------------------------------------------------------------------
// Name: dx_InitVars()
// Desc: Initialise les variables internes
//-----------------------------------------------------------------------------
void dx_InitVars ()
{
    Fenetre         = NULL;
	DirectDraw7		= NULL;
	SurfacePrimaire = NULL;
	SurfaceBack		= NULL;
	SurfaceClipper  = NULL;
	Surfaces        = NULL;
	
	ZeroMemory (&SurfaceDesc, sizeof(SurfaceDesc));
    ZeroMemory (&SurfaceCaps, sizeof(SurfaceCaps));
	SurfaceDesc.dwSize = sizeof(SurfaceDesc);

	NombreSurfaces = 0;
	ResolutionX    = 0;
	ResolutionY    = 0;
	BitsParPixel   = 0;
	Frequence      = 0;
	PleinEcran     = false;
	TailleFenetre  = false;
	ModeCoop       = 0;
	
	Pitch = 0;
	Ecran = NULL;
	
 	Restaure = NULL;   	
 	
	ErrDd = DD_OK;
	ErrNo = 0;
}

//-----------------------------------------------------------------------------
// Name: dx_Initialise (...)
// Desc: Initialise et configure DirectX (DirectDraw)
//-----------------------------------------------------------------------------
bool dx_Initialise (uint8  pNombreSurfaces,
                    HWND   pFenetre,
                    uint16 pResolutionX,
                    uint16 pResolutionY,
                    uint16 pBitsParPixel,
                    uint16 pFrequence,
                    bool   pPleinEcran,
                    bool   pTailleFenetre,
                    void   (*pRestaure)())
{
    // InitialiseDX a déjà été appelé
    
    if (DirectDraw7 != NULL) { return dx_Finalise (ERR_NO_UTILISATEUR); }
    
    dx_InitVars ();

    // Initialise toutes les variables
    
    Fenetre = pFenetre;
    
    NombreSurfaces = pNombreSurfaces;

	ResolutionX   = pResolutionX;
	ResolutionY   = pResolutionY;
	BitsParPixel  = pBitsParPixel;
	Frequence     = pFrequence;
	PleinEcran    = pPleinEcran;
	TailleFenetre = pTailleFenetre;
	
	Restaure = pRestaure;
	
	Surfaces = new LPDIRECTDRAWSURFACE7[NombreSurfaces];

	// Initialisation de directdraw

    ErrDd = DirectDrawCreateEx (0,(LPVOID*)&DirectDraw7,IID_IDirectDraw7,0);
    
    if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_CREATION);

    ModeCoop = PleinEcran ? COOP_PLEIN_ECRAN : COOP_FENETRE;
    
    // Utilisation de la résolution active ou donnée
    
    if (ResolutionX  == 0 || ResolutionY == 0 ||
        BitsParPixel == 0 || Frequence   == 0)
    {
        DDSURFACEDESC2 ModeActif;
        ZeroMemory (&ModeActif, sizeof(ModeActif));
        ModeActif.dwSize = sizeof(ModeActif);
     
        ErrDd = DirectDraw7->GetDisplayMode (&ModeActif);
   
        if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_MODE_ACTIF);

        if (ResolutionX  == 0) ResolutionX = ModeActif.dwWidth;
        if (ResolutionY  == 0) ResolutionY = ModeActif.dwHeight;
        if (BitsParPixel == 0) BitsParPixel = ModeActif.
                                              ddpfPixelFormat.dwRGBBitCount;
        if (Frequence == 0) Frequence = ModeActif.dwRefreshRate;
    }
    
    // Sélection du mode de coopération

	ErrDd = DirectDraw7->SetCooperativeLevel (Fenetre, ModeCoop);
	
	if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_COOPERATION);

	ErrDd = DirectDraw7->SetDisplayMode (ResolutionX,
                                         ResolutionY,BitsParPixel,0,0);
    
    if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_MODE_AFFICHAGE);

    // Création des surfaces d'affichage
	
    SurfaceDesc.dwFlags = DDSD_CAPS;
    SurfaceDesc.ddsCaps.dwCaps = DDSCAPS_PRIMARYSURFACE;
	
	if (PleinEcran)
	{   // Surface avec backbuffer
    	SurfaceDesc.dwFlags	|= DDSD_BACKBUFFERCOUNT;
 	    SurfaceDesc.ddsCaps.dwCaps |= DDSCAPS_FLIP | DDSCAPS_COMPLEX;
	    SurfaceDesc.dwBackBufferCount = 1;
    }
    
    ErrDd = DirectDraw7->CreateSurface (&SurfaceDesc,&SurfacePrimaire,NULL);
	
	if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_PRIMAIRE);
	
	if (PleinEcran)
	{
	    SurfaceCaps.dwCaps = DDSCAPS_BACKBUFFER;

	    ErrDd = SurfacePrimaire->GetAttachedSurface (&SurfaceCaps,&SurfaceBack);
	
	    if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_BACKBUFFER);
    }
    else
    {
        // Surface avec clipper pour dessiner que dans la fenêtre
        ErrDd = DirectDraw7->CreateClipper (0, &SurfaceClipper, NULL);
        
        if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_CLIPPER);
        
        // Coordonnées de la fenêtre dans le clipper
        ErrDd = SurfaceClipper->SetHWnd (0, Fenetre);
        
        if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_CLIPPER_HWND);

        // Attache le clipper à la surface primaire
        ErrDd = SurfacePrimaire->SetClipper (SurfaceClipper);
        
        if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_CLIPPER_PRIMAIRE);
       
        ZeroMemory (&SurfaceDesc, sizeof(SurfaceDesc));
        SurfaceDesc.dwSize = sizeof(SurfaceDesc);
        SurfaceDesc.dwFlags = DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH;
        SurfaceDesc.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN;
        SurfaceDesc.dwWidth  = ResolutionX;
        SurfaceDesc.dwHeight = ResolutionY;

        // Création du backbuffer séparément
        ErrDd = DirectDraw7->CreateSurface (&SurfaceDesc,&SurfaceBack,NULL);
       
        if (ErrDd != DD_OK) return dx_Finalise (ERR_NO_BACKBUFFER);
    }

	if (PleinEcran) ShowCursor (false);

	return true;
}

//-----------------------------------------------------------------------------
// Name: dx_Finalise()
// Desc: Désaloue les objet de la mémoire
//-----------------------------------------------------------------------------
bool dx_Finalise (uint8 pErrNo)
{
    ErrNo = pErrNo;
    
	ShowCursor (true);

    Nettoyage (SurfaceClipper);
	Nettoyage (SurfacePrimaire);
	Nettoyage (DirectDraw7);
	
	for (uint8 No = 0; No < NombreSurfaces; No++)
	{
        Nettoyage (Surfaces[No]);
    }
    
    delete [] Surfaces;
	
	return false;
}

//-----------------------------------------------------------------------------
// Name: dx_Test()
// Desc: Tente de restaurer les objets s'ils sont perdus
//-----------------------------------------------------------------------------
bool dx_Test ()
{
     if (ErrDd == DD_OK) return true;
         
     if (ErrDd == DDERR_SURFACELOST)
     {
         dx_Restaure (); return true;
     }
         
     return dx_Finalise (ERR_NO_AFFICHE);
}

//-----------------------------------------------------------------------------
// Name: dx_Affiche()
// Desc: Affiche le contenu du buffer à l'écran
//-----------------------------------------------------------------------------
bool dx_Affiche ()
{
     if (PleinEcran)
     {
         ErrDd = SurfacePrimaire->Flip (0, DDFLIP_WAIT);
     }    
     else
     {
         RECT tRectSrc;
         RECT tRectDest;
         POINT tPosition = {0,0};

        // Copie de Surface suivant la position de la fenêtre
        ClientToScreen (Fenetre, &tPosition);
        GetClientRect  (Fenetre, &tRectDest);
        
        if (TailleFenetre)
             SetRect (&tRectSrc, 0, 0, tRectDest.right-tRectDest.left,
                                       tRectDest.bottom-tRectDest.top);
        else SetRect (&tRectSrc, 0, 0, ResolutionX, ResolutionY);
                                    
        OffsetRect (&tRectDest, tPosition.x, tPosition.y);
        
        ErrDd = SurfacePrimaire->Blt
        (&tRectDest,SurfaceBack,&tRectSrc,DDBLT_WAIT,NULL);
     }
     
     return dx_Test ();
};

//-----------------------------------------------------------------------------
// Name: dx_Restaure()
// Desc: Restaure les objets perdus (s'ils sont perdus)
//-----------------------------------------------------------------------------
void dx_Restaure ()
{
     if (SurfacePrimaire->IsLost () != DD_OK)
     {
         DirectDraw7->RestoreAllSurfaces ();
         (*Restaure)();
     }
}

//-----------------------------------------------------------------------------
// Name: dx_Efface()
// Desc: Efface le buffer d'affichage
//-----------------------------------------------------------------------------
bool dx_Efface (uint8 Rouge, uint8 Vert, uint8 Bleu)
{
	ZeroMemory (&BlitFX, sizeof(BlitFX));
	
	BlitFX.dwSize = sizeof (BlitFX);

	BlitFX.dwFillColor = RGB (Rouge,Vert,Bleu);

	SurfaceBack->Blt (NULL, NULL, NULL, DDBLT_COLORFILL | DDBLT_WAIT, &BlitFX);
	
    return dx_Test ();
}

//-----------------------------------------------------------------------------
// Name: dx_AccessMemoire(...)
// Desc: Vérouille/déverouille l'accès à la mémoire vidéo
//-----------------------------------------------------------------------------
bool dx_AccessMemoire (bool pVerrou)
{
	if (pVerrou)
	{
		SurfaceBack->Lock (NULL, &SurfaceDesc, DDLOCK_WAIT, NULL);
		
		Pitch = (int)SurfaceDesc.lPitch;
		Ecran = (BVRA*)SurfaceDesc.lpSurface;
	}
	else
	{
		SurfaceBack->Unlock (NULL);

		Pitch = 0;
		Ecran = NULL;
    }
    
	return dx_Test ();
}

//-----------------------------------------------------------------------------
// Name: dx_CopieMemoire(...)
// Desc: Copie le contenu d'une image dans le buffer
//-----------------------------------------------------------------------------
bool dx_CopieBVRA (BVRA* pImage, uint16 pPosX, uint16 pTailleX,
                                 uint16 pPosY, uint16 pTailleY)
{
     if (dx_GetEcran () == 0) return false;
     
     uint16 tPitch = dx_GetPitch ();
     BVRA*  tEcran = dx_GetEcran ();

     int sj = 0;
     int dj = pPosY*(tPitch>>2)+pPosX;
        
     for (int j = 0; j < pTailleY; j++)
     {
         memcpy ((void*)&tEcran[dj].R,
           (const void*)&pImage[sj].R, pTailleX*sizeof(BVRA));
                    
         sj += pTailleX;
         dj += (tPitch>>2);
     }
     
     return true;
}

//-----------------------------------------------------------------------------
// Name: dx_NombreGDI(...)
// Desc: Dessine un nombre / du texte en utilisant le GDI
//-----------------------------------------------------------------------------

bool dx_NombreGDI (float pNombre, uint8 pDecimales,
                   uint16 pPosX, uint16 pPosY, COLORREF pCouleur)
{
    // this function draws the sent text on the sent surface
    // using color index as the color in the palette

    HDC xdc; // the working dc

    // get the dc from surface
    if (FAILED (SurfaceBack->GetDC (&xdc))) return false;
    
    char pTexte[128];
    
    gcvt ((double)pNombre, pDecimales, pTexte);
    
    WCHAR Texte[128] = {0};
    MultiByteToWideChar (GetACP(), 0, pTexte, -1, Texte, 128);
        

    SetTextColor (xdc, pCouleur);       // set the colors for the text
    SetBkMode    (xdc, TRANSPARENT); // set background mode to transparent so black isn't copied
    TextOut      (xdc, pPosX, pPosY, Texte, strlen (pTexte)); // draw the text
 
    SurfaceBack->ReleaseDC (xdc); // release the dc

    return true;
}

bool dx_NombreGDI (uint32 pNombre, uint16 pPosX, uint16 pPosY, COLORREF pCouleur)
{
    // this function draws the sent text on the sent surface
    // using color index as the color in the palette

    HDC xdc; // the working dc

    // get the dc from surface
    if (FAILED (SurfaceBack->GetDC (&xdc))) return false;
    
    char pTexte[128];
    
    _itoa (pNombre, pTexte, 10);
    
    WCHAR Texte[128] = {0};
    MultiByteToWideChar (GetACP(), 0, pTexte, -1, Texte, 128);
        

    SetTextColor (xdc, pCouleur);       // set the colors for the text
    SetBkMode    (xdc, TRANSPARENT); // set background mode to transparent so black isn't copied
    TextOut      (xdc, pPosX, pPosY, Texte, strlen (pTexte)); // draw the text
 
    SurfaceBack->ReleaseDC (xdc); // release the dc

    return true;
}

bool dx_TexteGDI (char* pTexte, uint16 pPosX, uint16 pPosY, COLORREF pCouleur)
{
    // this function draws the sent text on the sent surface
    // using color index as the color in the palette

    HDC xdc; // the working dc

    // get the dc from surface
    if (FAILED (SurfaceBack->GetDC (&xdc))) return false;
    
    WCHAR Texte[128] = {0};
    MultiByteToWideChar (GetACP(), 0, pTexte, -1, Texte, 128);
        

    SetTextColor (xdc, pCouleur);       // set the colors for the text
    SetBkMode    (xdc, TRANSPARENT); // set background mode to transparent so black isn't copied
    TextOut      (xdc, pPosX, pPosY, Texte, strlen (pTexte)); // draw the text
 
    SurfaceBack->ReleaseDC (xdc); // release the dc

    return true;
}

//-----------------------------------------------------------------------------
// Name: dx_CreerSurface(...)
// Desc: Créé une des surfaces à disposition
//-----------------------------------------------------------------------------
bool dx_CreerSurface (uint8 pNoSurface, uint16 pTailleX, uint16 pTailleY)
{
   DDSURFACEDESC2 ddsd;
   
   if (pNoSurface >= NombreSurfaces) return false;

   ZeroMemory(&ddsd, sizeof(ddsd));
   ddsd.dwSize = sizeof(ddsd);
   ddsd.dwFlags = DDSD_CAPS | DDSD_WIDTH | DDSD_HEIGHT;
   ddsd.ddsCaps.dwCaps = DDSCAPS_OFFSCREENPLAIN;
   ddsd.dwWidth  = pTailleX;
   ddsd.dwHeight = pTailleY;
   ErrDd = DirectDraw7->CreateSurface (&ddsd, &Surfaces[pNoSurface], NULL);
   
   return ErrDd == DD_OK;
}

//-----------------------------------------------------------------------------
// Name: dx_CopieBitmap(...)
// Desc: Copie le contenu d'un bitmap dans une des surfaces à disposition
//-----------------------------------------------------------------------------
bool dx_CopieBitmap (uint8 pNoSurface,
                     HBITMAP pBitmap, uint16 pPosX, uint16 pTailleX,
                                      uint16 pPosY, uint16 pTailleY)
{
   HDC           hdcImage;
   HDC           hdc;
   BITMAP        bm;

   if (pNoSurface >= NombreSurfaces) return false;
   if (Surfaces[pNoSurface] == NULL) return false;

   if (pBitmap == NULL) return false;

   Surfaces[pNoSurface]->Restore();

   hdcImage = CreateCompatibleDC (NULL);
   SelectObject (hdcImage, pBitmap);
   GetObject (pBitmap, sizeof(bm), &bm);
   
   pTailleX = pTailleX == 0 ? bm.bmWidth  : pTailleX;
   pTailleY = pTailleY == 0 ? bm.bmHeight : pTailleY;

   Surfaces[pNoSurface]->GetDC(&hdc);
   
   BitBlt (hdc, pPosX, pPosY, pTailleX, pTailleY, hdcImage, 0, 0, SRCCOPY);
   
   Surfaces[pNoSurface]->ReleaseDC(hdc);

   DeleteDC (hdcImage);
   
   return true;
}

//-----------------------------------------------------------------------------
// Name: dx_CopieBitmap(...)
// Desc: Copie le contenu d'un bitmap dans le buffer d'affichage
//-----------------------------------------------------------------------------
bool dx_CopieBitmap (HBITMAP pBitmap, uint16 pPosX, uint16 pTailleX,
                                      uint16 pPosY, uint16 pTailleY)
{
   HDC           hdcImage;
   HDC           hdc;
   BITMAP        bm;

   if (pBitmap == NULL) return false;

   SurfaceBack->Restore();

   hdcImage = CreateCompatibleDC (NULL);
   SelectObject (hdcImage, pBitmap);
   GetObject (pBitmap, sizeof(bm), &bm);
   
   pTailleX = pTailleX == 0 ? bm.bmWidth  : pTailleX;
   pTailleY = pTailleY == 0 ? bm.bmHeight : pTailleY;

   SurfaceBack->GetDC(&hdc);
   
   BitBlt (hdc, pPosX, pPosY, pTailleX, pTailleY, hdcImage, 0, 0, SRCCOPY);
   
   SurfaceBack->ReleaseDC(hdc);

   DeleteDC (hdcImage);
   
   return true;
}

//-----------------------------------------------------------------------------
// Name: dx_SurfaceChargeBMP(...)
// Desc: Charge le contenu d'un fichier bitmap dans un des surfaces...
//-----------------------------------------------------------------------------
bool dx_SurfaceChargeBMP (uint8 pNoSurface, char* pNomBMP,
                          uint16 pTailleX, uint16 pTailleY)
{
   if (!dx_CreerSurface (pNoSurface, pTailleX, pTailleY)) return false;
   
   return dx_SurfaceRestaureBMP (pNoSurface, pNomBMP);
}

//-----------------------------------------------------------------------------
// Name: dx_SurfaceRestaureBMP(...)
// Desc: Restaure le contenu d'un des surfaces d'affichage (avec un bitmap)
//-----------------------------------------------------------------------------
bool dx_SurfaceRestaureBMP (uint8 pNoSurface, char* pNomBMP)
{
   HBITMAP hBitmap;
   
   ut_ChargerBitmap (&hBitmap, pNomBMP);
   
   if (!dx_CopieBitmap (pNoSurface, hBitmap, 0, 0, 0, 0))
    return false;
   
   ut_FermerBitmap (hBitmap);
   
   return true;
}

//-----------------------------------------------------------------------------
// Name: dx_SurfaceCopie(...)
// Desc: Copie le contenu d'une surface dans le buffer d'affichage
//-----------------------------------------------------------------------------
bool dx_SurfaceCopie (uint8 pNoSurface, uint16 pPosX, uint16 pPosY)
{
    DDSURFACEDESC2 ddsd;
    ZeroMemory ((void*)&ddsd, sizeof(ddsd));
    ddsd.dwSize = sizeof(ddsd);
    ddsd.dwFlags = DDSD_HEIGHT | DDSD_WIDTH;
    
    Surfaces[pNoSurface]->GetSurfaceDesc (&ddsd);
    
    RECT rDest = {pPosX, pPosY, pPosX+ddsd.dwWidth-1, pPosY+ddsd.dwHeight-1};
    
    return (ErrDd = SurfaceBack->Blt (&rDest, Surfaces[pNoSurface], NULL,
                                          DDBLT_WAIT, NULL)) == DD_OK;
}

/*
//-------------------------------------------------------------------------
// Name: Draw_Rectangle_GDI()
// Desc: Draw a rectangle on the screen using GDI function
//-------------------------------------------------------------------------
INT Draw_Rectangle_GDI(int x1, int y1, int x2, int y2,
LPDIRECTDRAWSURFACE7 lpdds)
{
// this function draws a rectangle on the sent surface

HDC xdc; // the working dc

// get the dc from surface
if( FAILED(lpdds->GetDC(&xdc)) )
return 0;

// draw the rectangle
Rectangle(xdc, x1, y1, x2, y2);

// release the dc
lpdds->ReleaseDC(xdc);

return 1;
}*/
