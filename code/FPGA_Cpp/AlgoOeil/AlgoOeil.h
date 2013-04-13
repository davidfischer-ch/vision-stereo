//=============================================================--
// Nom de l'étudiant : David FISCHER TE3
// Nom du projet     : Caméra CMOS 2006
// Nom du C++        : AlgoImage.h
// Nom du processeur : Cyclone - EP1C12F256C7
//=============================================================--

enum SEUIL { NOIR, NEUTRE, BLANC, BLOB };

struct Blob
{
    int   Nombre;
    int        PosX,      PosY;
    float   CentreX,   CentreY;
    float VarianceX, VarianceY;
};

struct AlgoOeil
{
    string Nom;
    
    Image Oeil;

    int    Tab_Histo[256];
    SEUIL *Tab_Seuils;
    
    int SeuilNoir,  SeuilBlanc;
    XY CentreNoir, CentreBlanc;
    
    XY TaillePupille;
    XY CentrePupilleOld;
    XY CentrePupille;
    XY CentreManuel;
    
    bool AffCalcOK, AffHistoOK;
  
    bool Charge (string pNom);
    void Ferme  ();
    
    void Remplissage (Blob *pBlob, int pX, int pY, SEUIL pIn, SEUIL pOut);
  
    void Options (bool pCalcOK, bool pHistoOK);
  
    float Traitement (int pSerie, int pCentreX, int pCentreY, int pOldX, int pOldY);
    
    void Histogramme ();
    void Seuils_Calcul  ();
    void Seuils_Centres ();
    void Seuils_Arrange ();
    void Seuils_Morpho  ();
    void Seuils_Blob    ();
    void AlgoCroix   ();
    void AlgoBary    ();
};
