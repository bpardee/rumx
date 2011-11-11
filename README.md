# rumx

http://github.com/ClarityServices/rumx

## Description:

Ruby Management Extensions

Allows you to easily implement management interfaces for your Ruby application.

## Install:

  gem install rumx

## Usage:

You can easily add management interfaces to your classes by including Rumx::Bean and creating
bean attributes and operations.  For example, you might create a class as follows:

    require 'rumx'

    class MyBean
      include Rumx::Bean

      bean_attr_reader   :greeting,           :string,  'My greeting'
      bean_reader        :goodbye,            :string,  'My goodbye'
      bean_attr_accessor :my_accessor,        :integer, 'My integer accessor'

      bean_operation     :my_operation,       :string,  'My operation', [
          [ :arg_int,    :integer, 'An int argument'   ],
          [ :arg_float,  :float,   'A float argument'  ],
          [ :arg_string, :string,  'A string argument' ]
      ]

      def initialize
        @greeting    = 'Hello, Rumx'
        @my_accessor = 4
      end

      def goodbye
        'Goodbye, Rumx (hic)'
      end

      def my_operation(arg_int, arg_float, arg_string)
        "arg_int class=#{arg_int.class} value=#{arg_int} arg_float class=#{arg_float.class} value=#{arg_float} arg_string class=#{arg_string.class} value=#{arg_string}"
      end
    end

You create a tree of beans under Rumx::Bean.root.  For instance, you might create a tree for the bean above with the following commands:

    my_folder = Rumx::Beans::Folder.new
    Rumx::Bean.root.bean_add_child(:my_folder, my_folder)
    my_folder.bean_add_child(:my_bean, MyBean.new)

Rumx includes a Sinatra server app called Rumx::Server.  You could startup a server by creating the following config.ru and running "rackup -p 4567"

    require 'rubygems'
    require 'rumx'
    require 'my_bean'
    require ...

    run Rumx::Server

Then, you can just browse to http://localhost:4567 to inspect, modify, and execute attributes and operations.

Rumx comes with some ready-made beans that you can use within your application.  For instance, suppose you wanted to track the
amount of time that an expensive operation takes to execute.  You might do something like the following:

    class MyClass
      @@timer = Rumx::Beans::Timer.new
      Rumx::Bean.root.bean_add_child(:my_timer, @@timer)

      def my_expensive_operation
        @@timer.measure do
          ...
        end
      end

      ...
    end

Then you could use a tool such as munin, nagios, hyperic, etc to poll the url http://my-host:4567/my_timer.json?reset=true
to monitor, graph, or create an alert based on the average, max, and min times that your operation takes.
Refer to the timer example for more information.

## TODO

Api doc non-existent.

Really needs some html/css love.  Right now the sinatra pages are so ugly they'll make your eyes hurt but I don't do this stuff
so well.  Volunteers anyone?

Need tests!  So far just doing Example Driven Development.

Build in optional authentication or just let user extend Rumx::Server?

Railtie it.

## Author

Brad Pardee

## Copyright

Copyright (c) 2011 Clarity Services. See LICENSE for details.
