module Rumx
  class RemoteBean
    include Bean

    # Override bean implementation with our own local array (instead of a class array)
    attr_reader :bean_attributes, :bean_operations

    # Constructor for mirroring the bean setup of a remote tree of beans
    #   hash     - the hashized form of this remote bean
    #   remote_strategy - an object that implements the following 2 methods for remotely running an operation
    #                     setting the attributes for this corresponding bean.  The methods should raise an
    #                     exception if they don't succeed (TODO: Should Rumx have either a logger or an Error Handler?)
    #     - run_operation(ancestry, operation, argument_hash, client_info) - returns the json-parsed return value of the operation
    #     - set_attributes(ancestry, params, client_info) - returns the new attribute tree
    #   client_info - optional information which will be passed along in the remote_strategy methods which could be used to identify
    #                 the remote server to communicate with if a single remote_strategy is used for all clients as opposed to one per client
    #   ancestry - a name array of ancestors of this object which details how to find the remote bean from the root
    def initialize(hash, remote_strategy, client_info=nil, ancestry=[])
      @remote_strategy = remote_strategy
      @client_info     = client_info
      @ancestry        = ancestry
      bean_synchronize do
        (hash['beans'] || []).each do |name, child_hash|
          child_bean = RemoteBean.new(child_hash, remote_strategy, client_info, ancestry + [name])
          bean_add_child(name, child_bean)
        end
        @bean_attributes = hash['attributes'].map {|hash| RemoteAttribute.from_hash(hash)}
        @bean_operations = hash['operations'].map {|hash| Operation.from_hash(hash)}
        #puts "ancestry=#{ancestry.inspect} operations=#{@bean_operations.inspect}"
      end
    end

    def bean_run_operation(operation, argument_hash)
      @remote_strategy.run_operation(@ancestry, operation, argument_hash, @client_info)
    #rescue Exception => e
    #  puts "Error running operation: #{e.message}"
    #  return e
    end

    #########
    protected
    #########

    # Separate call in case we're already monitor locked
    def do_bean_set_attributes(params)
      return if !params || params.empty?
      new_attributes = @remote_strategy.set_attributes(@ancestry, params, @client_info)
      super(new_attributes)
    #rescue Exception => e
    #  puts "Error setting attributes: #{e.message}"
    #  return e
    end
  end
end
