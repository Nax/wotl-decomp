ENTRY(_start)

PHDRS
{
  text    PT_LOAD ;
}

SECTIONS
{
  . = 0x08804000;

  .text : { *(.text) } :text
  .rel.text : { . = .; }

  .sceStub.text : { *(.sceStub.text) } :text
  .rel.sceStub.text : { . = .; }

  .lib.ent.top : { *(.lib.ent.top) } :text
  .lib.ent : { *(.lib.ent) } :text
  .rel.lib.ent : { . = .; }
  .lib.ent.btm : { *(.lib.ent.btm) } :text

  .lib.stub.top : { *(.lib.stub.top) } :text
  .lib.stub : { *(.lib.stub) } :text
  .rel.lib.stub : { . = .; }
  .lib.stub.btm : { *(.lib.stub.btm) } :text

  .rodata.sceModuleInfo : { *(.rodata.sceModuleInfo) } :text
  .rel.rodata.sceModuleInfo : { . = .; }
  .rodata.sceResident : { *(.rodata.sceResident) } :text
  .rel.rodata.sceResident : { . = .; }
  .rodata.sceNid : { *(.rodata.sceNid) } :text
  .rodata.sceVstub : { . = .; } :text

  .data : { *(.data) } :text
  .rel.data : { . = .; }

  .bss : { . = .; *(.bss) } :text

  .comment : { . = .; *(.comment) }

  /DISCARD/ : { *(.*) }

  _start = 0x08814b00;
}
