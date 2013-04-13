void AlgoOeil::Seuils_Calcul ()
{
    int tTotal = Oeil.TailleX*Oeil.TailleY;
        
    int tNombreNoir = 0;
    for (SeuilNoir = 0; SeuilNoir < 256; SeuilNoir++)
    {   // Nous voulons que cSeuilNoir ~% des Pixels soient
        tNombreNoir += Tab_Histo[SeuilNoir]; // pris comme Noirs
        if (tNombreNoir >= tTotal*cSeuilNoir) break;
    }
    
    int tNombreBlanc = 0;
    for (SeuilBlanc = 255; SeuilBlanc > SeuilNoir; SeuilBlanc--)
    {   // Nous voulons que cSeuilBlanc ~% des Pixels soient
        tNombreBlanc += Tab_Histo[SeuilBlanc]; // pris comme Blancs
        if (tNombreBlanc >= tTotal*cSeuilBlanc) break;
    }

    // Seuillage dans l'Image
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            bool tNoir  = Oeil.LePixelL(tPosX,tPosY) <= SeuilNoir;
            bool tBlanc = Oeil.LePixelL(tPosX,tPosY) >= SeuilBlanc;
            // Tab_Seuils représente l'Image avec les Zones Seuillées
            Tab_Seuils[tPos] = tNoir ? NOIR : (tBlanc ? BLANC : NEUTRE);
        }
    }
}
