int IsItemMinerva(unsigned short itemId)
{
    switch (itemId)
    {
    case 0x12e:
        return 1;
    default:
        return 0;
    }
}
