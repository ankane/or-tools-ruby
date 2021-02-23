module ORTools
  class ObjectiveSolutionPrinter < CpSolverSolutionCallback
    attr_reader :solution_count

    def initialize
      super
      @solution_count = 0
      @start_time = Time.now
    end

    def on_solution_callback
      current_time = Time.now
      obj = objective_value
      puts "Solution %i, time = %0.2f s, objective = %i" % [@solution_count, current_time - @start_time, obj]
      @solution_count += 1
    end
  end
end
