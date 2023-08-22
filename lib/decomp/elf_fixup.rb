module Decomp
  module ElfFixup
    def self.round_size(sz, rnd)
      sz + ((rnd - (sz % rnd)) % rnd)
    end

    def self.run(in_path, out_path)
      in_file = File.open(in_path, "rb")
      elf_header = in_file.read(0x34)

      # We need to fetch all the sections and re-assemble them in order to
      # get a byte-for-byte equivalence

      e_entry = elf_header[0x18,4].unpack('L<').first
      e_shoff = elf_header[0x20,4].unpack('L<').first
      e_shnum = elf_header[0x30,2].unpack('S<').first
      e_shstrndx = elf_header[0x32,2].unpack('S<').first

      in_file.seek(e_shoff + 0x28 * e_shstrndx)
      tmph = in_file.read(0x28)
      strtable_off = tmph[0x10,4].unpack('L<').first
      strtable_len = tmph[0x14,4].unpack('L<').first

      in_file.seek(strtable_off)
      strtable = in_file.read(strtable_len)

      sections = []
      e_shnum.times do |i|
        in_file.seek(e_shoff + 0x28 * i)
        header = in_file.read(0x28)
        sh_name, sh_type, sh_flags, sh_addr, sh_offset, sh_size, sh_link, sh_info, sh_addralign, sh_entsize = *header.unpack('L<*')

        sh_size = 0 if sh_type == 0x08
        name = strtable[sh_name..-1].split("\x00", 2).first
        in_file.seek(sh_offset)
        data = in_file.read(sh_size)

        next if ['.shstrtab', '.symtab', '.strtab'].include?(name)
        if sh_type == 0x9
          sh_link = 0x3
          sh_addralign = 0x0
          sh_flags = 0x0
        end
        if sh_type == 0x01
          sh_addralign = 16
          sh_entsize = 1
        end
        if sh_type == 0x08
          sh_addralign = 128
          sh_entsize = 1
        end
        if name == ".comment"
          sh_addralign = 1
          sh_entsize = 1
        end
        if name == ".rodata.sceVstub"
          sh_flags = 2
        end
        if (sh_type != 0x01 && sh_type != 0x08) || name == ".comment"
          sh_addr = 0
        end

        sections << { name: name, data: data, sh_type: sh_type, sh_flags: sh_flags, sh_addr: sh_addr, sh_size: sh_size, sh_link: sh_link, sh_info: sh_info, sh_addralign: sh_addralign, sh_entsize: sh_entsize }
      end

      # Fixup and reposition the strtab
      sections = [sections[0], { name: '.shstrtab', data: "", sh_type: 0x03, sh_flags: 0, sh_addr: 0, sh_size: 0, sh_link: 0, sh_info: 0, sh_addralign: 1, sh_entsize: 1 }, *sections[1..-1]]
      fixedstrtab = sections.map{|x| x[:name] + "\x00"}.join("")
      sections[1][:data] = fixedstrtab
      sections[1][:sh_size] = fixedstrtab.size

      # Name fixup
      off = 0
      sections.each do |sec|
        sec[:sh_name] = off
        off += sec[:name].size + 1
      end

      # Setup the sections locations
      # Final Layout:
      # - elf header
      # - program header
      # - sections
      # - section header
      # - strtable
      # - comment

      off = 0x34 + 0x20
      sections[0][:sh_offset] = 0
      sections.each do |sec|
        next if ['.shstrtab', '.comment', ''].include?(sec[:name])
        sec[:sh_offset] = off
        off += round_size(sec[:data].size, 4)
      end
      section_header_offset = off
      off += 0x28 * sections.size
      sections.each do |sec|
        next if sec[:name] != '.shstrtab'
        sec[:sh_offset] = off
        off += round_size(sec[:data].size, 4)
      end
      sections.each do |sec|
        next if sec[:name] != '.comment'
        sec[:sh_offset] = off
        off += round_size(sec[:data].size, 4)
      end

      # Fixup the REL file offsets & info
      sections.each.with_index do |sec, i|
        next if sec[:sh_type] != 0x09
        sec[:sh_offset] = sections[1][:sh_offset]
        sec[:sh_info] = i + 1
      end

      # Generate a blank file
      dst_size = 0x34 + 0x28 * sections.size + 0x20 + sections.map{|x| round_size(x[:data].size, 4)}.reduce(:+)
      buffer = "\x00" * dst_size

      # Write all the sections data
      sections.each do |sec|
        buffer[sec[:sh_offset], sec[:data].size] = sec[:data]
      end

      # Write the section header
      header = sections.map {|x| [x[:sh_name], x[:sh_type], x[:sh_flags], x[:sh_addr], x[:sh_offset], x[:sh_size], x[:sh_link], x[:sh_info], x[:sh_addralign], x[:sh_entsize]].pack('L<*') }.join('')
      buffer[section_header_offset, header.size] = header

      # Write the program header
      header = [
        0x01, # p_type
        sections[2][:sh_offset], # p_offset
        sections[2][:sh_addr], # p_vaddr
        sections[14][:sh_offset], # p_paddr
        sections.filter{|x| x[:sh_type] == 0x01 && x[:name] != ".comment"}.map{|x| x[:sh_size]}.reduce(:+), # p_filesz
        0xfe5200, # p_memsz (HARDCODED)
        0x07, # p_flags
        0x10, # p_align
      ].pack("L<*")
      buffer[0x34, header.size] = header

      # Write the ELF Header
      header = [
        "\x7fELF",
        0x01,
        0x01,
        0x01,
        0x00,
        0x00,
        0x00,
        0x0002,
        0x0008,
        0x01,
        e_entry, # e_entry
        0x34, # e_phoff
        section_header_offset, # e_shoff
        0x10a23001, # e_flags
        0x34, # e_ehsize
        0x20, # e_phentsize
        0x01, # e_phnum
        0x28, # e_shentsize
        sections.size, # e_shnum
        0x01, # e_shstrndx
      ].pack('a4c4L<2S<2L<5S<6')
      buffer[0, header.size] = header

      File.binwrite(out_path, buffer)
    end
  end
end
