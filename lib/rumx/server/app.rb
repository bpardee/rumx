require 'sinatra/base'
require 'json'
require 'haml'

module Rumx::Server
  class App < Sinatra::Base
    configure do
      enable :logging
    end

    set :root, File.dirname(__FILE__)

    helpers do
      def render_tree_bean_attributes(bean)
        #puts "attributes for bean=#{bean}"
        attributes = bean.class.bean_attributes
        return '' if attributes.empty?
        partial :tree_bean_attributes, :locals => {:bean => bean}
      end

      def render_tree_bean_operations(bean)
        operations = bean.class.bean_operations
        return '' if operations.empty?
        partial :tree_bean_operations, :locals => {:bean => bean}
      end

      def render_tree_bean_children(parent_bean)
        children = parent_bean.bean_children
        return '' if children.empty?
        val = ''
        children.each do |name, bean|
          #puts "in child name=#{name} bean=#{bean}"
          val << partial(:tree_bean, :locals => {:name =>name, :bean => bean})
        end
        val
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
    end

    get '/' do
      haml :index
    end

    get '/*/attributes.?:format?' do
      bean = Bean.find(params[:splat][0].split('/'))
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
