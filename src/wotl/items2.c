#include <wotl/items.h>
#include <wotl/util.h>

int IsItemElementalGun(u16 itemId)
{
    if (itemId == 0x4c)
    {
        return 1;
    }
    else if (itemId == 0x4b || itemId == 0x4a)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

int IsItemOnion(u16 itemId)
{
    if (itemId == 0x136)
    {
        return 1;
    }
    else if (itemId == 0x12d || itemId == 0x125 || itemId == 0x120 || itemId == 0x106)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

int IsItemMinerva(u16 itemId)
{
    switch (itemId)
    {
    case 0x12e:
        return 1;
    default:
        return 0;
    }
}
