require 'decomp/chunk'

module Decomp
  class ChunkSet
    attr_reader :chunks

    def initialize
      @chunks = []
    end

    def add_chunk(chunk)
      @chunks << chunk
      @chunks.sort_by! { |c| c.addr }
    end

    def add_raw(section, addr, size, data)
      add_chunk(Chunk.new(:raw, section, addr, size, data))
    end

    def add_file(section, addr, size, filename)
      new_chunk = Chunk.new(:file, section, addr, size, filename)

      # We need to find the overlapping chunk
      overlaps = @chunks.select { |c| c.addr_range.cover?(new_chunk.addr) || new_chunk.addr_range.cover?(c.addr) }
      if overlaps.size != 1
        raise "#{filename}:#{section}: Chunk overlapping error"
      end
      overlap = overlaps[0]
      if overlap.type != :raw
        raise "#{filename}:#{section}: Files overlapping each other"
      end

      # Temp remove the chunk
      @chunks = @chunks - [overlap]

      # Add the first part of the chunk
      if overlap.addr < new_chunk.addr
        add_chunk(Chunk.new(:raw, overlap.section, overlap.addr, new_chunk.addr - overlap.addr, overlap.data[0, new_chunk.addr - overlap.addr]))
      end

      # Add the new chunk
      add_chunk(new_chunk)

      # Add the last part of the chunk
      if overlap.addr + overlap.size > new_chunk.addr + new_chunk.size
        add_chunk(Chunk.new(:raw, overlap.section, new_chunk.addr + new_chunk.size, overlap.addr + overlap.size - (new_chunk.addr + new_chunk.size), overlap.data[(new_chunk.addr + new_chunk.size) - overlap.addr, overlap.addr + overlap.size - (new_chunk.addr + new_chunk.size)]))
      end
    end
  end
end
