#include <wotl/items.h>

int IsItemInvalid(u16 itemId)
{
    int invalid;

    switch (itemId)
    {
    case 0xff:
        invalid = 1;
        break;
    default:
        if (itemId >= 0x13c)
            invalid = 1;
        else
            invalid = 0;
        break;
    }

    return invalid;
}
