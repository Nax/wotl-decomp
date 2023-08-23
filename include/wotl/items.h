#ifndef WOTL_ITEMS_H
#define WOTL_ITEMS_H

#include <wotl/types.h>

int IsItemInvalid(u16 itemId);
int IsItemNull(u16 itemId);
int IsItemRandomPlaceholder(u16 itemId);
int IsItemElementalGun(u16 itemId);
int IsItemOnion(u16 itemId);
int IsItemMinerva(u16 itemId);

#endif
