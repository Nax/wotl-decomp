#include <wotl/items.h>

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
