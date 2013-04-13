void AlgoOeil::Seuils_Arrange ()
{
    // Bouche les trous en X!
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        int tDelta = 0;
        int tMaintien = 0;
        bool tInterieur = false;
        
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            // Départ d'une Ligne
            if (tInterieur == false && Tab_Seuils[tPos] == NOIR)// != NEUTRE)
            {
                tInterieur = true;
                tDelta     = tPos;
                tMaintien  = tPos;
            }
            
            // Un pixel nous permet de continuer la Ligne
            if (tInterieur == true && Tab_Seuils[tPos] == NOIR)
            {
               tMaintien = tPos;
            }
            
            // Nous venons de finir une Ligne
            if (tInterieur == true && tPos-tMaintien > cSeuilTrou)
            {
                tInterieur = false;
                
                // Remplissage de la Ligne
                for (tDelta++; tDelta < tMaintien; tDelta++)
                {
                    Tab_Seuils[tDelta] = NOIR;//Tab_Seuils[tPos];
                }
            }
        }
    }
    
    // Bouche les trous en Y!
    
    for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
    {
        int tDelta = 0;
        int tMaintien = 0;
        bool tInterieur = false;
        
        for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            // Départ d'une Ligne
            if (tInterieur == false && Tab_Seuils[tPos] == NOIR)// != NEUTRE)
            {
                tInterieur = true;
                tDelta     = tPos;
                tMaintien  = tPos;
            }
            
            // Un pixel nous permet de continuer la Ligne
            if (tInterieur == true && Tab_Seuils[tPos] == NOIR)
            {
               tMaintien = tPos;
            }
            
            // Nous venons de finir une Ligne
            if (tInterieur == true && tPos-tMaintien > cSeuilTrou*Oeil.TailleX)
            {
                tInterieur = false;
                
                // Remplissage de la Ligne
                for (tDelta+=Oeil.TailleX; tDelta < tMaintien; tDelta+=Oeil.TailleX)
                {
                    Tab_Seuils[tDelta] = NOIR;//Tab_Seuils[tPos];
                }
            }
        }
    }
    
    // Filtre BF en X!
    
    /*for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            SEUIL v1 = tPosX > 0 ? Tab_Seuils[tPos-1] : NEUTRE;
            SEUIL v2 = Tab_Seuils[tPos];
            SEUIL v3 = tPosX < Oeil.TailleX-1 ? Tab_Seuils[tPos+1] : NEUTRE;
            
            if (v1 != NOIR && v2 == NOIR && v3 != NOIR)
            {
             Tab_Seuils[tPos] = NEUTRE;
            }
        }
    }
    
    // Filtre BF en Y!
    
    for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
    {
        for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            SEUIL v1 = tPosY > 0 ? Tab_Seuils[tPos-Oeil.TailleX] : NEUTRE;
            SEUIL v2 = Tab_Seuils[tPos];
            SEUIL v3 = tPosX < Oeil.TailleY-1 ? Tab_Seuils[tPos+Oeil.TailleX] : NEUTRE;
            
            if (v1 != NOIR && v2 == NOIR && v3 != NOIR)
            {
             Tab_Seuils[tPos] = NEUTRE;
            }
        }
    }*/
}
