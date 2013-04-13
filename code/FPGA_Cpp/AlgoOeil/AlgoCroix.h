void AlgoOeil::AlgoCroix ()
{
    int tMoinsY, tPlusY, tNewX = CentrePupilleOld.X;
    int tMoinsX, tPlusX, tNewY = CentrePupilleOld.Y;
     
    for (int tNo = 0; tNo < 4; tNo++)
    {
        for (tMoinsY = 0; tNewY >= tMoinsY; tMoinsY++)
        {   // Crucifiction vers le Haut (Bas en BMP)
            int tPos = (tNewY-tMoinsY)*Oeil.TailleX+tNewX;
            if (Tab_Seuils[tPos] == NEUTRE) break;
        }
        
        for (tPlusY = 0; tNewY + tPlusY <= Oeil.TailleY; tPlusY++)
        {   // Crucifiction vers le Bas (Haut en BMP)
            int tPos = (tNewY+tPlusY)*Oeil.TailleX+tNewX;
            if (Tab_Seuils[tPos] == NEUTRE) break;
        }
        
        // Centrage de la Position en Y
        tNewY = tNewY + (tPlusY-tMoinsY)/2;
     
        for (tMoinsX = 0; tNewX >= tMoinsX; tMoinsX++)
        {   // Crucifiction vers la Gauche (Gauche en BMP)
            int tPos = tNewY*Oeil.TailleX+(tNewX-tMoinsX);
            if (Tab_Seuils[tPos] == NEUTRE) break;
        }
        
        for (tPlusX = 0; tNewX + tPlusX <= Oeil.TailleX; tPlusX++)
        {   // Crucifiction vers le Droit (Droite en BMP)
            int tPos = tNewY*Oeil.TailleX+(tNewX+tPlusX);
            if (Tab_Seuils[tPos] == NEUTRE) break;
        }
        
        // Centrage de la Position en X
        tNewX = tNewX + (tPlusX-tMoinsX)/2;
    }
    
    CentrePupille.X = tNewX;
    CentrePupille.Y = tNewY;

    Oeil.EcCroix (tNewX, tNewY-tMoinsY, rvbCYAN);
    Oeil.EcCroix (tNewX, tNewY+tPlusY,  rvbCYAN);
    Oeil.EcCroix (tNewX-tMoinsX, tNewY, rvbCYAN);
    Oeil.EcCroix (tNewX+tPlusX,  tNewY, rvbCYAN);
}
