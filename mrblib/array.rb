##
# Array
#
# ISO 15.2.12
class Array
  ##
  # call-seq:
  #   array.each {|element| ... } -> self
  #   array.each -> Enumerator
  #
  # Calls the given block for each element of `self`
  # and pass the respective element.
  #
  # ISO 15.2.12.5.10
  def each(&block)
    return to_enum(:each) unless block

    idx = 0
    while idx < length
      yield self[idx]
      idx += 1
    end
    self
  end

  ##
  # call-seq:
  #   array.each_index {|index| ... } -> self
  #   array.each_index -> Enumerator
  #
  # Calls the given block for each element of `self`
  # and pass the index of the respective element.
  #
  # ISO 15.2.12.5.11
  def each_index(&block)
    return to_enum(:each_index) unless block

    idx = 0
    while idx < length
      yield idx
      idx += 1
    end
    self
  end

  ##
  # call-seq:
  #   array.collect! {|element| ... } -> self
  #   array.collect! -> new_enumerator
  #
  # Calls the given block for each element of `self`
  # and pass the respective element. Each element will
  # be replaced by the resulting values.
  #
  # ISO 15.2.12.5.7
  def collect!(&block)
    return to_enum(:collect!) unless block
    # An empty array assigns no element below, so nothing else on this path
    # asks whether the receiver may be written to.
    raise FrozenError, "can't modify frozen #{self.class}" if frozen?

    idx = 0
    len = size
    while idx < len
      self[idx] = yield(self[idx])
      idx += 1
    end
    self
  end

  ##
  # call-seq:
  #   array.map! {|element| ... } -> self
  #   array.map! -> new_enumerator
  #
  # Alias for collect!
  #
  # ISO 15.2.12.5.20
  alias map! collect!

  ##
  # call-seq:
  #   array.sort -> new_array
  #   array.sort {|a, b| ... } -> new_array
  #
  # Returns a new Array whose elements are those from `self`, sorted.
  #
  # With a block, the block orders each pair of elements as it does for
  # `Array#sort!`, which states what the block is to return.
  def sort(&block)
    self.dup.sort!(&block)
  end

  ##
  # call-seq:
  #   array.deconstruct -> self
  #
  # Returns self. Used for array pattern matching in case/in expressions.
  #
  def deconstruct
    self
  end

  ##
  # Array is enumerable
  # ISO 15.2.12.3
  include Enumerable
end

class Array
  alias __c_initialize initialize

  # Array.new(n) { ... } used to run entirely in C: mrb_ary_init loops over
  # the elements and calls mrb_yield for each one. mrb_yield does not return
  # to the interpreter frame that called Array.new; it starts a fresh
  # mrb_vm_exec for the block body and returns to C when it finishes.
  #
  # Under the yk JIT every mrb_vm_exec instance has its own control point, so
  # the C loop made the tracer stop at the C frame, enter the JIT once per
  # element for a tiny trace of the block body, and exit again. On the AWFY
  # Storage benchmark that was 5.46M trace entries per iteration and most of
  # the slowdown against plain mruby. Outlining mrb_ary_init cannot help: the
  # cost is inside the nested mrb_vm_exec, not in the loop around it.
  #
  # Looping here instead makes each yield an ordinary bytecode send inside
  # the same mrb_vm_exec, so the loop, the yield and the block body land in
  # one trace. C still validates the size and sets the length (and handles
  # the block-less forms unchanged); only the per-element fill moved to Ruby.
  def initialize(size = 0, obj = nil, &blk)
    # Only the common Integer+block case is handled here; everything else
    # (no block, Array/Float/bad sizes) keeps the exact C behaviour.
    return __c_initialize(size, obj, &blk) unless blk && size.kind_of?(Integer)
    __c_initialize(size)  # sets the length (nil-filled)
    n = self.size
    i = 0
    while i < n
      self[i] = yield i
      i += 1
    end
    self
  end
end
