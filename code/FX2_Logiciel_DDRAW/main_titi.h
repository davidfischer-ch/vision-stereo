//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du H            : main_titi
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

// STRUCTURES

const int TAILLE_TITI_X = (nPerPerX*2+nDetDetX);
const int TAILLE_TITI_Y = (nPerPerY*2+nDetDetY);

struct TITI
{
	uint16 NoImage;
	uint16 NoCRC;
	bool   Type;
	
    struct
    {
        RVB_HSL Pixels[TAILLE_TITI_X];
        uint16  Nombre;
        
    } Lignes[TAILLE_TITI_Y];
};

// VARIABLES

static volatile TITI    ImageTITI;
static volatile Pos2v8b PosPupille = {0,0};
static volatile uint16  NbControle = 0;

// FONCTIONS

void ToImageTiti  (void* rien);
void ToPosPupille (void* rien);
bool ToControle   (uint8   pTypeFlux);
bool ToControle   (Pos2v8b pPosPupille);

#define FX2_IMAGE    0
#define FX2_PUPILLE  2
#define FX2_CONTROLE 1

//-----------------------------------------------------------------------------
// Name: ToImageTiti(...)
// Desc: (Thread) Lit le flux de trames titi du système embarqué par l'USB2
//-----------------------------------------------------------------------------

#define MASQUE_IMAGE 0x80
#define VALEUR_IMAGE 0x80

#define MASQUE_LIGNE 0xC0
#define VALEUR_LIGNE 0x40

#define MASQUE_CRC   0xE0
#define VALEUR_CRC   0x20

#define MASQUE_PIXEL 0xF0
#define VALEUR_PIXEL 0x10

#define MASQUE_FLUX  0x04
#define RVB_FLUX     0x00
#define HSL_FLUX     0x04

#define MASQUE_TYPE  0x07
#define ROUGE_TYPE   0x00
#define VERT_TYPE    0x01
#define BLEU_TYPE    0x02
#define HUE_TYPE     0x04
#define SAT_TYPE     0x05
#define LUM_TYPE     0x06

void ToImageTiti (void* rien)
{   
    uint16 NoLigne = 0;
    uint16 NoPixel = 0;

    while (true)
    {   
		if (!LectureBulk (FX2_IMAGE, 512)) { Sleep (20); continue; }
		
        uint8 PFaible = GetBulk (FX2_IMAGE);
        uint8 PFort   = GetBulk (FX2_IMAGE);

        // Compteur Image
        if ((PFort & MASQUE_IMAGE) == VALEUR_IMAGE)
        {
			// Changement de Buffer
//            NumeroTiti = 1-NumeroTiti;
            
			ImageTITI.NoImage = (PFort&~MASQUE_IMAGE)*256+PFaible;            
			NoLigne = 0;
        }

        // Compteur Ligne
        else if ((PFort & MASQUE_LIGNE) == VALEUR_LIGNE)
        {
            NoLigne = (PFort&~MASQUE_LIGNE)*256+PFaible;
            NoPixel = 0;
            
            ImageTITI.Lignes[NoLigne].Nombre = 0;
        }

        // Paquet CRC
        else if ((PFort & MASQUE_CRC) == VALEUR_CRC)
        {
			ImageTITI.NoCRC = 0;
        }

        // Paquet Pixel / Données
        else if ((PFort & MASQUE_PIXEL) == VALEUR_PIXEL)
        {
            // Le pixel doit être dans les marges!! 
            //if (NoPixel < 0) NoPixel = 0;
			if (NoPixel > TAILLE_TITI_X-1) NoPixel = TAILLE_TITI_X-1;
			
			//if (NoLigne < 0) NoLigne = 0;
			if (NoLigne > TAILLE_TITI_Y-1) NoLigne = TAILLE_TITI_Y-1;
       
            ImageTITI.Type = (PFort & MASQUE_FLUX);
            
            switch (PFort & MASQUE_TYPE)
            {
            case ROUGE_TYPE:
            case HUE_TYPE:
            ImageTITI.Lignes[NoLigne].Pixels[NoPixel].R = PFaible; break;

            case VERT_TYPE:
            case SAT_TYPE:
            ImageTITI.Lignes[NoLigne].Pixels[NoPixel].V = PFaible; break;

            case BLEU_TYPE:
            case LUM_TYPE:
            ImageTITI.Lignes[NoLigne].Pixels[NoPixel].B = PFaible;
            ImageTITI.Lignes[NoLigne].Nombre = ++NoPixel;
            
            break;
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Name: ToPosPupille(...)
// Desc: (Thread) Lit le flux position du système embarqué par l'USB2
//-----------------------------------------------------------------------------

void ToPosPupille (void* rien)
{   
    while (true)
    {
		if (!LectureBulk (FX2_PUPILLE, 512)) { Sleep (50); continue; }
		
        PosPupille.Y = GetBulk (FX2_PUPILLE);
        PosPupille.X = GetBulk (FX2_PUPILLE);
    }
}

//-----------------------------------------------------------------------------
// Name: ToControle(...)
// Desc: (Thread) Envoie un ordre dans le système embarqué par l'USB2
//-----------------------------------------------------------------------------

#define FLUX_CONTROLE      0x00
#define POSITIONX_CONTROLE 0x01
#define POSITIONY_CONTROLE 0x02

__inline bool ToControle (uint8 pTypeFlux)
{
    NbControle++;
    return SetBulk (FX2_CONTROLE, FLUX_CONTROLE, pTypeFlux);
}

__inline bool ToControle (Pos2v8b pPosPupille)
{
    NbControle++;
    return SetBulk (FX2_CONTROLE, POSITIONX_CONTROLE, pPosPupille.X);
		   SetBulk (FX2_CONTROLE, POSITIONY_CONTROLE, pPosPupille.Y);
}
