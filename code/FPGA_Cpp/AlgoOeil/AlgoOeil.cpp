//=============================================================--
// Nom de l'étudiant : David FISCHER TE3
// Nom du projet     : Caméra CMOS 2006
// Nom du C++        : AlgoImage.cpp
// Nom du processeur : Cyclone - EP1C12F256C7
//=============================================================--

#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <math.h>

#include <string>

using namespace std;

#include "ImageBMP.h"
#include "AlgoOeil.h"

const XY cDelta = {5,5};

const int   cSeuilTrou  = 4;
const float cSeuilNoir  = 0.04; //0.10; web
const float cSeuilBlanc = 0.08; //0.03; web
const float cFactTaille = 0.04; //0.06; web

#include "AlgoCroix.h"
#include "AlgoBary.h"
#include "Histogramme.h"
#include "Seuils_Calcul.h"
#include "Seuils_Centres.h"
#include "Seuils_Arrange.h"
#include "Seuils_Morpho.h"
#include "Seuils_Blob.h"

//=======================================================================--

bool AlgoOeil::Charge (string pNom)
{
  Nom = string(pNom);
  
  if (Oeil.Charge ("yeux/"+Nom+string(".bmp"))) return true;
  
  Tab_Seuils = new SEUIL[Oeil.TailleX*Oeil.TailleY];
  
  return false;
}

void AlgoOeil::Ferme ()
{
  Oeil.Ferme ();
  delete [] Tab_Seuils;
}

void AlgoOeil::Options (bool pAffCalcOK, bool pAffHistoOK)
{
    AffCalcOK  = pAffCalcOK;
    AffHistoOK = pAffHistoOK;
}
                
void AlgoOeil::Remplissage (Blob *pBlob, int pX, int pY, SEUIL pIn, SEUIL pOut)
{
    if (pX < 0 || pX >= Oeil.TailleX ||
        pY < 0 || pY >= Oeil.TailleY) return;
    
    SEUIL cp = Tab_Seuils[pY*Oeil.TailleX+pX];
  
    if (cp == pIn)
    {
        pBlob->CentreX+=pX; pBlob->VarianceX+=pX*pX;
        pBlob->CentreY+=pY; pBlob->VarianceY+=pY*pY;
        pBlob->Nombre++;
        
        Tab_Seuils[pY*Oeil.TailleX+pX] = pOut;
        
        Remplissage (pBlob, pX,pY+1, pIn,pOut);
        Remplissage (pBlob, pX,pY-1, pIn,pOut);
        Remplissage (pBlob, pX+1,pY, pIn,pOut);
        Remplissage (pBlob, pX-1,pY, pIn,pOut);
    }
}
          
float AlgoOeil::Traitement (int pSerie, int pCentreX, int pCentreY,
                                        int    pOldX, int    pOldY)
{
    char tSerie[3];
    
    itoa(pSerie, tSerie, 10);
    
    if (pSerie < 10) { tSerie[2] = tSerie[1];
                       tSerie[1] = tSerie[0]; tSerie[0] = '0'; }
                       
    if (pSerie == 0) { pOldY = Oeil.TailleY-pOldY;}
    
    pCentreY = Oeil.TailleY-pCentreY;
    
    CentrePupilleOld.X = pOldX;
    CentrePupilleOld.Y = pOldY;
    CentreManuel.X = CentrePupille.X = CentreBlanc.X = CentreNoir.X = pCentreX;
    CentreManuel.Y = CentrePupille.Y = CentreBlanc.Y = CentreNoir.Y = pCentreY;
    
    //---------------------------------------------------------------------
    // Calcul de l'Histogramme de l'Image de Oeil

    Histogramme ();

    //---------------------------------------------------------------------
    // 1er Indice : La Pupille ne peut être que dans une certaine zone
    //              autour de l'ancienne position (+-deltaX,+-deltaY)

    TaillePupille.X = (int)(Oeil.TailleX*cFactTaille); // En ~% de la Largeur
    TaillePupille.Y = (int)(Oeil.TailleY*cFactTaille); // En ~% de la Hauteur

    //-------------------------------------------------------------------------
    // 3ème Indice : Le seuillage noir nous donne la Pupille et les Cils (SN)
    //               Le seuillage blanc nous donne le Blanc de l'Oeil    (SB)
    //               A partir de SB -> barycentre ~ centre Pupille (BSB)
    //               A partir de BSB -> zone de SN d'intérêt (Clipping) (BCSN)

    // Calcul des Seuils Noir&Blanc

    Seuils_Calcul ();

    //if (MorphoOK) Seuils_Morpho ();
    
    Seuils_Arrange ();
    
    Seuils_Blob ();
    
    Seuils_Centres ();
    
    //---------------------------------------------------------------------
    // Algorithme de la Croix par l'Ancien Centre
    
    //AlgoCroix ();

    //---------------------------------------------------------------------
    // Synthèse des Indices pour trouver la Pupille de façon cohérente
    
    //AlgoBary ();
    
    CentrePupille.X = CentreNoir.X;
    CentrePupille.Y = CentreNoir.Y;

    //---------------------------------------------------------------------
    // Affichage (dans des Images BMP) du Résultat

    // Résultat de l'Histogramme ...
    if (AffHistoOK)
    {
        Image tTab_Histo;
        if (tTab_Histo.Charge ("yeux/blanc.bmp")) return 0;
    
        int tMax = 0;
        
        for (int tNo = 0; tNo < 256; tNo++)
        {   // Maximum de l'Histogramme -> mise en page
            if (Tab_Histo[tNo] > tMax) tMax = Tab_Histo[tNo];
        }
        
        for (int tNo = 0; tNo < 256; tNo++)
        {
            RVB tChoix = tNo <= SeuilNoir  ? rvbVIOLET :
                        (tNo >= SeuilBlanc ? rvbBLEU : rvbVERT);
            
            for (int tNb = 0; tNb < (128*Tab_Histo[tNo])/tMax; tNb++)
            {   // Dessine la Barre [No] en Couleur!
                tTab_Histo.EcPixel(tNo,tNb,tChoix);
            }
        }
         
        tTab_Histo.Enreg ("resultats/"+Nom+"H_"+tSerie+".bmp");
        tTab_Histo.Ferme ();
    }
     
    // Résultat du Seuillage ...
    if (AffCalcOK)
    {                     
        Image tCalc;
        if (tCalc.Charge ("yeux/"+Nom+".bmp")) return 0;
         
        for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
        {
            for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
            {
                int tPos = tPosY*Oeil.TailleX+tPosX;
                
                RVB tRVB = rvbBLANC;
                
                switch (Tab_Seuils[tPos])
                {
                case NOIR   : tRVB = rvbVIOLET; break;
                case NEUTRE : tRVB = rvbNOIR;   break;
                case BLANC  : tRVB = rvbBLEU;   break;
                case BLOB   : tRVB = rvbBLANC;  break;
                }
                // Dessine le Pixel suivant sa Catégorie (Seuil)
                tCalc.EcPixel (tPosX,tPosY,tRVB);
            }
        }
                
        tCalc.EcCroix (CentrePupilleOld.X, CentrePupilleOld.Y, rvbROUGE); 
        tCalc.EcCroix (CentreBlanc.X,      CentreBlanc.Y,      rvbBLEU);
        tCalc.EcCroix (CentreNoir.X,       CentreNoir.Y,       rvbVIOLET);
        tCalc.EcCroix (CentreManuel.X,     CentreManuel.Y,     rvbJAUNE);
        tCalc.EcCroix (CentrePupille.X,    CentrePupille.Y,    rvbVERT);
          
        tCalc.Enreg ("resultats/"+Nom+"C_"+tSerie+".bmp");
        tCalc.Ferme ();
    }
    
    // Réglage des Niveaux pour mieux voir l'Image
    
    /*float tOffset  = SeuilNoir;
    float tFacteur = 256.0/(SeuilBlanc-SeuilNoir);
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {
            float L = (float)Oeil.LePixelL(tPosX,tPosY);
            
            L = (L-tOffset)*tFacteur;
            
            RVB tRVB;
            
            tRVB.R = L < 0 ? 0 : (L > 255 ? 255 : L);
            tRVB.V = L < 0 ? 0 : (L > 255 ? 255 : L);
            tRVB.B = L < 0 ? 0 : (L > 255 ? 255 : L);
                       
            Oeil.EcPixel(tPosX,tPosY,tRVB);
        }
    }*/
    
    // Positions Calculées...
    /*Oeil.EcCroix (CentrePupilleOld.X, CentrePupilleOld.Y, rvbROUGE);
    Oeil.EcCroix (CentreBlanc.X,      CentreBlanc.Y,      rvbBLEU);
    Oeil.EcCroix (CentreNoir.X,       CentreNoir.Y,       rvbVIOLET);
    Oeil.EcCroix (CentreManuel.X,     CentreManuel.Y,     rvbJAUNE);
    Oeil.EcCroix (CentrePupille.X,    CentrePupille.Y,    rvbVERT);
    Oeil.Enreg   ("resultats/"+Nom+"B_"+tSerie+".bmp");


    //---------------------------------------------------------------------
    // Statistiques sur le Traitement*/
    
    float tErreurX = (CentreManuel.X-CentrePupille.X); tErreurX *= tErreurX;
    float tErreurY = (CentreManuel.Y-CentrePupille.Y); tErreurY *= tErreurY;
    float tErreur  = sqrt (tErreurX+tErreurY);

    return tErreur;
}
    
/*void algo_delta_centre (Image *pImage, int old_x, int old_y)
{
     float rx = (plus_x+moins_x)/2;
     float ry = (plus_y+moins_y)/2;
     
     float r = rx > ry ? rx : ry;
     
     /*float x1 = old_x-moins_x, y1 = old_y;
     float x3 = old_x+plus_x,  y3 = old_y+1;
     float x2 = old_x,         y2 = old_y-moins_y;
     float xc = (((x3*x3-x2*x2+y3*y3-y2*y2)/(2*(y3-y2))-(x2*x2-x1*x1+y2*y2-y1*y1)/(2*(y2-y1))))
               /((x2-x1)/(y2-y1)-(x3-x2)/(y3-y2));
     float yc = (x2-x1)/(y2-y1)*xc+(x2*x2-x1*x1+y2*y2-y1*y1)/(2*(y2-y1));
     
     cout << xc << " " << yc << endl;

     EcPixel(pImage,xc,yc,255,1);
}*/
