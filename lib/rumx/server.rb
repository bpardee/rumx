require 'sinatra/base'
require 'json'
require 'haml'
require 'uri'

module Rumx
  class Server < Sinatra::Base
    configure do
      enable :logging
    end

    set :root, File.join(File.dirname(__FILE__), 'server')

    helpers do
      def render_tree_bean_attributes(path, bean)
        #puts "attributes for bean=#{bean}"
        attributes = bean.class.bean_attributes
        return '' if attributes.empty?
        partial :tree_bean_attributes, :locals => {:path => path, :bean => bean}
      end

      def render_tree_bean_operations(path, bean)
        operations = bean.class.bean_operations
        return '' if operations.empty?
        partial :tree_bean_operations, :locals => {:path => path, :bean => bean}
      end

      def render_tree_bean_children(parent_path, parent_bean)
        children = parent_bean.bean_children
        return '' if children.empty?
        val = ''
        children.each do |name, bean|
          #puts "in child name=#{name} bean=#{bean}"
          path = URI.escape(parent_path + '/' + name)
          val << partial(:tree_bean, :locals => {:path => path, :name =>name, :bean => bean})
        end
        val
      end

      def attributes_path(path)
        path + '/attributes'
      end

      def operations_path(path)
        path + '/operations'
      end

      # http://sinatra-book.gittr.com/#implementation_of_rails_style_partials but extract_options! part of ActiveSupport
      # Also look at http://stackoverflow.com/questions/3974878/rendering-a-partial-from-a-haml-file
      def partial(template, options={})
        options.merge!(:layout => false)
        if collection = options.delete(:collection) then
          collection.inject([]) do |buffer, member|
            buffer << haml(template, options.merge(
                                      :layout => false,
                                      :locals => {template.to_sym => member}
                                    )
                         )
          end.join("\n")
        else
          haml(template, options)
        end
      end

      def find_bean(escaped_path)
        arr = escaped_path.split('/').map {|name| URI.unescape(name)}
        Bean.find(arr)
      end
    end

    get '/' do
      haml :index
    end

    get '/*/attributes.?:format?' do
      bean = find_bean(params[:splat][0])
      return 404 unless bean
      if params[:format] == 'json'
      else
        partial :content_attributes, :locals => {:bean => bean}
      end
    end

    get '/*/operations' do
      names = params[:splat][0].split('/')
      Bean.operations(names, params)
    end

    get '/*/children' do
      names = params[:splat][0].split('/')
      Bean.children(names, params)
    end

    get '/*' do
      names = params[:splat][0].split('/')
      Bean.get(names, params)
    end

    post '/*' do
      names = params[:splat][0].split('/')
      Bean.post(names, params)
    end
  end
end
