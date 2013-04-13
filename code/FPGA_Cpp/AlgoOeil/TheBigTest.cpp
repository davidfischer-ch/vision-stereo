//=============================================================--
// Nom de l'étudiant : David FISCHER TE3
// Nom du projet     : Caméra CMOS 2006
// Nom du C++        : AlgoImage.cpp
// Nom du processeur : Cyclone - EP1C12F256C7
//=============================================================--

#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <math.h>

using namespace std;

#include "ImageBMP.h"
#include "AlgoOeil.h"

//=======================================================================--

static float Somme1 = 0;
static float Somme2 = 0;
static float Nombre = 0;
   
void TestOldCentre (string pNom, int pCentreX, int pCentreY)
{	
    AlgoOeil tAlgoOeil/*, tSauveOeil*/;

//    tSauveOeil.Charge (pNom);
        
    tAlgoOeil.Charge  (pNom);
    
    // Calc? Histo?
    tAlgoOeil.Options (true, true);
    
    int tNoX = 0, tNoY = 0;
/*    for (int tNoY = -5; tNoY <= 5; tNoY+=2)
    {
        for (int tNoX = -5; tNoX <= 5; tNoX+=2)
        {
            tAlgoOeil.Oeil.Copie (tSauveOeil.Oeil);*/
            
            int tOldX = pCentreX + tNoX;
            int tOldY = pCentreY + tNoY;
            cout << setw(2) << tOldX-pCentreX << " "
                 << setw(2) << tOldY-pCentreY << " ";

            float tResultat =
                  tAlgoOeil.Traitement (0, pCentreX, pCentreY, tOldX, tOldY);
            
            cout << pNom;
            cout << " mano " << tAlgoOeil.CentreManuel.X << " "
                             << tAlgoOeil.CentreManuel.Y;
            cout << " algo " << tAlgoOeil.CentrePupille.X << " "
                             << tAlgoOeil.CentrePupille.Y;
                             
            cout.precision(3);
            
            cout << " erro " << tResultat << endl;
            
            Somme1 += tResultat;
            Somme2 += tResultat*tResultat;
            Nombre++;
/*        }
    }*/
            
    tAlgoOeil.Ferme  ();
//    tSauveOeil.Ferme ();
}

/*void TestStabilite (string pNom, int pCentreX, int pCentreY)
{	
    AlgoOeil tAlgoOeil, tSauveOeil;

    tSauveOeil.Charge (pNom);
    tAlgoOeil.Charge  (pNom);
    
    // Morpho? Croix? Bary? Calc? Histo?
    tAlgoOeil.Options (false, false, true, false, false);
    
    int tOldX = pCentreX+5, tOldY = pCentreY+5;
    
    for (int tNo = 0; tNo < 1; tNo++)
    {
        tAlgoOeil.Oeil.Copie (tSauveOeil.Oeil);
            
        cout << setw(2) << tOldX-pCentreX << " "
             << setw(2) << tOldY-pCentreY << " ";
                 
        float tResultat =
              tAlgoOeil.Traitement (tNo, pCentreX, pCentreY, tOldX, tOldY);
              
        tOldX = tAlgoOeil.CentrePupille.X;
        tOldY = tAlgoOeil.CentrePupille.Y;
            
        cout << pNom;
        cout << " mano " << tAlgoOeil.CentreManuel.X << " "
                         << tAlgoOeil.CentreManuel.Y;
        cout << " algo " << tAlgoOeil.CentrePupille.X << " "
                         << tAlgoOeil.CentrePupille.Y;
                             
        cout.precision(3);
            
        cout << " erro " << tResultat << endl;
            
        Somme1 += tResultat;
        Somme2 += tResultat*tResultat;
        Nombre++;
    }
    
    tAlgoOeil.Ferme  ();
    tSauveOeil.Ferme ();
}*/

//=======================================================================--

struct Images
{
    char *Nom;
    int PosX;
    int PosY;
};

static Images MesImages[] =
{{"oeil1",  64,   40}, // 0
 {"oeil2",  64,   29}, // 1
 {"oeil3",  347, 183}, // 2
 {"oeil4",  65,   73}, // 3
 {"oeil5",  43,   44}, // 4
 {"oeil6",  61,   38}, // 5
 {"oeil7",  76,   58}, // 6
 {"oeil8",  57,   41}, // 7
 {"oeil9",  63,   52}, // 8
 {"oeil10", 52,   33}, // 9
 {"oeil11", 37,   43}, // 10
 {"oeil12", 72,   37}, // 11
 {"oeil13", 72,   39}, // 12
 {"oeil14", 61,   51}, // 13
 {"oeil15", 28,   55}, // 14
 {"MonOeil4",  53, 30}, // 15
 {"MonOeil5",  48, 34}, // 16
 {"MonOeil6",  55, 35}, // 17
 {"MonOeil8",  21, 20}, // 18
 {"MonOeil14", 30, 21}, // 19
 {"MonOeil15", 36, 18}, // 20
 {"MonOeil16", 55, 28}, // 21
 {"MonOeil22", 55, 29}, // 22
 {"Oeil_001_128", 60, 32}, // 23
 {"Oeil_018_128", 49, 33}, // 24
 {"Oeil_019_128", 69, 41}, // 25
 {"Oeil_020",  153,129}, // 26
 {"Oeil_021",  261,188}, // 27
 {"Oeil_022",  40,24}, // 28
 {"Oeil_023", 56,39}, // 29
 {"Oeil_024", 147,70}, // 30
 {"Oeil_025", 50,38}, // 31
 {"Oeil_026", 36,24}, // 32
 {"Oeil_027", 20,28}, // 33
 {"Oeil_028", 119,92}, // 34
 {"Oeil_029", 44,29} // 35
 
/* {"Oeil1_030",,}, // 37
 {"Oeil1_032",,}, // 38
 {"Oeil1_033",,}, // 39
 {"Oeil1_034",,}, // 40
 {"Oeil1_035",,}, // 41
 {"Oeil1_036",,}, // 42
 {"Oeil1_037",,}, // 43
 {"Oeil1_038",,}, // 44
 {"Oeil1_039",,}, // 45        
 {"Oeil1_040",,}, // 46
 {"Oeil1_041",,}, // 47
 {"Oeil1_042",,}, // 48
 {"Oeil1_043",,} // 49*/
 };

#define TEST(no)\
 TestOldCentre (MesImages[no].Nom, MesImages[no].PosX, MesImages[no].PosY);

int main (long argc, char *argv[])
{	
    // ============================-
    for (int i = 23; i < 36; i++) { if (i == 2) continue; TEST(i) }

    // TEST(23)

    
    // 106 68 MonOeil4 centre=(70.48221343873517, 33.45059288537549) environ OK mais c'est du bol
    // 94  67 MonOeil5 centre=(26.70137825421133, 22.156202143950996) pas ok
    // 103 69 MonOeil6 centre=(55.10126582278481, 34.40506329113924) ok
    // 61  47 MonOeil8 centre=(9.13312693498452, 20.984520123839008) pas ok
    // 64  49 MonOeil14 centre=(50.158940397350996, 28.102649006622517) pas ok
    // 69  37 MonOeil15 centre=(59.85, 23.8) pas ok
    // 91  61 MonOeil16 centre=(39.90243902439025, 23.170731707317074) pas ok
    // 98  65 MonOeil22 centre=(56.40625, 25.734375) environ ok mais c'est du bol
    
	float tMoyenne  = Somme1/Nombre;
	float tVariance = Somme2/Nombre-tMoyenne*tMoyenne;
    
    cout << endl;
    cout << "Erreur totale  : " << Somme1    << endl;
    cout << "Erreur moyenne : " << tMoyenne  << endl;
    cout << "Ecart /moyenne : " << tVariance << endl;
  
    system("PAUSE");
    return 0;
}
