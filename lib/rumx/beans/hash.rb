module Rumx
  module Beans
    class Hash
      include Bean

      def initialize(&block)
        raise 'Must be given initialize instance to create the bean' unless block_given?
        @block = block
        # Hacks for potential race conditions
        bean_children
        bean_synchronize {}
      end

      def [](key)
        child = bean_children[key]
        return child if child
        bean_synchronize do
          # Try it again to prevent race
          child = bean_children[key]
          return child if child
          child = @block.call(key)
          bean_add_child(key, child)
        end
        return child
      end

      def delete(key)
        bean_synchronize do
          bean_remove_child(key)
        end
      end
    end
  end
end
