/**
 * D header file for GNU/Linux
 *
 * $(LINK2 http://sourceware.org/git/?p=glibc.git;a=blob;f=elf/link.h, glibc elf/link.h)
 */
module sys.linux.link;

version(linux):
extern(C):
// nothrow:

import core.stdc.stdint /+ : uintptr_t, uint32_t +/;
import sys.linux.config /+ : __WORDSIZE +/;
// import sys.linux.dlfcn /+ : Lmid_t +/;
alias Lmid_t = long;
import sys.linux.elf;

// <bits/elfclass.h>
version (X86) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (X86_64) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (MIPS32) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (MIPS64) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (PPC) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (PPC64) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (ARM) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else version (AArch64) {
	// http://sourceware.org/git/?p=glibc.git;a=blob;f=bits/elfclass.h
	alias __ELF_NATIVE_CLASS = __WORDSIZE;
	alias Elf_Symndx = uint32_t;
} else {
	static assert(0, "unimplemented");
}
// <bits/elfclass.h>

template ElfW(string Type) {
	// mixin("alias Elf"~__ELF_NATIVE_CLASS.stringof~"_"~type~" ElfW;");
	
	// stringof not implemented, hardcode 64 in there.
	mixin("alias ElfW = Elf64_" ~ Type ~ ";");
}

enum {
	RT_CONSISTENT,
	RT_ADD,
	RT_DELETE,
}

struct r_debug {
	int r_version;
	link_map* r_map;
	ElfW!"Addr" r_brk;
	typeof(RT_CONSISTENT) r_state;
	ElfW!"Addr" r_ldbase;
}

// extern r_debug _r_debug;
// extern ElfW!"Dyn"* _DYNAMIC;

struct link_map {
	ElfW!"Addr" l_addr;
	char* l_name;
	ElfW!"Dyn"* l_ld;
	link_map* l_next, l_prev;
}

enum {
	LA_ACT_CONSISTENT,
	LA_ACT_ADD,
	LA_ACT_DELETE,
}

enum {
	LA_SER_ORIG = 0x01,
	LA_SER_LIBPATH = 0x02,
	LA_SER_RUNPATH = 0x04,
	LA_SER_CONFIG = 0x08,
	LA_SER_DEFAULT = 0x40,
	LA_SER_SECURE = 0x80,
}

enum {
	LA_FLG_BINDTO = 0x01,
	LA_FLG_BINDFROM = 0x02,
}

enum {
	LA_SYMB_NOPLTENTER = 0x01,
	LA_SYMB_NOPLTEXIT = 0x02,
	LA_SYMB_STRUCTCALL = 0x04,
	LA_SYMB_DLSYM = 0x08,
	LA_SYMB_ALTVALUE = 0x10,
}

struct dl_phdr_info {
	ElfW!"Addr" dlpi_addr;
	const(char)* dlpi_name;
	const(ElfW!"Phdr")* dlpi_phdr;
	ElfW!"Half" dlpi_phnum;
	
	// check the SIZE argument of the dl_iterate_phdr callback whether
	// the following members are available
	ulong dlpi_adds;
	ulong dlpi_subs;
	
	size_t dlpi_tls_modid;
	void *dlpi_tls_data;
}

private alias __Callback = /+ extern(C) +/ int function(dl_phdr_info*, size_t, void *);
/+ extern +/ int dl_iterate_phdr(__Callback __callback, void*__data);


// ld.so auditing interfaces prototypes have to be defined by the auditing DSO.
/+ extern +/ uint la_version(uint __version);
/+ extern +/ void la_activity(uintptr_t *__cookie, uint __flag);
/+ extern +/ char* la_objsearch(const(char)* __name, uintptr_t* __cookie,
                          uint __flag);
/+ extern +/ uint la_objopen(link_map* __map, Lmid_t __lmid,
                       uintptr_t* __cookie);
/+ extern +/ void la_preinit(uintptr_t* __cookie);
/+ extern +/ uintptr_t la_symbind32(Elf32_Sym* __sym, uint __ndx,
                              uintptr_t* __refcook, uintptr_t* __defcook,
                              uint *__flags, const(char)* __symname);
/+ extern +/ uintptr_t la_symbind64(Elf64_Sym* __sym, uint __ndx,
                              uintptr_t* __refcook, uintptr_t* __defcook,
                              uint* __flags, const(char)* __symname);
/+ extern +/ uint la_objclose(uintptr_t *__cookie);
