//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du C++          : Utile
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

#include "david_fischer.h"

//-----------------------------------------------------------------------------
// Name: ToHex(...)
// Desc: Conversion Hexadécimal d'un octet non signé
//-----------------------------------------------------------------------------
void ut_ToHex (uint8 pOctet, char* pHexa)
{
	_itoa (pOctet,pHexa,16);
	
	if (pOctet < 16)
	{
		pHexa[1] = pHexa[0];
		pHexa[0] = '0';
    }
	
	for (int No = 0; No < 2; No++)
	{
		switch (pHexa[No])
		{
		case 'a': pHexa[No] = 'A'; break;
		case 'b': pHexa[No] = 'B'; break;
		case 'c': pHexa[No] = 'C'; break;
		case 'd': pHexa[No] = 'D'; break;
		case 'e': pHexa[No] = 'E'; break;
		case 'f': pHexa[No] = 'F'; break;
		}
	}
}

//-----------------------------------------------------------------------------
// Name: ut_Coords(...)
// Desc: Retourne les coordonnées source transformées d'après ...
//-----------------------------------------------------------------------------

Pos2v32f ut_Coords32f (Pos2v16b pCoords, uint16 pSrcDebX, uint16 pSrcFinX,
                                         uint16 pSrcDebY, uint16 pSrcFinY)
{
    Pos2v32f tCoords = {0.0,0.0};
    
    // Les coordonnées sont coincées dans les limites
    if (pCoords.X < pSrcDebX) pCoords.X = pSrcDebX;
    if (pCoords.X > pSrcFinX) pCoords.X = pSrcFinX;
    if (pCoords.Y < pSrcDebY) pCoords.Y = pSrcDebY;
    if (pCoords.Y > pSrcFinY) pCoords.Y = pSrcFinY;
    
    // Ramené entre 0.0 et 1.0 depuis le monde source
    tCoords.X = ((float)(pCoords.X-pSrcDebX))/((float)(pSrcFinX-pSrcDebX));
    tCoords.Y = ((float)(pCoords.Y-pSrcDebY))/((float)(pSrcFinY-pSrcDebY));
    
    return tCoords;
}
Pos2v16b ut_Coords16b (Pos2v32f pCoords, uint16 pDstDebX, uint16 pDstFinX,
                                         uint16 pDstDebY, uint16 pDstFinY)
{
    Pos2v16b tCoords = {0,0};
    
    // Les coordonnées sont coincées dans les limites
    if (pCoords.X < 0.0) pCoords.X = 0.0;
    if (pCoords.X > 1.0) pCoords.X = 1.0;
    if (pCoords.Y < 0.0) pCoords.Y = 0.0;
    if (pCoords.Y > 1.0) pCoords.Y = 1.0;
    
    // Ramené entre pDstDeb et pDstFin dans le mode dest.
    tCoords.X = pDstDebX + (uint16)(pCoords.X*(pDstFinX-pDstDebX));
    tCoords.Y = pDstDebY + (uint16)(pCoords.Y*(pDstFinY-pDstDebY));
    
    return tCoords;
}

Pos2v8b ut_Coords8b (Pos2v32f pCoords, uint8 pDstDebX, uint8 pDstFinX,
                                       uint8 pDstDebY, uint8 pDstFinY)
{
    Pos2v8b tCoords = {0,0};
    
    // Les coordonnées sont coincées dans les limites
    if (pCoords.X < 0.0) pCoords.X = 0.0;
    if (pCoords.X > 1.0) pCoords.X = 1.0;
    if (pCoords.Y < 0.0) pCoords.Y = 0.0;
    if (pCoords.Y > 1.0) pCoords.Y = 1.0;
    
    // Ramené entre pDstDeb et pDstFin dans le mode dest.
    tCoords.X = pDstDebX + (uint8)(pCoords.X*(pDstFinX-pDstDebX));
    tCoords.Y = pDstDebY + (uint8)(pCoords.Y*(pDstFinY-pDstDebY));

    return tCoords;
}

//-----------------------------------------------------------------------------
// Name: ut_HSL_a_RVB(...)
// Desc: Conversion du format HSL au RVB
//-----------------------------------------------------------------------------
RVB_HSL ut_HSL_a_RVB (RVB_HSL pHSL, float fH, float fS, float fL)
{
   float H = pHSL.H/255.0*fH; if (H > 1.0) H = 1.0;
   float S = pHSL.S/255.0*fS; if (S > 1.0) S = 1.0;
   float L = pHSL.L/255.0*fL; if (L > 1.0) L = 1.0;
    
   float R = 0.0;
   float V = 0.0;
   float B = 0.0;
    
   float temp1, temp2;
    
   if (L > 0.0)
   {
      if (S == 0.0)
      {
         R = V = B = L;
      }
      else
      {
         temp2 = (L <= 0.5) ? L*(1.0+S) : L+S-(L*S);
         temp1 = 2.0*L-temp2;
            
         float t3 [3] = {H+1.0/3.0, H, H-1.0/3.0};
         float clr[3] = {0,0,0};

         for (uint8 i=0; i<3; i++)
         {
            if(t3[i]<0) t3[i]+=1.0;
            if(t3[i]>1) t3[i]-=1.0;

            if      (6.0*t3[i] < 1.0) clr[i] = temp1+(temp2-temp1)*t3[i]*6.0;
            else if (2.0*t3[i] < 1.0) clr[i] = temp2;
            else if (3.0*t3[i] < 2.0) clr[i] = (temp1+(temp2-temp1)*((2.0/3.0)-t3[i])*6.0);
            else clr[i] = temp1;
         }

         R = clr[0];
         V = clr[1];
         B = clr[2];
      }
   }

   RVB_HSL tRVB = {(uint8)(R*255), (uint8)(V*255), (uint8)(B*255)};
    
   return tRVB;
}

//-----------------------------------------------------------------------------
// Name: dx_NombreGDI(...)
// Desc: Dessine un nombre / du texte en utilisant le GDI
//-----------------------------------------------------------------------------
void ut_ChargerBitmap (HBITMAP* pBitmap, char* pNomBMP)
{
   WCHAR tNomBMP[128] = {0};
   MultiByteToWideChar (GetACP(), 0, pNomBMP, -1, tNomBMP, 128);
   
   *pBitmap = (HBITMAP)LoadImage (NULL, tNomBMP, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
}

//-----------------------------------------------------------------------------
// Name: dx_NombreGDI(...)
// Desc: Dessine un nombre / du texte en utilisant le GDI
//-----------------------------------------------------------------------------
void ut_FermerBitmap (HBITMAP pBitmap)
{
    DeleteObject (pBitmap);
}
