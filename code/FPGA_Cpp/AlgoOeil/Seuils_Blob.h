void AlgoOeil::Seuils_Blob ()
{
    int  NBlobs = 0;
    Blob BBlobs[1024];
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            // Nouveau Blob
            if (Tab_Seuils[tPos] == NOIR)
            {
                BBlobs[NBlobs].PosX = tPosX;
                BBlobs[NBlobs].PosY = tPosY;
                BBlobs[NBlobs].CentreX = 0;
                BBlobs[NBlobs].CentreY = 0;
                BBlobs[NBlobs].VarianceX = 0;
                BBlobs[NBlobs].VarianceY = 0;
                BBlobs[NBlobs].Nombre = 0;
                
                Remplissage (&BBlobs[NBlobs], tPosX, tPosY, NOIR, BLOB);
                
                float tNombre = BBlobs[NBlobs].Nombre;
                float tMoX  = BBlobs[NBlobs].CentreX/tNombre;
                float tMoY  = BBlobs[NBlobs].CentreY/tNombre;
	            float tVaX = BBlobs[NBlobs].VarianceX/tNombre-tMoX*tMoX;
	            float tVaY = BBlobs[NBlobs].VarianceY/tNombre-tMoY*tMoY;
	  
	            BBlobs[NBlobs].CentreX = tMoX;
	            BBlobs[NBlobs].CentreY = tMoY;
	            BBlobs[NBlobs].VarianceX = tVaX;
	            BBlobs[NBlobs].VarianceY = tVaY;
	  
                NBlobs++;
            }
        }    
    }
      
    int tMaxN = 0, tMaxV = 0;
   
    // Recherche la Plus Grande Zone
    for (int tNo = 0; tNo < NBlobs; tNo++)
    {  
       if (BBlobs[tNo].Nombre > tMaxV)
       {
          tMaxN = tNo;
          tMaxV = BBlobs[tNo].Nombre;
          
          CentrePupille.X = (int)BBlobs[tNo].CentreX;
          CentrePupille.Y = (int)BBlobs[tNo].CentreY;
       }
    }
    
    Remplissage (&BBlobs[tMaxN], BBlobs[tMaxN].PosX, BBlobs[tMaxN].PosY, BLOB, NOIR);
      
    // Efface les Autres
/*    for (int tNo = 0; tNo < NBlobs; tNo++)
    {
       if (tNo != tMaxN)
       {
       Remplissage (&BBlobs[tNo], BBlobs[tNo].PosX,BBlobs[tNo].PosY, BLOB, NOIR);
       }
    }*/
}

      // Algorithme de suivi de contour... inutile
/*    XY Tab_D[4] = {{0,-1},{1,0},{0,1},{-1,0}};
    
    for (int tPosY = 0; tPosY < Oeil.TailleY; tPosY++)
    {
        for (int tPosX = 0; tPosX < Oeil.TailleX; tPosX++)
        {
            int tPos = tPosY*Oeil.TailleX+tPosX;
            
            // Nouveau Blob à Caractériser
            if (Tab_Seuils[tPos] == NOIR)
            {
               int tdV = 0;
               int tdX = 0;
               int tdY = 0;
               
               int tGarde2 = 0;
               
               while (tGarde2 < 300)
               {
                   int tGarde = 0;
                   
                   while (tGarde < 100)
                   {    
                       int tPX = tPosX+tdX+Tab_D[tdV].X;
                       int tPY = tPosY+tdY+Tab_D[tdV].Y;
                   
                       if (tPX >= 0 && tPX < Oeil.TailleX &&
                           tPY >= 0 && tPY < Oeil.TailleY)
                       {
                           if (Tab_Seuils[tPY*Oeil.TailleX+tPX] == NOIR ||
                               Tab_Seuils[tPY*Oeil.TailleX+tPX] == BLOB) break;
                       }
                   
                       tdV++; if (tdV == 4) tdV = 0;
                       
                       tGarde++;
                   }
                   
                   if (tGarde > 50) { cout << "Garde!" << endl; goto Suite; }
               
                   tdX += Tab_D[tdV].X;
                   tdY += Tab_D[tdV].Y;
                   
                   Tab_Seuils[(tPosY+tdY)*Oeil.TailleX+(tPosX+tdX)] = BLOB;
               
                   tdV--; if (tdV < 0) tdV = 3;
               
                   // Tour Complet
                   if (tdX == 0 && tdY == 0) break;
                   
                   tGarde2++;
               }
               
               goto Suite;
                              
            }
        }
    }*/  
    
