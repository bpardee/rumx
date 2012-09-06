module Rumx
  class RemoteBean
    include Bean

    # Override bean implementation with our own local array (instead of a class array)
    attr_reader :bean_attributes, :bean_operations

    # Constructor for mirroring the bean setup of a remote tree of beans
    #   hash     - the hashized form of this remote bean
    #   remote_strategy - an object that implements the following 2 methods for remotely running an operation
    #                     setting the attributes for this corresponding bean.  The methods should raise an
    #                     exception if they don't succeed which is silently ignored but allows the caller
    #                     to skip the remaining processing (TODO: Should Rumx have either a logger or an Error Handler?)
    #     - run_operation(ancestry, operation, argument_hash) - returns the json-parsed return value of the operation
    #     - set_attributes(ancestry, params) - returns the new attribute tree
    #   ancestry - a name array of ancestors of this object which details how to find the remote bean from the root
    def initialize(hash, remote_strategy, ancestry=[])
      @ancestry        = ancestry
      @remote_strategy = remote_strategy
      bean_synchronize do
        (hash['beans'] || []).each do |name, child_hash|
          child_bean = RemoteBean.new(child_hash, remote_strategy, ancestry + [name])
          bean_add_child(name, child_bean)
        end
        @bean_attributes = hash['attributes'].map {|hash| RemoteAttribute.from_hash(hash)}
        @bean_operations = hash['operations'].map {|hash| Operation.from_hash(hash)}
        puts "ancestry=#{ancestry.inspect} operations=#{@bean_operations.inspect}"
      end
    end

    def run_operation(operation, argument_hash)
      @remote_strategy.run_operation(@ancestry, operation, argument_hash)
    rescue Exception => e
      # Silently ignore for now
      puts "Error running operation: #{e.message}"
      return e
    end

    #########
    protected
    #########

    # Separate call in case we're already monitor locked
    def do_bean_set_attributes(params)
      return if !params || params.empty?
      new_attributes = @remote_strategy.set_attributes(@ancestry, params)
      super(new_attributes)
    rescue Exception => e
      # Silently ignore for now
      puts "Error setting attributes: #{e.message}"
      return e
    end
  end
end
