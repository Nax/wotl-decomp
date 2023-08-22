require 'fileutils'
require 'decomp/common'
require 'decomp/elf_wrapper'
require 'decomp/elf_extractor'
require 'decomp/elf_fixup'

module Decomp
  def self.object_name(section, addr)
    "raw_#{"%08x" % addr}_#{section[1..-1]}.o"
  end

  def self.make_linker_script(chunk_set)
    substitutions = {}
    files = {}
    section = nil
    section_files = nil
    chunk_set.chunks.each do |chunk|
      if chunk.section != section
        section = chunk.section
        section_files = []
        files[section] = section_files
      end

      if chunk.type == :raw
        section_files << "build/gen/obj/#{object_name(chunk.section, chunk.addr)}"
      end
    end

    files.each do |section, section_files|
      key = 'FILES_' + section[1..-1].gsub('.', ' ').strip.gsub(' ', '_').upcase
      substitutions[key] = section_files.map{|f| "#{f}(#{section})"}.join(' ')
    end

    template = File.read(File.join(ROOT, 'wotl.ld.in'))
    template.gsub!(/@(\w+)@/) do |match|
      substitutions[$1]
    end
    File.write(File.join(ROOT, 'build', 'gen', 'wotl.ld'), template)
  end

  def self.make_objects(chunk_set)
    raws = chunk_set.chunks.select { |c| c.type == :raw }
    raws.each do |raw|
      object_data = ElfWrapper.run(raw.section, raw.data)
      File.binwrite(File.join(ROOT, 'build', 'gen', 'obj', object_name(raw.section, raw.addr)), object_data)
    end
  end

  def self.run(args)
    # Make the build tree
    FileUtils.mkdir_p(File.join(ROOT, 'build', 'gen', 'obj'))
    FileUtils.mkdir_p(File.join(ROOT, 'build', 'bin'))

    # Extract the chunks
    chunks = ElfExtractor.run
    make_objects(chunks)
    make_linker_script(chunks)

    # Make
    system("make -C #{ROOT}")

    # Fix the build
    ElfFixup.run(File.join(ROOT, 'build', 'bin', 'BOOT.elf'), File.join(ROOT, 'build', 'bin', 'BOOT.BIN'))
  end
end
