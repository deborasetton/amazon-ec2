module AWS
  module Cloudwatch
    class Base < AWS::Base

      # This method call lists available Cloudwatch metrics attached to your EC2
      # account. To get further information from the metrics, you'll then need to
      # call get_metric_statistics.
      #
      # there are no options available to this method.
      def list_metrics
        return response_generator(:action => 'ListMetrics', :params => {})
      end

      # get_metric_statistics pulls a hashed array from Cloudwatch with the stats
      # of your requested metric.
      # Once you get the data out, if you assign the results into an object like:
      # res = @mon.get_metric_statistics(:measure_name => 'RequestCount', \
      #     :statistics => 'Average', :namespace => 'AWS/ELB')
      #
      # This call gets the average request count against your ELB at each sampling period
      # for the last 24 hours. You can then attach a block to the following iterator
      # to do whatever you need to:
      # res['GetMetricStatisticsResult']['Datapoints']['member'].each
      #
      # @option options [String] :custom_unit (nil) not currently available, placeholder
      # @option options [String] :dimensions (nil) Option to filter your data on. Check the developer guide
      # @option options [Time] :end_time (Time.now()) Outer bound of the date range you want to view
      # @option options [String] :measure_name (nil) The measure you want to check. Must correspond to
      # =>                                           provided options
      # @option options [String] :namespace ('AWS/EC2') The namespace of your measure_name. Currently, 'AWS/EC2' and 'AWS/ELB' are available
      # @option options [Integer] :period (60) Granularity in seconds of the returned datapoints. Multiples of 60 only
      # @option options [String] :statistics (nil) The statistics to be returned for your metric. See the developer guide for valid options. Required.
      # @option options [Time] :start_time (Time.now() - 86400) Inner bound of the date range you want to view. Defaults to 24 hours ago
      # @option options [String] :unit (nil) Standard unit for a given Measure. See the developer guide for valid options.
      def get_metric_statistics ( options ={} )
        options = { :custom_unit => nil,
                    :dimensions => nil,
                    :end_time => Time.now(),      #req
                    :measure_name => "",          #req
                    :namespace => "AWS/EC2",
                    :period => 60,
                    :statistics => "",            # req
                    :start_time => (Time.now() - 86400), # Default to yesterday
                    :unit => "" }.merge(options)

        raise ArgumentError, ":end_time must be provided" if options[:end_time].nil?
        raise ArgumentError, ":end_time must be a Time object" if options[:end_time].class != Time
        raise ArgumentError, ":start_time must be provided" if options[:start_time].nil?
        raise ArgumentError, ":start_time must be a Time object" if options[:start_time].class != Time
        raise ArgumentError, ":start_time must be before :end_time" if options[:start_time] > options[:end_time]
        raise ArgumentError, ":measure_name must be provided" if options[:measure_name].nil? || options[:measure_name].empty?
        raise ArgumentError, ":statistics must be provided" if options[:statistics].nil? || options[:statistics].empty?

        params = {
                    "CustomUnit" => options[:custom_unit],
                    "EndTime" => options[:end_time].iso8601,
                    "MeasureName" => options[:measure_name],
                    "Namespace" => options[:namespace],
                    "Period" => options[:period].to_s,
                    "StartTime" => options[:start_time].iso8601,
                    "Unit" => options[:unit]
        }

        # FDT: Fix statistics and dimensions values
        if !(options[:statistics].nil? || options[:statistics].empty?)
          stats_params = {}
          i = 1
          options[:statistics].split(',').each{ |stat|
            stats_params.merge!( "Statistics.member.#{i}" => "#{stat}" )
            i += 1
          }
          params.merge!( stats_params )
        end

        if !(options[:dimensions].nil? || options[:dimensions].empty?)
          dims_params = {}
          i = 1
          options[:dimensions].split(',').each{ |dimension|
            dimension_var = dimension.split('=')
            dims_params = dims_params.merge!( "Dimensions.member.#{i}.Name" => "#{dimension_var[0]}", "Dimensions.member.#{i}.Value" => "#{dimension_var[1]}" )
            i += 1
          }
          params.merge!( dims_params )
        end

        return response_generator(:action => 'GetMetricStatistics', :params => params)

      end
      
      # Deletes all specified alarms. In the event of an error, no alarms are deleted.
      #
      # @option options [Array] :alarm_names (nil) a list of alarms to be deleted. 
      def delete_alarms( options={})
        raise ArgumentError, "No :alarm_names provided" if options[:alarm_names].nil? || options[:alarm_names].empty?
        
        params ={}
        
        params.merge!(pathlist('AlarmNames.member', options[:alarm_names].flatten)) 
        
        return response_generator(:action => 'DeleteAlarms', :params => params)
        
      end
      
      # Creates or updates an alarm and associates it with the specified Amazon CloudWatch metric. 
      # Optionally, this operation can associate one or more Amazon Simple Notification Service resources with the alarm.
      #
      # @option options [optional, Boolean] :actions_enabled (false) indicates whether or not actions should be executed during any changes to the alarm's state.
      # @option options [optional, Array] :alarm_actions (nil) the list of actions to execute when this alarm transitions into an ALARM state from any other state. Each action is specified as an Amazon Resource Number (ARN). 
      # @option options [optional, String] :alarm_description (nil) the description for the alarm.
      # @option options [String] :alarm_name (nil) the descriptive name for the alarm. This name must be unique within the user's AWS account.
      # @option options [String] :comparison_operator (nil) the arithmetic operation to use when comparing the specified 
      # => Statistic and Threshold. Valid Values: GreaterThanOrEqualToThreshold | GreaterThanThreshold | LessThanThreshold | LessThanOrEqualToThreshold
      # @option options [optional, Array] :dimensions (nil) the dimensions for the alarm's associated metric.
      # @option options [Integer] :evaluation_periods (nil) the number of periods over which data is compared to the specified threshold.
      # @option options [optional, Array] :insufficient_data_actions (nil) the list of actions to execute when this alarm transitions into an INSUFFICIENT_DATA state from any other state.
      # @option options [String] :metric_name (nil) the name for the alarm's associated metric.
      # @option options [String] :namespace (nil) the namespace for the alarm's associated metric.
      # @option options [optional, Array] :ok_actions (nil) the list of actions to execute when this alarm transitions into an OK state from any other state.
      # @option options [Integer] :period (nil) the period in seconds over which the specified statistic is applied.
      # @option options [String] :statistic (nil) the statistic to apply to the alarm's associated metric.
      # => Valid Values: SampleCount | Average | Sum | Minimum | Maximum
      # @option options [Double] :threshold (nil) the value against which the specified statistic is compared.
      # @option options [optional, String] :unit (nil) the unit for the alarm's associated metric.
      # => Valid Values: Seconds | Microseconds | Milliseconds | Bytes | Kilobytes | Megabytes | Gigabytes | Terabytes | 
      # => Bits | Kilobits | Megabits | Gigabits | Terabits | Percent | Count | Bytes/Second | Kilobytes/Second | 
      # => Megabytes/Second | Gigabytes/Second | Terabytes/Second | Bits/Second | Kilobits/Second | Megabits/Second | 
      # => Gigabits/Second | Terabits/Second | Count/Second | None 
      def put_metric_alarm( options={})
        #raise ArgumentError, ":alarm_name must be provided" if options[:alarm_name].nil? || options[:alarm_name].empty?
        #raise ArgumentError, ":comparison_operator must be provided" if options[:comparison_operator].nil? || options[:comparison_operator].empty?
        #raise ArgumentError, ":evaluation_periods must be provided" if options[:evaluation_periods].nil?
        #raise ArgumentError, ":metric_name must be provided" if options[:metric_name].nil? || options[:metric_name].empty?
        #raise ArgumentError, ":namespace must be provided" if options[:namespace].nil? || options[:namespace].empty?
        #raise ArgumentError, ":period must be provided" if options[:period].nil?
        #raise ArgumentError, ":statistic must be provided" if options[:statistic].nil? || options[:statistic].empty?
        #raise ArgumentError, ":statistic value is invalid" if not valid_statistic_values.index(options[:statistic])
        #raise ArgumentError, ":threshold must be provided" if options[:threshold].nil?        
        #raise ArgumentError, ":unit value is invalid" if ((not options[:unit].nil?) and (not valid_unit_values.index(options[:unit])))        
       
        params = {
                    'AlarmName' => options[:alarm_name],
                    'ComparisonOperator' => options[:comparison_operator],
                    'EvaluationPeriods' => options[:evaluation_periods].to_s,
                    'MetricName' => options[:metric_name],
                    'Namespace' => options[:namespace],
                    'Period' => options[:period].to_s,
                    'Statistic' => options[:statistic],
                    'Threshold' => options[:threshold].to_s
        }
        
        # Optional parameters
        
        params['Force'] = options[:force].to_s unless options[:force].nil?
        params.merge!(pathlist('AlarmActions.member', [options[:alarm_actions]].flatten)) if options.has_key?(:alarm_actions)
        params['AlarmDescription'] = options[:alarm_description] if options.has_key?(:alarm_description)
        params.merge!(pathlist('InsufficientDataActions.member', [options[:insufficient_data_actions]].flatten)) if options.has_key?(:insufficient_data_actions)
        params.merge!(pathlist('OKActions.member', [options[:ok_actions]].flatten)) if options.has_key?(:ok_actions)
        
       if !(options[:dimensions].nil? || options[:dimensions].empty?)
          dims_params = {}
          i = 1
          options[:dimensions].each{ |dimension|
            dimension_var = dimension.split('=')
            dims_params = dims_params.merge!( "Dimensions.member.#{i}.Name" => "#{dimension_var[0]}", "Dimensions.member.#{i}.Value" => "#{dimension_var[1]}" )
            i += 1
          }
          params.merge!( dims_params )
        end
        
        return response_generator(:action => 'PutMetricAlarm', :params => params)
        
      end
      
      # PRIVATE METHODS
      private
      
      #
      # Returns all valid values for the Statistic parameter used by various AWS methods.
      #
      def valid_statistic_values
        ['SampleCount', 'Average', 'Sum', 'Minimum', 'Maximum']
      end
      
      #
      # Returns all valid values for the Unit parameter used by various AWS methods.
      #
      def valid_unit_values
        ["Seconds", "Microseconds", "Milliseconds", "Bytes", "Kilobytes", "Megabytes", 
          "Gigabytes", "Terabytes", "Bits", "Kilobits", "Megabits", "Gigabits", "Terabits", 
          "Percent", "Count", "Bytes/Second", "Kilobytes/Second", "Megabytes/Second", "Gigabytes/Second", 
          "Terabytes/Second", "Bits/Second", "Kilobits/Second", "Megabits/Second", "Gigabits/Second", "Terabits/Second", 
          "Count/Second", "None"]
      end

    end

  end

end

