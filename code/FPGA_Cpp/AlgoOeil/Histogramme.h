void AlgoOeil::Histogramme ()
{
    for (int tNo = 0; tNo < 256; tNo++) Tab_Histo[tNo] = 0;
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {   // La valeure d'Histogramme [Luminance] est apparue 1 fois de
            Tab_Histo[Oeil.LePixelL(tPosX,tPosY)]++; // plus: Incrémenter!
        }
    }
}
