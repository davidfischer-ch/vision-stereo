void AlgoOeil::Seuils_Morpho ()
{
    for (int tPosY = 0; tPosY < Oeil.TailleY-2; tPosY+=3)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX-2; tPosX+=3)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            bool tNoir  = Tab_Seuils[tPos] == NOIR ||
                          Tab_Seuils[tPos+1] == NOIR ||
                          Tab_Seuils[tPos+2] == NOIR ||
                          Tab_Seuils[tPos+Oeil.TailleX] == NOIR ||
                          Tab_Seuils[tPos+Oeil.TailleX+1] == NOIR ||
                          Tab_Seuils[tPos+Oeil.TailleX+2] == NOIR ||
                          Tab_Seuils[tPos+2*Oeil.TailleX] == NOIR ||
                          Tab_Seuils[tPos+2*Oeil.TailleX+1] == NOIR ||
                          Tab_Seuils[tPos+2*Oeil.TailleX+2] == NOIR;
            bool tBlanc = Tab_Seuils[tPos] == BLANC ||
                          Tab_Seuils[tPos+1] == BLANC ||
                          Tab_Seuils[tPos+2] == BLANC ||
                          Tab_Seuils[tPos+Oeil.TailleX] == BLANC ||
                          Tab_Seuils[tPos+Oeil.TailleX+1] == BLANC ||
                          Tab_Seuils[tPos+Oeil.TailleX+2] == BLANC ||
                          Tab_Seuils[tPos+2*Oeil.TailleX] == BLANC ||
                          Tab_Seuils[tPos+2*Oeil.TailleX+1] == BLANC ||
                          Tab_Seuils[tPos+2*Oeil.TailleX+2] == BLANC;
                           
            SEUIL tValeure = tNoir ? NOIR : (tBlanc ? BLANC : NEUTRE);
            Tab_Seuils[tPos]   = Tab_Seuils[tPos+Oeil.TailleX]   = Tab_Seuils[tPos+2*Oeil.TailleX]   = tValeure;
            Tab_Seuils[tPos+1] = Tab_Seuils[tPos+Oeil.TailleX+1] = Tab_Seuils[tPos+2*Oeil.TailleX+1] = tValeure;
            Tab_Seuils[tPos+2] = Tab_Seuils[tPos+Oeil.TailleX+2] = Tab_Seuils[tPos+2*Oeil.TailleX+2] = tValeure;
        }
    }
    
    // Erosion en Y
    for (int tPosY = 0; tPosY < Oeil.TailleY-2; tPosY+=3)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX-2; tPosX+=3)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            bool tNoir  = Tab_Seuils[tPos] == NOIR &&
                          Tab_Seuils[tPos+1] == NOIR &&
                          Tab_Seuils[tPos+2] == NOIR &&
                          Tab_Seuils[tPos+Oeil.TailleX] == NOIR &&
                          Tab_Seuils[tPos+Oeil.TailleX+1] == NOIR &&
                          Tab_Seuils[tPos+Oeil.TailleX+2] == NOIR &&
                          Tab_Seuils[tPos+2*Oeil.TailleX] == NOIR &&
                          Tab_Seuils[tPos+2*Oeil.TailleX+1] == NOIR &&
                          Tab_Seuils[tPos+2*Oeil.TailleX+2] == NOIR;
            bool tBlanc = Tab_Seuils[tPos] == BLANC &&
                          Tab_Seuils[tPos+1] == BLANC &&
                          Tab_Seuils[tPos+2] == BLANC &&
                          Tab_Seuils[tPos+Oeil.TailleX] == BLANC &&
                          Tab_Seuils[tPos+Oeil.TailleX+1] == BLANC &&
                          Tab_Seuils[tPos+Oeil.TailleX+2] == BLANC &&
                          Tab_Seuils[tPos+2*Oeil.TailleX] == BLANC &&
                          Tab_Seuils[tPos+2*Oeil.TailleX+1] == BLANC &&
                          Tab_Seuils[tPos+2*Oeil.TailleX+2] == BLANC;
                           
            SEUIL tValeure = tNoir ? NOIR : (tBlanc ? BLANC : NEUTRE);
            Tab_Seuils[tPos]   = Tab_Seuils[tPos+Oeil.TailleX]   = Tab_Seuils[tPos+2*Oeil.TailleX]   = tValeure;
            Tab_Seuils[tPos+1] = Tab_Seuils[tPos+Oeil.TailleX+1] = Tab_Seuils[tPos+2*Oeil.TailleX+1] = tValeure;
            Tab_Seuils[tPos+2] = Tab_Seuils[tPos+Oeil.TailleX+2] = Tab_Seuils[tPos+2*Oeil.TailleX+2] = tValeure;
        }
    }
}
