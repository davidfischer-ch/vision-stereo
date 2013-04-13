#include <cstdlib>
#include <iostream>
#include <iomanip>

using namespace std;

static const float z1 = -2+1.7320508;

static const float X = 255.0/1024.0;
static const int K = 8;
static float c[K][K];
static float s[K][K] = {{X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X},
                        {X,X,X,X,X,X,X,X}};

static float i[2*K][2*K];
                        
                       
//{42,10,17,14,23,43,76,54,10,90};

static float Max, MaxA = -6969.0, MaxB = -6969.0;
static float Min, MinA =  6969.0, MinB =  6969.0;

static bool affiche = false;

void BSpline3_Coeffs ()
{
    Max = -6969.0;
    Min =  6969.0;
        
    float k0 = 5-1;
    
    for (int a = 0; a < K; a++)
    {
        float z1km1 = 1;
    
        if (affiche)
        cout << "\nEtape c+(1) = somme de s(k)*z1^(k-1) avec k=1..k0\n" << endl;
        
        c[a][0] = 0;
        for (int k = 0; k < k0; k++)
        {
            c[a][0]  += s[a][k]*z1km1;
            z1km1 *= z1;
            
            if (c[a][0] > Max) Max = c[a][0];
            if (c[a][0] < Min) Min = c[a][0];
        }
        
        if (affiche)
        cout << c[a][0] << " en binaire " << c[a][0]*1024.0 << endl;
        
        if (affiche)
        cout << "\nEtape c+(k) = s(k) + z1*c+(k-1) avec k=2..K\n" << endl;
        
        for (int k = 1; k < K; k++)
        {
            c[a][k] = s[a][k]+z1*c[a][k-1];
            
            if (c[a][k] > Max) Max = c[a][k];
            if (c[a][k] < Min) Min = c[a][k];
    
            if (affiche)
            cout << c[a][k] << " en binaire " << c[a][k]*1024.0 << endl;
        }
        
        if (affiche)      
        cout << "\nEtape c-(K) = z1/(1-z1^2) * (c+(K) + z1*c+(K-1))\n" << endl;
        
        c[a][K-1] = z1/(1-z1*z1) * (c[a][K-1]+z1*c[a][K-2]);
        
        if (c[a][K-1] > Max) Max = c[a][K-1];
        if (c[a][K-1] < Min) Min = c[a][K-1];
        
        if (affiche)    
        cout << c[a][K-1] << " en binaire " << c[a][K-1]*1024.0 << endl;
        
        if (affiche)
        cout << "\nEtape c-(k) = z1*(c-(k+1) - c+(k)) avec k=K-1..1\n" << endl;
        
        for (int k = K-2; k >= 0; k--)
        {
            c[a][k] = z1*(c[a][k+1]-c[a][k]);
            
            if (c[a][k] > Max) Max = c[a][k];
            if (c[a][k] < Min) Min = c[a][k];
            
            if (affiche)
            cout << c[a][k] << " en binaire " << c[a][k]*1024.0 << endl;
        }
        
        if (affiche)
        cout << "\nEtape c(k) = 6*c-(k)\n" << endl;
        
        for (int k = 0; k < K; k++)
        {
            c[a][k] *= 6;
            
            if (c[a][k] > Max) Max = c[a][k];
            if (c[a][k] < Min) Min = c[a][k];
            
            if (affiche)
            cout << c[a][k] << " en binaire " << c[a][k]*1024.0 << endl;
        }
    }
}

float b3(float n)
{
      float an = n < 0.0 ? -an : an;
      if (an < 1.0) return 2.0/3.0-an*an+an*an*an/2.0;
      if (an < 2.0) return (2.0-an)*(2.0-an)*(2.0-an)/6.0;
      return 0.0;
}

void BSpline3_Image()
{    
     for (int y = 0; y < K; y++)
     {
         int l1 = y-2;
         
         for (int x = 0; x < K; x++)
         {     
             int k1 = x-2;
             
             i[y][x] = 0.0;
             
             for (int l = l1; l <= l1+3; l++)
                 for (int k = k1; k <= k1+3; k++)
                     i[y][x] += c[l][k]*b3(x-k)*b3(y-l);
         }
     }
}

int main (int argc, char *argv[])
{
	srand ((unsigned)time(NULL)); // Initialisation du rand()
	
    for (int m = 0; m < 1000; m++)
    {
        for (int y = 0; y < K; y++)
            for (int x = 0; x < K; x++)
                s[y][x] = (float)rand()/(float)RAND_MAX;
         
        BSpline3_Coeffs();
        
        if (Max > MaxA) MaxA = Max;
        if (Min < MinA) MinA = Min;
        
        for (int y = 0; y < K; y++)
            for (int x = 0; x < K; x++)
                s[y][x] = c[x][y];
        
        BSpline3_Coeffs();
        
        if (Max > MaxB) MaxB = Max;
        if (Min < MinB) MinB = Min;
        
        BSpline3_Image();
        
        if (m % 100 == 0) cout << "\nMIN a = " << MinA << endl;
        if (m % 100 == 0) cout <<   "MAX a =  " << MaxA << endl;
        if (m % 100 == 0) cout << "\nMIN b = " << MinB << endl;
        if (m % 100 == 0) cout <<   "MAX b =  " << MaxB << endl;
    }
    
         for (int y = 0; y < K; y++)
         {
            cout << endl;
            for (int x = 0; x < K; x++)
                cout << setw(6) << (int)(c[y][x]*100) << " ";
                
            cout << endl;
         }
         
         for (int y = 0; y < K; y++)
         {
            cout << endl;
            for (int x = 0; x < K; x++)
                cout << setw(6) << i[y][x] << " ";
                
            cout << endl;
         }

    system("PAUSE");
    return EXIT_SUCCESS;
}

