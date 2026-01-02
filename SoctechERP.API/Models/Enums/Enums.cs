namespace SoctechERP.API.Models.Enums
{
    public enum UnionType
    {
        UOCRA,          // Construcción (Hora)
        UECARA,         // Administrativos Construcción (Mes)
        COMERCIO,       // Administrativos Generales (Mes)
        FUERA_CONVENIO  // Gerentes / Profesionales
    }

    public enum PayFrequency
    {
        Quincenal,      // Para obreros
        Mensual         // Para administrativos
    }
}