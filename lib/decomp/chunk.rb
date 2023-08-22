module Decomp
  class Chunk
    attr_reader :type, :section, :addr, :size, :data

    def initialize(type, section, addr, size, data)
      @type = type
      @section = section
      @data = data
      @addr = addr
      @size = size
    end

    def addr_range
      @addr..(@addr + @size - 1)
    end
  end
end
