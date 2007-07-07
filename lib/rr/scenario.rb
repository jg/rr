module RR
  # RR::Scenario is the use case for a method call.
  # It has the ArgumentEqualityExpectation, TimesCalledExpectation,
  # and the implementation.
  class Scenario
    attr_reader :times_called, :argument_expectation, :times_called_expectation

    def initialize(space)
      @space = space
      @implementation = nil
      @argument_expectation = nil
      @times_called_expectation = nil
      @times_called = 0
    end

    # Scenario#with creates an ArgumentEqualityExpectation for the
    # Scenario. it takes a list of expected arguments.
    #
    # Passing in a block sets the return value.
    #
    #   mock(subject).method_name.with(1, 2) {:return_value}
    def with(*args, &returns)
      @argument_expectation = Expectations::ArgumentEqualityExpectation.new(*args)
      returns(&returns) if returns
      self
    end

    # Scenario#with_any_args creates an AnyArgumentEqualityExpectation
    # for the Scenario.
    #
    # Passing in a block sets the return value.
    #
    #   mock(subject).method_name.with_any_args {:return_value}
    def with_any_args(&returns)
      @argument_expectation = Expectations::AnyArgumentExpectation.new
      returns(&returns) if returns
      self
    end

    # Scenario#once creates an TimesCalledExpectation of 1.
    #
    # Passing in a block sets the return value.
    #
    #   mock(subject).method_name.once {:return_value}
    def once(&returns)
      @times_called_expectation = Expectations::TimesCalledExpectation.new(1)
      returns(&returns) if returns
      self
    end

    # Scenario#twice creates an TimesCalledExpectation of 2.
    #
    # Passing in a block sets the return value.
    #
    #   mock(subject).method_name.twice {:return_value}
    def twice(&returns)
      @times_called_expectation = Expectations::TimesCalledExpectation.new(2)
      returns(&returns) if returns
      self
    end

    # Scenario#twice creates an TimesCalledExpectation of the passed
    # in number.
    #
    # Passing in a block sets the return value.
    #
    #   mock(subject).method_name.times(4) {:return_value}
    def times(number, &returns)
      @times_called_expectation = Expectations::TimesCalledExpectation.new(number)
      returns(&returns) if returns
      self
    end

    # Scenario#ordered sets the Scenario to have an ordered
    # expectation.
    #
    # Passing in a block sets the return value.
    #
    #   mock(subject).method_name.ordered {return_value}
    def ordered(&returns)
      @ordered = true
      @space.ordered_scenarios << self unless @space.ordered_scenarios.include?(self)
      returns(&returns) if returns
      self
    end

    # Scenario#ordered? returns true when the Scenario is ordered.
    #
    #   mock(subject).method_name.ordered?
    def ordered?
      @ordered
    end

    # Scenario#returns causes Scenario to return the return value of
    # the passed in block.
    def returns(&implementation)
      implemented_by implementation
    end

    # Scenario#implemented_by sets the implementation of the Scenario.
    # This method takes a Proc or a Method. Passing in a Method allows
    # the Scenario to accept blocks.
    #
    #   obj = Object.new
    #   def obj.foobar
    #     yield(1)
    #   end
    #   mock(obj).method_name.implemented_by(obj.method(:foobar))
    def implemented_by(implementation)
      @implementation = implementation
      self
    end

    # Scenario#call calls the Scenario's implementation. The return
    # value of the implementation is returned.
    def call(*args, &block)
      @times_called_expectation.verify_input if @times_called_expectation
      @space.verify_ordered_scenario(self) if ordered?
      return nil unless @implementation

      if @implementation.is_a?(Method)
        return @implementation.call(*args, &block)
      else
        args << block if block
        return @implementation.call(*args)
      end
    end

    # Scenario#exact_match? returns true when the passed in arguments
    # exactly match the ArgumentEqualityExpectation arguments.
    def exact_match?(*arguments)
      return false unless @argument_expectation 
      @argument_expectation.exact_match?(*arguments)
    end

    # Scenario#wildcard_match? returns true when the passed in arguments
    # wildcard match the ArgumentEqualityExpectation arguments.
    def wildcard_match?(*arguments)
      return false unless @argument_expectation
      @argument_expectation.wildcard_match?(*arguments)
    end

    def times_called_verified?
      return false unless @times_called_expectation
      @times_called_expectation.verify
    end

    def verify
      return true unless @times_called_expectation
      @times_called_expectation.verify!
      true
    end
  end
end