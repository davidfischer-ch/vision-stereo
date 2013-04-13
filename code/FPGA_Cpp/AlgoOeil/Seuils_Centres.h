void AlgoOeil::Seuils_Centres ()
{
    // Calcul du Barycentre du Noir
{
    int tSommeX = 0, tSommeY = 0, tNombre = 0;
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {   
            if (Tab_Seuils[tPosY*Oeil.TailleX+tPosX] == NOIR)
            {  // Formule du Barycentre Mathématique
               tSommeX += tPosX;
               tSommeY += tPosY;
               tNombre++;
            }
        }
    }
    
    CentreNoir.X = tSommeX/tNombre;
    CentreNoir.Y = tSommeY/tNombre;
}
    
    // Calcul du Barycentre du Blanc
{
    int tSommeX = 0, tSommeY = 0, tNombre = 0;
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {            
            if (Tab_Seuils[tPosY*Oeil.TailleX+tPosX] == BLANC)
            {  // Formule du Barycentre Mathématique
               tSommeX += tPosX;
               tSommeY += tPosY;
               tNombre++;
            }
        }
    }
    
    CentreBlanc.X = tSommeX/tNombre;
    CentreBlanc.Y = tSommeY/tNombre;
}
}
