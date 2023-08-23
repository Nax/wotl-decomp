#ifndef WOTL_ITEMS_H
#define WOTL_ITEMS_H

#include <wotl/types.h>

typedef struct
{
    u8      palette;
    u8      gfx;
    u8      level;
    u8      flags;
    u8      unk0;
    u8      type;
    u8      unk1;
    u8      attrId;
    u16     price;
    u8      shop;
    u8      unk2;
}
ItemData;

int IsItemInvalid(u16 itemId);
int IsItemNull(u16 itemId);
int IsItemRandomPlaceholder(u16 itemId);
int IsItemElementalGun(u16 itemId);
int IsItemOnion(u16 itemId);
int IsItemMinerva(u16 itemId);

const ItemData* GetItemData(u16 itemId);

#endif
