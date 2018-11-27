# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/integer/time'

Sidekiq::Testing.fake!

class SidekiqHelperWorker
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task

  def perform; end
end

class SidekiqHelperWorker1a
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task

  def perform(args1); end
end

class SidekiqHelperWorker1b
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task

  def perform(args1, arg2); end
end

class SidekiqHelperWorker1c
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task

  def perform(args1, arg2 = nil); end
end

class SidekiqHelperWorker2
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task, spread_duration: 2.hours

  def perform(id); end
end

class SidekiqHelperWorker3
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task, spread_method: :mod

  def perform(id); end
end

class SidekiqHelperWorker4
  include Sidekiq::Worker
  include SidekiqSpread

  sidekiq_options queue: :task

  def perform(id, bad_arg:); end
end

RSpec.describe 'SidekiqSpread' do
  describe 'perform_spread' do
    before(:each) do
      @rand = 50
      allow(SecureRandom).to receive(:random_number).with(1.hours.to_i).and_return(@rand)
    end

    it 'should call perform_in' do
      expect(SecureRandom).to receive(:random_number).with(1.hours.to_i).and_return(50)
      expect(SidekiqHelperWorker).to receive(:perform_in).with(50)
      SidekiqHelperWorker.perform_spread
    end

    it 'should call perform_async with arguemnts - no opts' do
      expect(SidekiqHelperWorker1c).to receive(:perform_in).with(50, :a, :b)
      SidekiqHelperWorker1c.perform_spread(:a, :b)
    end

    it 'should call perform_async with arguemnts - 0 duration' do
      expect(SidekiqHelperWorker1b).to receive(:perform_async).with(:a, :b)
      SidekiqHelperWorker1b.perform_spread(:a, :b, spread_duration: 0)
    end

    it 'should call perform_in with arguemnts' do
      t = (1.hour + @rand).to_i
      expect(SidekiqHelperWorker1c).to receive(:perform_in).with(t, :a, :b)
      SidekiqHelperWorker1c.perform_spread(:a, :b, spread_in: 1.hour)
    end

    it 'should call perform_in with arguemnts - end hash' do
      t = (1.hour + @rand).to_i
      expect(SidekiqHelperWorker1b).to receive(:perform_in).with(t, :a, things: :stuff)
      SidekiqHelperWorker1b.perform_spread(:a, things: :stuff, spread_in: 1.hour)
    end

    it 'should call perform_in with arguemnts - end hash - 2' do
      t = (1.hour + @rand).to_i
      expect(SidekiqHelperWorker1c).to receive(:perform_in).with(t, :a, things: :stuff)
      SidekiqHelperWorker1c.perform_spread(:a, things: :stuff, spread_in: 1.hour)
    end

    it 'should call perform_in with arguemnts - empty hash' do
      expect(SidekiqHelperWorker1b).to receive(:perform_in).with(@rand, :a, {})
      SidekiqHelperWorker1b.perform_spread(:a, {})
    end

    it 'should call perform_in with arguemnts - empty hash - 2' do
      expect(SidekiqHelperWorker1c).to receive(:perform_in).with(@rand, :a)
      SidekiqHelperWorker1c.perform_spread(:a)
    end

    describe 'spread_duration' do
      it 'should call perform_in with spread_duration option - sidekiq_options' do
        expect(SecureRandom).to receive(:random_number).with(2.hours.to_i).and_return(100)
        expect(SidekiqHelperWorker2).to receive(:perform_in).with(100, 1234)
        SidekiqHelperWorker2.perform_spread(1234)
      end

      it 'should call perform_in with spread_duration option - argument override' do
        expect(SecureRandom).to_not receive(:random_number).with(2.hours.to_i)
        expect(SecureRandom).to receive(:random_number).with(3.hours.to_i).and_return(200)
        expect(SidekiqHelperWorker2).to receive(:perform_in).with(200, 1234)
        SidekiqHelperWorker2.perform_spread(1234, spread_duration: 3.hours)
      end

      it 'should call perform_in with spread_duration option - argument' do
        expect(SecureRandom).to receive(:random_number).with(2.hours.to_i).and_return(100)
        expect(SidekiqHelperWorker1a).to receive(:perform_in).with(100, 1234)
        SidekiqHelperWorker1a.perform_spread(1234, spread_duration: 2.hours)
      end

      it 'should call perform_in with spread_duration option - argument - string' do
        expect(SecureRandom).to receive(:random_number).with(2.hours.to_i).and_return(100)
        expect(SidekiqHelperWorker1c).to receive(:perform_in).with(100, 1234)
        SidekiqHelperWorker1c.perform_spread(1234, 'spread_duration' => 2.hours)
      end
    end

    describe 'spread_method' do
      it 'should call perform_in with spread_method option - sidekiq_options' do
        expect(SecureRandom).to_not receive(:random_number)
        expect(SidekiqHelperWorker3).to receive(:perform_in).with((1234 % 3600), 1234)
        SidekiqHelperWorker3.perform_spread(1234)
      end

      it 'should call perform_in with spread_method option - argument override' do
        expect(SecureRandom).to receive(:random_number).with(1.hour.to_i).and_return(100)
        expect(SidekiqHelperWorker3).to receive(:perform_in).with(100, 1234)
        SidekiqHelperWorker3.perform_spread(1234, spread_method: :rand)
      end

      it 'should call perform_in with spread_method option - argument' do
        expect(SecureRandom).to_not receive(:random_number)
        expect(SidekiqHelperWorker1a).to receive(:perform_in).with((1234 % 3600), 1234)
        SidekiqHelperWorker1a.perform_spread(1234, spread_method: :mod)
      end

      it 'should call perform_in with spread_method option - argument - string' do
        expect(SecureRandom).to_not receive(:random_number)
        expect(SidekiqHelperWorker1a).to receive(:perform_in).with((1234 % 3600), 1234)
        SidekiqHelperWorker1a.perform_spread(1234, spread_method: 'mod')
      end
    end

    it 'should call perform_in with spread_in offset' do
      t = (1.hour + @rand).to_i
      expect(SidekiqHelperWorker1a).to receive(:perform_in).with(t, 1234)
      SidekiqHelperWorker1a.perform_spread(1234, spread_in: 1.hour)
    end

    it 'should call perform_in with spread_in offset - sidekiq_options - spread_duration' do
      allow(SecureRandom).to receive(:random_number).with(2.hours.to_i).and_return(100)
      t = (3.hour + 100).to_i
      expect(SidekiqHelperWorker2).to receive(:perform_in).with(t, 1234)
      SidekiqHelperWorker2.perform_spread(1234, spread_in: 3.hour)
    end

    it 'should call perform_at with spread_at offset' do
      t = 3.hours.from_now
      pat = (t + @rand).to_i
      expect(SidekiqHelperWorker1a).to receive(:perform_at).with(pat, 1234)
      SidekiqHelperWorker1a.perform_spread(1234, spread_at: t)
    end

    it 'should call perform_at with spread_at offset - sidekiq_options - spread_duration' do
      allow(SecureRandom).to receive(:random_number).with(2.hours.to_i).and_return(100)
      t = 3.hours.from_now
      pat = (t + 100).to_i
      expect(SidekiqHelperWorker2).to receive(:perform_at).with(pat, 1234)
      SidekiqHelperWorker2.perform_spread(1234, spread_at: t)
    end

    it 'raises an ArgumentError if :mod is passed in without an argument' do
      expect do
        SidekiqHelperWorker1a.perform_spread(spread_method: :mod)
      end.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError if :mod is passed in without an integer first argument' do
      expect do
        SidekiqHelperWorker1a.perform_spread('string', spread_method: :mod)
      end.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError if perform takes a keyword arg' do
      expect do
        SidekiqHelperWorker4.perform_spread(1234, bad_arg: :things, spread_method: :mod)
      end.to raise_error(ArgumentError)
    end

    it 'calls perform_spread with option mod if given an integer and mod' do
      mod = 10_000 # arbitrary large number of things
      spread_duration = 1.hour.to_i
      expect(SidekiqHelperWorker1a).to receive(:perform_in).with((mod % spread_duration), mod)
      SidekiqHelperWorker1a.perform_spread(mod, spread_method: :mod)
    end

    it 'calls perform_spread with option mod if given an spread_mod_value option and mod' do
      mod = 10_000 # arbitrary large number of things
      spread_duration = 1.hour.to_i
      expect(SidekiqHelperWorker1a).to receive(:perform_in).with((mod % spread_duration), 1234)
      SidekiqHelperWorker1a.perform_spread(1234, spread_method: :mod, spread_mod_value: mod)
    end

    it 'calls perform_spread with option mod if given an spread_mod_value option and mod - 2' do
      mod = 10_000 # arbitrary large number of things
      spread_duration = 1.hour.to_i
      expect(SidekiqHelperWorker1a).to receive(:perform_in).with((mod % spread_duration), 'things')
      SidekiqHelperWorker1a.perform_spread('things', spread_method: :mod, spread_mod_value: mod)
    end

    it 'calls perform_spread with option mod if given an spread_mod_value option and mod - 3' do
      mod = 10_000 # arbitrary large number of things
      spread_duration = 1.hour.to_i
      expect(SidekiqHelperWorker1a).to receive(:perform_in).with((mod % spread_duration), 50)
      SidekiqHelperWorker1a.perform_spread(50, spread_method: :mod, spread_mod_value: mod)
    end

    it 'spread_opts args' do
      mod = 1234 # arbitrary large number of things
      spread_duration = 2.hours.to_i

      expect(SidekiqHelperWorker1a).to receive(:perform_in).with((mod % spread_duration), 1234)
      expect(SidekiqHelperWorker1a).to_not receive(:perform_in).with((mod % spread_duration), 1234, {})

      spread_opts = {
        spread_method: :mod,
        spread_duration: spread_duration
      }

      SidekiqHelperWorker1a.perform_spread(1234, spread_opts)
    end
  end
end
