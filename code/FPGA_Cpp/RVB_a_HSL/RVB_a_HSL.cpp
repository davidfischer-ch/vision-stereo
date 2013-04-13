#include <cstdlib>
#include <iostream>
#include <iomanip>

using namespace std;

void RVB_a_HSL (float R, float V, float B)
{  
   cout << "\nRVB = " << setw(6) << R << " "
                      << setw(6) << V << " "
                      << setw(6) << B << "  et ";
        
    R /= 256.0; // Quantification préconisèe
    V /= 256.0; // sur 8 bits ...
    B /= 256.0;
    
    float MAX = R; if (V > MAX) MAX = V; if (B > MAX) MAX = B;	
	float MIN = R; if (V < MIN) MIN = V; if (B < MIN) MIN = B;

	float L = (MAX + MIN)/2.0;
	float H = 0.0, S = 0.0;
		
	if      (MIN == MAX) H = 0;
	else if (MAX == R)   { if (V >= B) H = 60.0*(V-B)/(MAX-MIN);
			               else        H = 60.0*(V-B)/(MAX-MIN)+360.0; }
	else if (MAX == V) H = 60.0*(B-R)/(MAX-MIN)+120.0;
	else if (MAX == B) H = 60.0*(R-V)/(MAX-MIN)+240.0;
		
	if (MIN == MAX) S = 0.0;
	else if (L > 0.5) S = (MAX-MIN)/(2.0-(MAX+MIN));
	else if (L > 0.0) S = (MAX-MIN)/(MAX+MIN);
	
    int H8 = (int)(H/360.0*256.0);    if (H8 > H*256.0) H8--;
    int S8 = (int)(S*256.0);          if (S8 > S*256.0) S8--;
    int L8 = (int)(L*256.0);          if (L8 > L*256.0) L8--;
 
    cout << "HSL = " << setw(6) << H8 << " "
                     << setw(6) << S8 << " "
                     << setw(6) << L8;
}

void TestRVB_HSL ()
{
    RVB_a_HSL(255,   0,   0); // Tests de base
    RVB_a_HSL(128, 255, 128); // Confirmées par
    RVB_a_HSL(0,     0, 128); // Wikipedia !
    RVB_a_HSL(128, 128, 128);
    
    int R = 0;
    int V = 99;
    int B = 128;
    
    for (int No = 0; No < 36; No++)
    {
        if (No % 4 == 0) cout << endl;
        
        RVB_a_HSL(R,V,B);
        
        R = (R + 121) % 256; // Création d'un
        V = (V + 169) % 256; // ensemble de
        B = (B +  49) % 256; // couleurs
    }
    cout << endl;
}

static int testR;
static int testV;
static int testB;

int main (int argc, char *argv[])
{    
    TestRVB_HSL();
    
    while(true)
    {
        cin >> testR;
        cin >> testV;
        cin >> testB;
    
        RVB_a_HSL(testR,testV,testB);
        
        cout << endl;
    }

    system("PAUSE");
    return EXIT_SUCCESS;
}
