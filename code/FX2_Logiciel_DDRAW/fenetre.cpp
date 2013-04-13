//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du C++          : Fenetre
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

#define DAVID_FENETRE
#include "david_fischer.h"

static LRESULT CALLBACK WindowProc (HWND hWnd,
                                    unsigned uMsg,
                                    WPARAM wParam,
                                    LPARAM lParam); // caché
                                    
static char* ErrTxt[4] = {"FE - Tout est OK!\n",
                          "FE - Erreur de votre part!\n",
                          "FE - Erreur RegisterClass\n",
                          "FE - Erreur CreateWindow\n"};

static HWND	    Handle = NULL;
static WNDCLASS Classe;

static WCHAR NomClasse  [128] = {0};
static WCHAR TitreClasse[128] = {0};

static uint16 PosL = 0;
static uint16 PosH = 0;
static uint16 Largeur = 0;
static uint16 Hauteur = 0;

static bool Active = true;
static bool Focus  = true;

static uint8 ErrNo = 0;

// FONCTIONS UTILISATEUR APPELÉES

void (*Nettoyage)();
void (*Affichage)();
void (*MessageFenetre)(HWND hWnd, unsigned uMsg, WPARAM wParam, LPARAM lParam);

// FONCTIONS DE NOTRE CRU

HWND fe_GetHandle () { return Handle; };

uint16 fe_GetPosL    () { return PosL;    };
uint16 fe_GetPosH    () { return PosH;    };
uint16 fe_GetLargeur () { return Largeur; };
uint16 fe_GetHauteur () { return Hauteur; };

bool fe_GetActive () { return Active; };
bool fe_GetFocus  () { return Focus;  };

uint16 fe_GetLargeurEcran () { return GetSystemMetrics(SM_CXSCREEN); };
uint16 fe_GetHauteurEcran () { return GetSystemMetrics(SM_CYSCREEN); };

uint8 fe_GetErrNo () { return ErrNo; };

static char Erreur_Tampon[64];

//-----------------------------------------------------------------------------
// Name: fe_GetErrTxt()
// Desc: Retourne un texte décrivant l'erreur en cours
//-----------------------------------------------------------------------------
char* fe_GetErrTxt ()
{
    memcpy ((void*)Erreur_Tampon,
            (const void*)&ErrTxt[ErrNo], strlen(ErrTxt[ErrNo])+1);

    return Erreur_Tampon;
}

//-----------------------------------------------------------------------------
// Name: fe_Message(...)
// Desc: Affiche un message (erreur) dans un boîte de dialogue
//-----------------------------------------------------------------------------
void fe_Message (char* pMessage)
{
	if (pMessage)
	{
        WCHAR Message[128] = {0};
        MultiByteToWideChar (GetACP(), 0, pMessage, -1, Message, 128);
		MessageBox (NULL, Message, TitreClasse, MB_OK);
	}
}

//-----------------------------------------------------------------------------
// Name: fe_InitVars()
// Desc: Initialise les variables internes
//-----------------------------------------------------------------------------
void fe_InitVars () // caché
{
    Handle = NULL;
    
    NomClasse  [0] = 0;
    TitreClasse[0] = 0;
	
	PosL = 0;
	PosH = 0;
	Largeur = 0;
	Hauteur = 0;
	
	Focus = true;

    ErrNo = 0;
    
    Nettoyage = NULL;
    Affichage = NULL;
    MessageFenetre = NULL;
}

//-----------------------------------------------------------------------------
// Name: fe_Initialise(...)
// Desc: Initialise et configure une Fenêtre
//-----------------------------------------------------------------------------
bool fe_Initialise (HINSTANCE pInstance,
				   char*	 pNomClasse,
				   char*	 pTitreClasse,
				   uint16    pPosL, uint16 pLargeur,
				   uint16    pPosH, uint16 pHauteur,
                   void (*pNettoyage)(),
                   void (*pAffichage)(),
                   void (*pMessageFenetre)
                   (HWND hWnd, unsigned uMsg, WPARAM wParam, LPARAM lParam))
{
    if (Handle != NULL) return fe_Finalise (ERR_NO_UTILISATEUR);

    MultiByteToWideChar (GetACP(), 0, pNomClasse,   -1, NomClasse,   128);
    MultiByteToWideChar (GetACP(), 0, pTitreClasse, -1, TitreClasse, 128);
	
	PosL = pPosL;
	PosH = pPosH;
	Largeur = pLargeur;
	Hauteur = pHauteur;

    Nettoyage = pNettoyage;
    Affichage = pAffichage;
    MessageFenetre = pMessageFenetre;
	
	Classe.style         = CS_HREDRAW | CS_VREDRAW;
	Classe.lpfnWndProc   = (WNDPROC) WindowProc;
	Classe.cbClsExtra    = 0;
	Classe.cbWndExtra    = sizeof(DWORD);
	Classe.hInstance     = pInstance;
	Classe.hIcon         = NULL;
	Classe.hCursor       = LoadCursor (NULL, IDC_ARROW);
	Classe.hbrBackground = (HBRUSH) GetStockObject (BLACK_BRUSH);
	Classe.lpszClassName = NomClasse;

	if (!RegisterClass (&Classe)) return fe_Finalise (ERR_NO_FENETRE_CLASSE);

	Handle = CreateWindow (NomClasse,
                           TitreClasse, WS_VISIBLE | WS_POPUP,
                           PosL, PosH, Largeur, Hauteur,
                           NULL, NULL, pInstance, NULL);

	if (!Handle) return fe_Finalise (ERR_NO_FENETRE_CREATE);

	ShowWindow   (Handle, SW_SHOW);
	UpdateWindow (Handle);

	return true;
}

//-----------------------------------------------------------------------------
// Name: fe_Finalise(...)
// Desc: Désaloue les objets de la mémoire
//-----------------------------------------------------------------------------
bool fe_Finalise (uint8 pErrNo)
{
    ErrNo = pErrNo;
    
    UnregisterClass (NomClasse, NULL);
    
    Handle = NULL;
	
	return false;
}

//-----------------------------------------------------------------------------
// Name: fe_Boucle()
// Desc: Boucle de récupération des message
//-----------------------------------------------------------------------------
int fe_Boucle ()
{
	MSG msg;

    while (true)
    {
         if (PeekMessage (&msg, NULL, 0, 0, PM_NOREMOVE))
  	 	 {
  	 	     if (!GetMessage(&msg, NULL, 0, 0)) return msg.wParam;
  	 	     
	         TranslateMessage (&msg);
  	 	     DispatchMessage  (&msg);
  	 	 }
  	 	 else if (fe_GetActive ()) { (*Affichage)(); }
  	 	 else                      {  WaitMessage(); }
    }

	return msg.wParam;
}

//-----------------------------------------------------------------------------
// Name: WindowProc
// Desc: Procédure de la Fenêtre appelée par Windows
//-----------------------------------------------------------------------------
static LRESULT CALLBACK WindowProc (HWND hWnd,
                                    unsigned uMsg,
                                    WPARAM wParam,
                                    LPARAM lParam)
{
	if (uMsg == WM_CREATE)
	{
		/*LPCREATESTRUCT pCs = reinterpret_cast< LPCREATESTRUCT >(lParam);
		pFenetre = (Fenetre*)(pCs->lpCreateParams);
		SetWindowLong (hWnd, GWL_USERDATA, (LONG)(pFenetre));*/
	}
	else
	{
		/*if (pFenetre)
		{*/
		switch (uMsg)
		{
		case WM_KEYDOWN:

			switch (wParam)
			{
                case VK_ESCAPE:
					DestroyWindow (hWnd);
					break;
			}
			break;

        case WM_ACTIVATE:

 	 	    Active = !((BOOL)HIWORD(wParam));
 	 	    break;
 
		case WM_DESTROY:
		    (*Nettoyage)();
			PostQuitMessage(0);
			break;

		case WM_SETFOCUS:
			Focus = true;
			break;

		case WM_KILLFOCUS:
			Focus = false;
			break;

		default:
            // Passe le Message à la Fonction Utilisateur
            (*MessageFenetre)(hWnd, uMsg, wParam, lParam);
			return DefWindowProc (hWnd, uMsg, wParam, lParam);
		}
			
		// Passe le Message à la Fonction Utilisateur
		(*MessageFenetre)(hWnd, uMsg, wParam, lParam);
	}

	return 0;
}
