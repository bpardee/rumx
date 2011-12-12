Rumx Changelog
=====================

0.0.6

 - Separate out error tracking from Timer bean.  TimerAndError bean now includes what Timer bean used to bean.
   Timer and Error beans can be used to track time and errors individually.
   Apologies for the somewhat incompatible change if anyone is already using Rumx::Beans::Timer.  Just rename
   to Rumx::Beans::TimerAndError if you want both.

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
