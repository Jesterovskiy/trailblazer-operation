require "pipetree"
require "pipetree/flow"
require "trailblazer/operation/result"

class Trailblazer::Operation
  New  = ->(klass, options)     { klass.new(options) }                # returns operation instance.
  Call = ->(operation, options) { operation.call(options["params"]) } # returns #call result.

  module Pipetree
    def self.included(includer)
      includer.extend ClassMethods
      includer.extend Pipe

      includer.>> New, name: "operation.new"
      includer.>> Call, name: "operation.call"
      includer._insert :_insert, Result::Build, { append: true, name: "operation.result" }, Result::Build, "" # FIXME: nicer API, please.
    end

    module ClassMethods
      # Top-level, this method is called when you do Create.() and where
      # all the fun starts.
      def call(options)
        pipe = self["pipetree"] # TODO: injectable? WTF? how cool is that?

        pipe.(self, options)
      end
    end

    module Pipe
      def >>(*args); _insert(:>>, *args) end
      def >(*args); _insert(:>, *args) end
      def &(*args); _insert(:&, *args) end
      def <(*args); _insert(:<, *args) end

      # :private:
      def _insert(*args)
        heritage.record(:_insert, *args)

        self["pipetree"] ||= ::Pipetree::Flow[]
        self["pipetree"].send(*args) # ex: pipetree.> Validate, after: Model::Build
      end
    end
  end

  Result::Build = ->(last, input, options) {  Result.new(last == ::Pipetree::Flow::Right, input) } # DISCUSS: call Operation#result! here?
end

# TODO: test in pipetree_test the outcome of returning Stop. it's only implicitly tested with Policy.