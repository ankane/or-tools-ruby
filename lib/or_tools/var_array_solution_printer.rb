module ORTools
  class VarArraySolutionPrinter < CpSolverSolutionCallback
    attr_reader :solution_count

    def initialize(variables)
      super()
      @variables = variables
      @solution_count = 0
      @start_time = Time.now
    end

    def on_solution_callback
      current_time = Time.now
      puts "Solution %i, time = %0.2f s" % [@solution_count, current_time - @start_time]
      puts @variables.map { |v| "  %s = %i" % [v.name, value(v)] }.join(" ")
      @solution_count += 1
    end
  end
end
