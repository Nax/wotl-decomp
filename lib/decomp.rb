require 'fileutils'
require 'decomp/common'
require 'decomp/elf_wrapper'
require 'decomp/elf_extractor'
require 'decomp/elf_fixup'

module Decomp
  def self.run(args)
    # Make the build tree
    FileUtils.mkdir_p(File.join(ROOT, 'build', 'gen', 'obj'))
    FileUtils.mkdir_p(File.join(ROOT, 'build', 'bin'))

    # Extract the object files
    ElfExtractor.run

    # Make
    system("make -C #{ROOT}")

    # Fix the build
    ElfFixup.run(File.join(ROOT, 'build', 'bin', 'BOOT.elf'), File.join(ROOT, 'build', 'bin', 'BOOT.BIN'))
  end
end
