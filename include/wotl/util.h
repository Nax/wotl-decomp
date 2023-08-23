#ifndef WOTL_UTIL_H
#define WOTL_UTIL_H

#define if_unlikely(cond) \
    if (!(cond))          \
    {                     \
    }                     \
    else

#define if_likely(cond) if_unlikely(!((cond)))

#endif
