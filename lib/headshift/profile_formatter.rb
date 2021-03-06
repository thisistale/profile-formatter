require 'cucumber/formatter/progress'

module Headshift
  class ProfileFormatter < Cucumber::Formatter::Progress
    def initialize(step_mother, io, options)
      super
      
      @steps = {}
      @examples = {}
      @failures = []
    end
    
    def before_features(*args)
      @start_time = Time.now
    end
    
    def after_features(*args)
      puts
      puts "======================="
      puts "#{@steps.count} steps and #{@examples.count} examples executed in #{Time.at(Time.now - @start_time).gmtime.strftime("%Hh %Mm %Ss")}"
      puts
      print_formatted_hash(@steps, "Steps")
      puts
      print_formatted_hash(@examples, "Examples")
      unless @failures.empty?
        puts "======================="
        puts "Failing Scenarios:"
        @failures.each do |failure|
          puts "cucumber #{failure}"
        end
      end
    end
    
    def before_step(*args)
      @timestamp = Time.now
    end
    
    def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
      if status == :passed
        time = Time.now - @timestamp
        key = step_match.file_colon_line
        
        if @steps.has_key? key
          # Incremental average time: http://jvminside.blogspot.com/2010/01/incremental-average-calculation.html
          @steps[key][:count] += 1
          @steps[key][:avg_time] += (time - @steps[key][:avg_time]) / @steps[key][:count]
          @steps[key][:tot_time] += time
        else
          @steps[key] = {:count => 1, :avg_time => time, :tot_time => time}
        end
      elsif status == :failed
        @failures << @scenario_file_colon_line
      end
      
      super
    end
    
    def before_examples(examples)
      @processing_examples = true
      @processing_title_row = true
      @outline_file_colon_line = @scenario_file_colon_line
    end
    
    def after_examples(examples)
      @processing_examples = false
    end
    
    def before_table_row(table_row)
      if @processing_examples
        @ts = Time.now
      end
    end
    
    def after_table_row(table_row)
      if @processing_examples
        unless @processing_title_row
          time = Time.now - @ts
          key = @outline_file_colon_line
        
          if @examples.has_key? key
            # Incremental average time: http://jvminside.blogspot.com/2010/01/incremental-average-calculation.html
            @examples[key][:count] += 1
            @examples[key][:avg_time] += (time - @examples[key][:avg_time]) / @examples[key][:count]
            @examples[key][:tot_time] += time
          else
            @examples[key] = {:count => 1, :avg_time => time, :tot_time => time}
          end
        else
          @processing_title_row = false
        end
      end
    end
    
    def scenario_name(keyword, name, file_colon_line, source_indent)
      @scenario_file_colon_line = file_colon_line
    end
    
    private
      def print_formatted_hash(hash, title, sort_by=:tot_time, limit=20)
        key_width = title.length
        count_width = avg_time_width = tot_time_width = 0
        hash.each do |key, value|
          key_width = [key_width, key.length].max
          count_width = [count_width, value[:count].to_s.length].max
          avg_time_width = [avg_time_width, ("%.6f" % value[:avg_time]).length].max
          tot_time_width = [tot_time_width, ("%.6f" % value[:tot_time]).length].max
        end
      
        sorted_hash = hash.sort {|x,y| x[1][sort_by] <=> y[1][sort_by]}
      
        puts "| #{title.ljust(key_width)} | #{"#".ljust(count_width)} | #{"Avg Time".ljust(avg_time_width)} | #{"Tot Time".ljust(tot_time_width)} |"
        sorted_hash.reverse[0..limit].each do |step|
          puts "| #{step[0].ljust(key_width)} | #{step[1][:count].to_s.ljust(count_width)} | #{("%.6f" % step[1][:avg_time]).ljust(avg_time_width)} | #{("%.6f" % step[1][:tot_time]).ljust(tot_time_width)} |"
        end
      end
  end
end