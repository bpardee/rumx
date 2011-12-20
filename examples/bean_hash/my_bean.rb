require 'rumx'

class MyEntryBean
  include Rumx::Bean

  bean_attr_accessor :my_int,    :integer, 'My integer'
  bean_attr_reader   :my_string, :string,  'My string'

  def initialize(my_int, my_string)
    @my_int, @my_string = my_int, my_string
  end
end

class MyBean
  include Rumx::Bean

  bean_attr_reader :entries,  :hash,   'My entries', :hash_type => :bean

  bean_operation   :put_entry, :void, 'Put entry into hash', [
      [ :key,       :symbol,  'Hash key'],
      [ :my_int,    :integer, 'An integer argument' ],
      [ :my_string, :string,  'A string argument' ]
  ]

  bean_operation   :remove_entry, :void, 'Remove entry from hash', [
      [ :key,       :symbol,  'Hash key']
  ]

  def initialize
    @entries = {:foo => MyEntryBean.new(1, '#1')}
  end

  def put_entry(key, my_int, my_string)
    @entries[key] = MyEntryBean.new(my_int, my_string)
    return my_string
  end

  def remove_entry(key)
    removed = @entries.delete(key)
    return 'None' unless removed
    return removed.my_string
  end
end

