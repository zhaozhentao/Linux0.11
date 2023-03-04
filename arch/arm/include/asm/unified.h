#define PSR_ISETSTATE	0

#define ARM(x...)	x
#define THUMB(x...)
#ifdef __ASSEMBLY__
#define W(instr)	instr
#endif
#define BSYM(sym)	sym

#ifdef __ASSEMBLY__
.macro itet, cond
.endm
#endif	/* __ASSEMBLY__ */

