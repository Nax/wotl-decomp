module Decomp
  class ElfWrapper
    # Creates an object file with the provided data
    # inside a single section.
    def self.run(section, data)
      flags = 0x00
      align = 0x10
      type = 0x01 # SHT_PROGBITS
      case section
      when /\.text/
        flags = 0x06 # SHF_ALLOC | SHF_EXECINSTR
      when /\.rodata/, /\.lib/
        flags = 0x02 # SHF_ALLOC
      when /\.data/
        flags = 0x03 # SHF_ALLOC | SHF_WRITE
      when /\.bss/
        flags = 0x03 # SHF_ALLOC | SHF_WRITE
        type = 0x08 # SHT_NOBITS
      end
      elf = "\x00" * (0x3000 + data.length)

      # 0x0000 ELF header
      elf[0..3] = "\x7fELF"
      elf[0x04] = "\x01" # 32-bit
      elf[0x05] = "\x01" # little endian
      elf[0x06] = "\x01" # ELF version
      elf[0x07] = "\x00" # System V ABI
      elf[0x08] = "\x00" # ABI version
      elf[0x10] = "\x01" # Relocatable
      elf[0x12] = "\x08" # MIPS
      elf[0x14] = "\x01" # ELF version
      elf[0x18,4] = [0].pack('L<') # Entry point
      elf[0x1c,4] = [0].pack('L<') # Program header offset
      elf[0x20,4] = [0x1000].pack('L<') # Section header offset
      elf[0x24,4] = [0x10970001].pack('L<') # Flags
      elf[0x28,2] = [0x34].pack('S<') # ELF header size
      elf[0x2a,2] = [0x20].pack('S<') # Program header entry size
      elf[0x2c,2] = [0x00].pack('S<') # Program header entry count
      elf[0x2e,2] = [0x28].pack('S<') # Section header entry size
      elf[0x30,2] = [0x03].pack('S<') # Section header entry count
      elf[0x32,2] = [0x01].pack('S<') # Section header string table index

      # 0x1000 - Setion header
      # Shared string table
      elf[0x1000 + 1 * 0x28 + 0x00,4] = [1].pack('L<') # Name offset
      elf[0x1000 + 1 * 0x28 + 0x04,4] = [3].pack('L<') # Type (SHT_STRTAB)
      elf[0x1000 + 1 * 0x28 + 0x08,4] = [0x20].pack('L<') # Flags
      elf[0x1000 + 1 * 0x28 + 0x0c,4] = [0].pack('L<') # Address
      elf[0x1000 + 1 * 0x28 + 0x10,4] = [0x2000].pack('L<') # Offset
      elf[0x1000 + 1 * 0x28 + 0x14,4] = [".shstrtab".length + section.length + 3].pack('L<') # Size
      elf[0x1000 + 1 * 0x28 + 0x18,4] = [0].pack('L<') # Link
      elf[0x1000 + 1 * 0x28 + 0x1c,4] = [0].pack('L<') # Info
      elf[0x1000 + 1 * 0x28 + 0x20,4] = [1].pack('L<') # Address alignment
      elf[0x1000 + 1 * 0x28 + 0x24,4] = [0].pack('L<') # Entry size

      # data
      elf[0x1000 + 2 * 0x28 + 0x00,4] = [".shstrtab".length + 2].pack('L<') # Name offset
      elf[0x1000 + 2 * 0x28 + 0x04,4] = [type].pack('L<') # Type (SHT_PROGBITS)
      elf[0x1000 + 2 * 0x28 + 0x08,4] = [flags].pack('L<') # Flags (SHF_ALLOC)
      elf[0x1000 + 2 * 0x28 + 0x0c,4] = [0].pack('L<') # Address
      elf[0x1000 + 2 * 0x28 + 0x10,4] = [0x3000].pack('L<') # Offset
      elf[0x1000 + 2 * 0x28 + 0x14,4] = [data.length].pack('L<') # Size
      elf[0x1000 + 2 * 0x28 + 0x18,4] = [0].pack('L<') # Link
      elf[0x1000 + 2 * 0x28 + 0x1c,4] = [0].pack('L<') # Info
      elf[0x1000 + 2 * 0x28 + 0x20,4] = [4].pack('L<') # Address alignment
      elf[0x1000 + 2 * 0x28 + 0x24,4] = [0].pack('L<') # Entry size

      # 0x2000 - .shstrtab data
      elf[0x2000 + 1, ".shstrtab".length] = ".shstrtab"
      elf[0x2000 + 1 + ".shstrtab".length + 1, section.length] = section

      # 0x3000 - data
      elf[0x3000, data.length] = data

      elf
    end
  end
end
