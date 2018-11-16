require "./spec_helper"

describe Speacr::Speaker do
  # TODO: Write tests

  context "basic functionality" do
    it "puts the response" do
      p! Speacr::Speaker.new.say("test phrase").gets
      # => Failed to raise an exception: END_OF_STACK
      # [0x559c4f7bee96] *CallStack::print_backtrace:Int32 +118
      # [0x559c4f7a1036] __crystal_raise +86
      # [0x559c4f7a140e] ???
      # [0x559c4f7a133e] ???
      # [0x559c4f7d81a6] *Thread::current:Thread +70
      # [0x559c4f7d7e46] *Crystal::Scheduler::current_fiber:Fiber +6
      # [0x559c4f7d7166] *Fiber::current:Fiber +6
      # [0x559c4f7b11a2] __crystal_sigfault_handler +18
      # [0x7f7784f2a890] ???
      # [0x559c5160db88] ???

    end
  end
end
