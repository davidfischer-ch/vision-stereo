//=============================================================--
// Nom de l'étudiant : David FISCHER TE3
// Nom du projet     : Caméra CMOS 2006
// Nom du C++        : ImageBMP.cpp
// Nom du processeur : Cyclone - EP1C12F256C7
//=============================================================--

#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>

using namespace std;

#include "bmp_io.H"

#include "ImageBMP.h"

//=======================================================================--

// Charge une Image d'un fichier BMP
bool Image::Charge (string pNomFichier)
{
     Rouge = Vert = Bleu = NULL;
     
     return bmp_read ((char*)pNomFichier.c_str(),
                      &TailleX, &TailleY, &Rouge, &Vert, &Bleu);
}

void Image::Copie (Image &pSource)
{
    TailleX = pSource.TailleX;
    TailleY = pSource.TailleY;
 
    Rouge = new BYTE[TailleX*TailleY];
    Vert  = new BYTE[TailleX*TailleY];
    Bleu  = new BYTE[TailleX*TailleY];
  
    memcpy (Rouge, pSource.Rouge, TailleX*TailleY);
    memcpy (Vert,  pSource.Vert,  TailleX*TailleY);
    memcpy (Bleu,  pSource.Bleu,  TailleX*TailleY);
}

// Enregistre une Image d'un fichier BMP
void Image::Enreg (string pNomFichier)
{
    bmp_24_write ((char*)pNomFichier.c_str(),
                  TailleX, TailleY, Rouge, Vert, Bleu);
}

// Ferme l'Image
void Image::Ferme ()
{
     delete[] Rouge;
     delete[] Vert;
     delete[] Bleu;
}

// Lecture du Pixel de position X,Y
RVB Image::LePixel (int pPosX, int pPosY)
{
    int tPos = pPosY*TailleX+pPosX;
    
    RVB tRVB = {Rouge[tPos]+Vert[tPos]+Bleu[tPos]};
    
    return tRVB;
}

int Image::LePixelL (int pPosX, int pPosY)
{
    int tPos = pPosY*TailleX+pPosX;
    
    return (Rouge[tPos]+Vert[tPos]+Bleu[tPos])/3;
}

// Ecriture du Pixel de position X,Y
void Image::EcPixel (int pPosX, int pPosY, RVB pValeure)
{
    int tPos = pPosY*TailleX+pPosX;
    
    Rouge[tPos] = pValeure.R;
    Vert [tPos] = pValeure.V;
    Bleu [tPos] = pValeure.B;
}

// Dessine une Croix à l'emplacement spécifié
void Image::EcCroix (int pPosX, int pPosY, RVB pValeure)
{
    EcPixel (pPosX,   pPosY,   pValeure);
    EcPixel (pPosX-1, pPosY,   pValeure);
    EcPixel (pPosX+1, pPosY,   pValeure);
    EcPixel (pPosX,   pPosY-1, pValeure);
    EcPixel (pPosX,   pPosY+1, pValeure);
    
/*    EcPixel (pPosX-1, pPosY-1, rvbBLANC);
    EcPixel (pPosX-1, pPosY+1, rvbBLANC);
    EcPixel (pPosX+1, pPosY-1, rvbBLANC);
    EcPixel (pPosX+1, pPosY+1, rvbBLANC);*/
}
