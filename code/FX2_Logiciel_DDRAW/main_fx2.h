//=============================================================--
// Nom de l'étudiant   : David FISCHER TE3
// Nom du projet       : Vision Stéréoscopique 2006
// Nom du H            : main_fx2
// Nom de la FPGA      : Cyclone - EP1C12F256C7
// Nom de la puce USB2 : Cypress - FX2
// Nom du compilateur  : Quartus II
//=============================================================--

struct BufferBulk
{
    uint8  Buffer[512];
    uint16 Position;
    uint16 Numero;
    uint16 Nombre;
};

static CypressEzUSBDevice NotreFX2;
static BufferBulk BuffersBulk[4];

static CRITICAL_SECTION MutexBulk;

//-----------------------------------------------------------------------------
// Name: LectureBulk(...)
// Desc: Lecture du FX2 s'il le faut
//-----------------------------------------------------------------------------

bool LectureBulk (uint8 pNoPipe, uint16 pNombre)
{  
    if (BuffersBulk[pNoPipe].Position <
        BuffersBulk[pNoPipe].Nombre) return true;
    
    BuffersBulk[pNoPipe].Numero++;
    BuffersBulk[pNoPipe].Position = 0;

    EnterCriticalSection (&MutexBulk);
    
    BuffersBulk[pNoPipe].Nombre = 
    NotreFX2.bulkRead (pNoPipe, (char*)BuffersBulk[pNoPipe].Buffer, pNombre);
    
    LeaveCriticalSection (&MutexBulk);
    
    return BuffersBulk[pNoPipe].Nombre > 0;
}

//-----------------------------------------------------------------------------
// Name: GetBulk(..)
// Desc: Retourne le caractère en cours dans le buffer FX2
//-----------------------------------------------------------------------------

__inline uint8 GetBulk (uint8 pNoPipe)
{
    return BuffersBulk[pNoPipe].Buffer[BuffersBulk[pNoPipe].Position++];
}

//-----------------------------------------------------------------------------
// Name: SetBulk(..)
// Desc: Enregistre 16 bits dans le buffer FX2
//-----------------------------------------------------------------------------

__inline bool SetBulk (uint8 pNoPipe, uint8 pNoOrdre, uint8 pValeur)
{
    char tBuffer[3] = {pNoOrdre, pValeur, 0};
    bool tOK;
    
    //EnterCriticalSection (&MutexBulk);
    
    tOK = (NotreFX2.bulkWrite (pNoPipe, tBuffer, 2) == 2);
    
    //LeaveCriticalSection (&MutexBulk);
    
    return tOK;
}
