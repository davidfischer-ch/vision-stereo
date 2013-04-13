void AlgoOeil::AlgoBary ()
{
    int tSommeX = 0, tSommeY = 0, tNombre = 0;
    
    // Seule une petite zone de l'Image est prise en compte (bornes...)
    for (int tPosY = CentrePupilleOld.Y-cDelta.Y-TaillePupille.Y;
             tPosY < CentrePupilleOld.Y+cDelta.Y+TaillePupille.Y; tPosY++)
    {
        if (tPosY < 0) continue;
        if (tPosY >= Oeil.TailleY) break;
        
        for (int tPosX = CentrePupilleOld.X-cDelta.X-TaillePupille.X;
                 tPosX < CentrePupilleOld.X+cDelta.X+TaillePupille.X; tPosX++)
        {
            if (tPosX < 0) continue;
            if (tPosX >= Oeil.TailleX) break;
            
            if (Tab_Seuils[tPosY*Oeil.TailleX+tPosX] != NEUTRE)
            {  // Forume du Barycentre Mathématique
               tSommeX += tPosX;
               tSommeY += tPosY;
               tNombre++;
            }
        }
    }
    
    if (tNombre > 0)
    {
      CentrePupille.X = tSommeX/tNombre;
      CentrePupille.Y = tSommeY/tNombre;
    }
}
