require 'fileutils'
require 'decomp/common'
require 'decomp/elf_wrapper'
require 'decomp/chunk_set'

module Decomp
  module ElfExtractor
    SECTIONS = [
      '.text',
      '.sceStub.text',
      '.lib.ent.top',
      '.lib.ent',
      '.lib.ent.btm',
      '.lib.stub.top',
      '.lib.stub',
      '.lib.stub.btm',
      '.rodata.sceModuleInfo',
      '.rodata.sceResident',
      '.rodata.sceNid',
      '.rodata.sceVstub',
      '.data',
      '.bss',
      '.comment',
    ]

    def self.run
      # Load the ELF file
      f = File.open(File.join(ROOT, 'rom', 'BOOT.BIN'), 'rb')
      data = f.read
      f.close

      # Parse the ELF header
      e_shoff = data[0x20,4].unpack('L<')[0]
      e_shnum = data[0x30,2].unpack('S<')[0]
      e_shstrndx = data[0x32,4].unpack('S<')[0]

      # Get the base address of the section header string table
      shstrtab = data[e_shoff + e_shstrndx * 0x28 + 0x10,4].unpack('L<')[0]

      # Parse the section header
      cs = ChunkSet.new
      e_shnum.times do |i|
        sh_name = data[e_shoff + i * 0x28 + 0x00,4].unpack('L<')[0]
        name = data[shstrtab + sh_name, data[shstrtab + sh_name..-1].index("\x00")].strip
        next unless SECTIONS.include?(name)
        sh_addr = data[e_shoff + i * 0x28 + 0x0c,4].unpack('L<')[0]
        sh_offset = data[e_shoff + i * 0x28 + 0x10,4].unpack('L<')[0]
        sh_size = data[e_shoff + i * 0x28 + 0x14,4].unpack('L<')[0]
        section_data = data[sh_offset, sh_size]
        cs.add_raw(name, sh_addr, sh_size, section_data)
      end

      cs
    end
  end
end
