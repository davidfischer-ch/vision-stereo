//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du H            : main_graphique
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

enum TypeTG { RVB, C1,C2,C3 };

void Rectangle (BVRA* pBVRA, int pFacteur,
                int pDestX, int pTailleX, int pTitiX,
                int pDestY, int pTailleY, int pTitiY);

void TraitementGraphique (BVRA* pBVRA, int pFacteur, TypeTG pTypeTG);

void TraitementTextuel   ();

//-----------------------------------------------------------------------------
// Name: Rectangle(...)
// Desc: Dessine un 'pixel' suivant sa position, taille et sa source...
//-----------------------------------------------------------------------------

void Rectangle (BVRA* pBVRA, int pFacteur, TypeTG pTypeTG,
                int pDestX, int pTailleX, int pTitiX,
                int pDestY, int pTailleY, int pTitiY)
{  
   RVB_HSL tRVB = {ImageTITI.Lignes[pTitiY].Pixels[pTitiX].H,
                   ImageTITI.Lignes[pTitiY].Pixels[pTitiX].S,
                   ImageTITI.Lignes[pTitiY].Pixels[pTitiX].L};

   // Vraiment besoin d'une conversion HSL à RVB ?
   if (ImageTITI.Type && pTypeTG == RVB) tRVB = ut_HSL_a_RVB (tRVB, fH,fS,fL);

   int MaxX = TAILLE_RVB_X*pFacteur;
   //int MaxY = TAILLE_RVB_Y*pFacteur;

//   if (ImageTITI.Type)
   {
       switch (pTypeTG) // Couches H,S,L
       {
       case RVB: break;
       case C1: tRVB.S = 255;tRVB.L = 128;tRVB=ut_HSL_a_RVB(tRVB,fH,1,1);break;
       case C2: tRVB.H = 0;  tRVB.L = 128;tRVB=ut_HSL_a_RVB(tRVB,1,fS,1);break;
       case C3: tRVB.H = 0;  tRVB.S = 0;  tRVB=ut_HSL_a_RVB(tRVB,1,1,fL);break;
       }
    }
  /*  else // Source en RVB...
    {
       switch (pTypeTG) // Couches R,V,B
       {
       case RVB: break;
       case C1: tRVB.V = tRVB.B = 0; break;
       case C2: tRVB.R = tRVB.B = 0; break;
       case C3: tRVB.R = tRVB.V = 0; break;
       }
   }*/
    
   BVRA Couleur = {tRVB.B, tRVB.V, tRVB.R, 255};
   
   for (int y = pDestY*pFacteur; y < (pDestY+pTailleY)*pFacteur; y++)
   for (int x = pDestX*pFacteur; x < (pDestX+pTailleX)*pFacteur; x++)
   {
       memcpy ((void*)&pBVRA[y*MaxX+x], (const void*)&Couleur, sizeof (BVRA));
   }
}

//-----------------------------------------------------------------------------
// Name: TraitementGraphique()
// Desc: Affiche l'image provenant du système embarqué (+zones)
//-----------------------------------------------------------------------------

int compteur = 0;

void TraitementGraphique (BVRA* pBVRA, int pFacteur, TypeTG pTypeTG)
{    /*compteur = 0;
    
    for (int y = 0; y < TAILLE_TITI_Y; y++)
    {
     for (int x = 0; x < TAILLE_TITI_X; x++)
     {
     ImageTITI.Lignes[y].Pixels[x].R = compteur;
     ImageTITI.Lignes[y].Pixels[x].V = 100-compteur;
     ImageTITI.Lignes[y].Pixels[x].B = 64;
     }
     compteur += 64;
    }*/
    
    int dy = TAILLE_RVB_Y-1;
    
    for (int y = TAILLE_TITI_Y-1; y >= 0; y--)
    {
        int x = ImageTITI.Lignes[y].Nombre-1;
        
        // Ligne figurantt dans une Bande ayant des Détails?
        if (y >= nPerPerY && y < nPerPerY+nDetDetY)
        {
            // Si la source est une Bande Mixée...
            if (x == nPerPerX*2+nDetDetX-1)
            {          
                int dx = TAILLE_RVB_X-1;
                
                while (x >= nPerPerX+nDetDetX)
                {
                    Rectangle (pBVRA, pFacteur, pTypeTG,
                               dx-nDefCfgPerMoyX+1, nDefCfgPerMoyX, x,
                               dy-nDefCfgPerMoyY+1, nDefCfgPerMoyY, y);
                    x--;
                    
                    dx -= nDefCfgPerMoyX;
                }
                
               while (x >= nPerPerX)
                {
                    Rectangle (pBVRA, pFacteur, pTypeTG,
                               dx-nDefCfgDetMoyX+1, nDefCfgDetMoyX, x,
                               dy-nDefCfgDetMoyY+1, nDefCfgDetMoyY, y);
                    x--;
                    
                    dx -= nDefCfgDetMoyX;
                }
                
               while (x >= 0)
                {
                    Rectangle (pBVRA, pFacteur, pTypeTG,
                               dx-nDefCfgPerMoyX+1, nDefCfgPerMoyX, x,
                               dy-nDefCfgPerMoyY+1, nDefCfgPerMoyY, y);
                    x--;
                    
                    dx -= nDefCfgPerMoyX;
                }                
                
                // Une Ligne de faite...
                dy -= nDefCfgDetMoyY;
            }
            // Si la source est une Bande 100% Détaillée
            else /*if (x == nDetDetX-1)*/
            {
                int dx = TAILLE_RVB_X-nPerPerX*nDefCfgPerMoyX-1;
                
                while (x >= 0)
                {
                    Rectangle (pBVRA, pFacteur, pTypeTG,
                               dx-nDefCfgDetMoyX+1, nDefCfgDetMoyX, x,
                               dy-nDefCfgDetMoyY+1, nDefCfgDetMoyY, y);
                    x--;
                    
                    dx -= nDefCfgDetMoyX;
                }
                // Une Ligne de faite...
                dy -= nDefCfgDetMoyY;
            }
            // Sinon Bug .. on ne fait rien!
            /*else
            {
                //return;
            }*/
        }
        // Ligne figurante dans une Bande 100% Périphérique
        else
        {
            x = nPerPerX*2+nPerDetX-1;
            // Si la Source à la bonne Taille OK
            if (x == nPerPerX*2+nPerDetX-1)
            {
                int dx = TAILLE_RVB_X-1;
                
                while (x >= 0)
                {
                    Rectangle (pBVRA, pFacteur, pTypeTG,
                               dx-nDefCfgPerMoyX+1, nDefCfgPerMoyX, x,
                               dy-nDefCfgPerMoyY+1, nDefCfgPerMoyY, y);
                    x--;
                    
                    dx -= nDefCfgPerMoyX;
                }
                // Une Ligne de faite...
                dy -= nDefCfgPerMoyY;
            }
            // Sinon Bug .. on utilise la bonne Taille!
            else
            {
                //return;
            }
        }
    }
}
