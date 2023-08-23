#include <wotl/items.h>

extern const ItemData kItemTable[];
extern const ItemData kItemTable2[];

const ItemData* GetItemData(u16 itemId)
{
    if (itemId < 0x100)
        return &kItemTable[itemId];
    else
        return &kItemTable2[itemId - 0x100];
}
