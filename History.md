Rumx Changelog
=====================

0.2.0

 - Bridge to JMX

0.1.5

 - Require Beans::TimerAndErrorHash otherwise it won't do any good adding it.

0.1.4

 - Oops, I had broken all the examples when I changed the setup around.
 - Added Beans::TimerAndErrorHash

0.1.3

 - Check for nil when using Hash and List attribute.
 - Fix bug where

0.1.2

 - Changed Beans::TimerAndError so it doesn't reset error count.  Works better to map this as a trend upward attribute.

0.1.1

 - Changed Bean::Timer attribute total_count to count and added non-resettable total_count as attribute.
   For munin, this allows the total count to be collected in a separate call without worrying about it being reset.

0.1.0

 - Removed the following methods and the equivalient writers and accessors to hopefully make the commands more consistent:

   OLD: bean_list_reader :foo, :string, 'Description'
   NEW: bean_reader :foo, :list, 'Description', :list_type => :string

   OLD: bean_list_attr_reader :foo, :string, 'Description'
   NEW: bean_attr_reader :foo, :list, 'Description', :list_type => :string, :allow_write => true #Use allow_write if the accessing of list elements is different from the list.

   OLD: bean_embed :foo, 'Description'
   NEW: bean_reader :foo, :bean, 'Description'

   OLD: bean_attr_embed :foo, 'Description'
   NEW: bean_attr_reader :foo, :bean, 'Description'

   OLD: bean_embed_list :foo, 'Description'
   NEW: bean_reader :foo, :list, 'Description', :list_type => :bean

   OLD: bean_attr_embed_list :foo, 'Description'
   NEW: bean_attr_reader :foo, :list, 'Description', :list_type => :bean

 - Added Hash type

 - A lot of restructuring of the code so it isn't quite as repetitive for the bean iteration and such.

 - Added example/monitor_script for an example script that could be used with a tool like munin or hyperic.

0.0.8

 - Added /attributes query which can retrieve attributes for multiple beans in one call.

0.0.7

 - Add .properties format for brain-dead hyperic.  Might as well allow extending while we're at it.

0.0.6

 - Separate out error tracking from Timer bean.  TimerAndError bean now includes what Timer bean used to bean.
   Timer and Error beans can be used to track time and errors individually.
   Apologies for the somewhat incompatible change if anyone is already using Rumx::Beans::Timer.  Just rename
   to Rumx::Beans::TimerAndError if you want both.
 - Fix bug where Rack mounted apps don't have the correct url.

0.0.5

 - Allow default values for operation arguments.
 - Add json mime type.

0.0.4

 - Fix bug where embedded beans and bean-lists of base classes weren't included.

0.0.3

 - Use msec instead of sec for Timer bean.

0.0.2

 - Added dependencies sinatra, haml and rack.

0.0.1

 - Initial release
