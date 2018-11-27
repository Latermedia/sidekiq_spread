# frozen_string_literal: true

require 'sidekiq_spread/version'
require 'sidekiq'

# Helpers to spread worker load out over a period of time
module SidekiqSpread
  PERFORM_SPREAD_OPTS = %i[
    duration
    in
    at
    method
    mod_value
  ].map { |o| "spread_#{o}".to_sym }.freeze

  def self.included(base)
    base.extend(ClassMethods)
  end

  # class methods for SidekiqSpread
  module ClassMethods
    # Randomly schedule worker over a window of time.
    # Arguments are keys of the final options hash.
    #
    # @param spread_duration [Number] Size of window to spread workers out over
    # @param spread_in [Number] Start of window offset from now
    # @param spread_at [Number] Start of window offset timestamp
    # @param spread_method [rand|mod] perform either a random or modulo spread,
    #   default: *:rand*
    # @param spread_mod_value [Integer] value to use for determining mod offset
    # @return [String] Sidekiq job id
    def perform_spread(*args)
      spread_duration = get_sidekiq_options['spread_duration'] || 1.hour
      spread_in = 0
      spread_at = nil
      spread_method = get_sidekiq_options['spread_method'] || :rand
      spread_mod_value = nil

      spread_method = spread_method.to_sym if spread_method.present?

      # process spread_* options

      has_options = false

      opts =
        if !args.empty? && args.last.is_a?(::Hash)
          has_options = true
          args.pop
        else
          {}
        end

      sd = _extract_spread_opt(opts, :duration)
      spread_duration = sd if sd.present?

      si = _extract_spread_opt(opts, :in)
      spread_in = si if si.present?

      sa = _extract_spread_opt(opts, :at)
      spread_at = sa if sa.present?

      sm = _extract_spread_opt(opts, :method)
      spread_method = sm.to_sym if sm.present?

      smv = _extract_spread_opt(opts, :mod_value)
      spread_mod_value = smv if smv.present?

      # get left over options / keyword args
      remaining_opts = opts.reject { |o| PERFORM_SPREAD_OPTS.include?(o.to_sym) }

      # check args
      num_args = args.length

      # figure out the require params for #perform
      params = new.method(:perform).parameters

      num_req_args = params.select { |p| p[0] == :req }.length
      num_opt_args = params.select { |p| p[0] == :opt }.length
      num_req_key_args = params.select { |p| p[0] == :keyreq }.length
      num_opt_key_args = params.select { |p| p[0] == :key }.length

      # Sidekiq doesn't play nicely with named args
      raise ArgumentError, "#{name}#perform should not use keyword args" if num_req_key_args.positive? || num_opt_key_args.positive?

      if has_options
        # if we popped something off to process, push it back on
        # if it contains arguments we need
        if num_args < num_req_args
          args.push(remaining_opts)
        elsif num_args < (num_req_args + num_opt_args) && !remaining_opts.empty?
          args.push(remaining_opts)
        end
      end

      # if a spread_mod_value is not provided use the first argument,
      # assumes it is an Integer
      spread_mod_value = args.first if spread_mod_value.blank? && spread_method == :mod

      # validate the spread_* options
      _check_spread_args!(spread_duration, spread_method, spread_mod_value)

      # calculate the offset for this job
      spread = _set_spread(spread_method, spread_duration.to_i, spread_mod_value)

      # call the correct perform_* method
      if spread_at.present?
        t = spread_at.to_i + spread
        perform_at(t, *args)
      else
        t = spread_in.to_i + spread
        if t.zero?
          perform_async(*args)
        else
          perform_in(t, *args)
        end
      end
    end

    # @private
    def _set_spread(spread_method, duration, spread_mod_value)
      return 0 if duration.blank? || duration.zero?

      case spread_method
      when :rand
        SecureRandom.random_number(duration)
      when :mod
        spread_mod_value % duration
      end
    end

    # @private
    def _check_spread_args!(duration, spread_method, spread_mod_value)
      raise ArgumentError, 'Duration must be an integer' unless duration.is_a?(::Integer)
      raise ArgumentError, 'Method must be rand or mod' unless %i[rand mod].include?(
        spread_method
      )
      return unless spread_method == :mod

      e = 'spread_mod_value must be provided or first arg must be an int to use mod'
      raise ArgumentError, e unless spread_mod_value.is_a?(::Integer)
    end

    # @private
    def _extract_spread_opt(opts, opt)
      str = "spread_#{opt}"
      sym = str.to_sym

      if opts.key?(sym)
        opts[sym]
      elsif opts.key?(str)
        opts[str]
      end
    end
  end
end
