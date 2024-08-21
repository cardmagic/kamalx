require 'spec_helper'
require 'kamalx'

RSpec.describe KamalX do
  describe '.run' do
    it 'calls EventMachine.run' do
      expect(EventMachine).to receive(:run).once
      KamalX.run([])
    end
  end

  describe 'LogParser' do
    let(:parser) { LogParser.new }

    it 'parses stage information' do
      line = 'INFO [foo] Running something on bar'
      expect(parser.parse(line)).to eq([:green, [:bold, 'Stage:'], ' foo'])
    end

    it 'parses command information' do
      line = 'INFO [foo] Finished in 2.3 seconds with exit status 0'
      expect(parser.parse(line)).to eq([:yellow, [:bold, 'Command[foo@localhost]'], ' Returned Status: ', :green, '0'])
    end

    it 'parses debug information' do
      line = 'DEBUG [foo] This is a debug message'
      expect(parser.parse(line)).to eq([:yellow, [:bold, 'Command[foo@localhost]'], ' This is a debug message'])
    end

    it 'parses info information' do
      line = 'INFO This is an info message'
      expect(parser.parse(line)).to eq([:blue, [:bold, 'Info:'], ' This is an info message'])
    end
  end
end
