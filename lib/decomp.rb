require 'fileutils'
require 'yaml'
require 'digest'
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

      if chunk.type == :file
        section_files << "build/obj/#{chunk.data}.o"
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
    stamp_path = File.join(ROOT, 'build', 'gen', 'obj.stamp')
    wotl_path = File.join(ROOT, 'wotl.yml')
    return if FileUtils.uptodate?(stamp_path, [wotl_path])

    # Delete the old objects
    Dir.glob(File.join(ROOT, 'build', 'gen', 'obj', '*.o')).each do |f|
      File.delete(f)
    end

    # Make the new objects
    raws = chunk_set.chunks.select { |c| c.type == :raw }
    raws.each do |raw|
      object_data = ElfWrapper.run(raw.section, raw.data)
      File.binwrite(File.join(ROOT, 'build', 'gen', 'obj', object_name(raw.section, raw.addr)), object_data)
    end

    # Stamp the build
    FileUtils.touch(stamp_path)
  end

  def self.splice_chunks(chunks)
    data = YAML.load_file(File.join(ROOT, 'wotl.yml'))
    data['files'].each do |ff|
      name = ff['name']
      ff['sections'].each do |section, sdata|
        sstart = sdata[0]
        send = sdata[1]
        ssize = send - sstart
        chunks.add_file(".#{section}", sstart, ssize, name)
      end
    end
  end

  def self.find_diff()
    good_file_path = File.join(ROOT, 'rom', 'BOOT.BIN')
    bad_file_path = File.join(ROOT, 'build', 'bin', 'BOOT.BIN')
    good_file = File.open(good_file_path, 'rb')
    bad_file = File.open(bad_file_path, 'rb')
    good_file.seek(0x54)
    bad_file.seek(0x54)
    vaddr = 0x08804000
    while true
      good_data = good_file.read(4)
      bad_data = bad_file.read(4)
      if good_data != bad_data
        return vaddr
      end
      vaddr += 4
    end
  end

  def self.validate()
    target_sum = "ae0319c5c31885930d76a5c7dc1d389cd664365c48205ed887f002e01ed4abc4"
    target_path = File.join(ROOT, 'build', 'bin', 'BOOT.BIN')
    if Digest::SHA256.file(target_path).hexdigest != target_sum
      puts "Image NOT matching!"
      addr = find_diff()
      puts "Diff at 0x#{"%08x" % addr}"
      exit(1)
    end
    puts "Image matching!"
  end

  def self.run(args)
    # Make the build tree
    FileUtils.mkdir_p(File.join(ROOT, 'build', 'gen', 'obj'))
    FileUtils.mkdir_p(File.join(ROOT, 'build', 'bin'))

    # Extract the chunks
    chunks = ElfExtractor.run
    splice_chunks(chunks)
    make_objects(chunks)
    make_linker_script(chunks)

    # Make
    system("make -C #{ROOT}")

    # Fix the build
    ElfFixup.run(File.join(ROOT, 'build', 'bin', 'BOOT.elf'), File.join(ROOT, 'build', 'bin', 'BOOT.BIN'))

    # Validate
    validate()
  end
end
