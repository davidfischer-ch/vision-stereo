//=============================================================--
// Nom de l'étudiant : David FISCHER TE3
// Nom du projet     : Caméra CMOS 2006
// Nom du C++        : ImageBMP.h
// Nom du processeur : Cyclone - EP1C12F256C7
//=============================================================--

#define  BYTE  unsigned char
#define  DWORD unsigned long int
#define SDWORD long int

//=======================================================================--

struct RVB { BYTE R,V,B; };

const RVB rvbNOIR   = {  0,  0,  0};
const RVB rvbBLANC  = {255,255,255};
const RVB rvbROUGE  = {255,  0,  0};
const RVB rvbVERT   = {  0,255,  0};
const RVB rvbBLEU   = {  0,  0,255};
const RVB rvbVIOLET = {255,  0,255};
const RVB rvbJAUNE  = {255,255,  0};
const RVB rvbCYAN   = {  0,255,255};

struct XY { int X,Y; };

class Image
{
public:
  DWORD  TailleX;
  SDWORD TailleY;
 
  BYTE *Rouge;
  BYTE *Vert;
  BYTE *Bleu;
  
public:
  bool Charge (string pNomFichier);
  void Copie  (Image  &pSource);
  void Enreg  (string pNomFichier);
  void Ferme  ();
  
  RVB  LePixel  (int pPosX, int pPosY);
  int  LePixelL (int pPosX, int pPosY);
  void EcPixel (int pPosX, int pPosY, RVB pValeure);
  void EcCroix (int pPosX, int pPosY, RVB pValeure);
};
