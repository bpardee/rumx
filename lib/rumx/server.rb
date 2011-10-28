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
          path = parent_path + '/' + URI.escape(name)
          val << partial(:tree_bean, :locals => {:path => path, :name =>name, :bean => bean})
        end
        val
      end

      def attributes_path(path)
        path + '/attributes'
      end

      def attribute_path(path, attribute=nil)
        if attribute
          "#{path}/#{attribute.name}/attribute"
        else
          "#{path}/attribute"
        end
      end

      def operations_path(path)
        path + '/operations'
      end

      def operation_path(path, operation=nil)
        if operation
          "#{path}/#{operation.name}/operation"
        else
          "#{path}/operation"
        end
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

      def haml_for_ajax(template, options={})
        layout = request.xhr? ? false : :layout
        options = options.merge(:layout => layout)
        haml template, options
      end

      def link_to_attributes(path)
        partial :link_to_attributes, :locals => {:path =>path}
      end

      def link_to_attribute(path, attribute)
        partial :link_to_attribute, :locals => {:path =>path, :attribute => attribute}
      end

      def link_to_operations(path)
        partial :link_to_operations, :locals => {:path =>path}
      end

      def link_to_operation(path, operation)
        partial :link_to_operation, :locals => {:path =>path, :operation => operation}
      end

      def attribute_value_tag(bean, attribute)
        partial :attribute_value_tag, :locals => {:bean => bean, :attribute => attribute}
      end
    end

    get '/' do
      haml :index
    end

    get '/*/attributes.?:format?' do
      path = params[:splat][0]
      bean = Bean.find(path.split('/'))
      return 404 unless bean
      # For get we read, then write.  post is the other way around.
      attribute_value_hash = bean.bean_get_and_set_attributes(params)
      if params[:format] == 'json'
      else
        haml_for_ajax :content_attributes, :locals => {:path => '/' + URI.escape(path), :bean => bean, :attribute_value_hash => attribute_value_hash}
      end
    end

    post '/*/attributes.?:format?' do
      path = params[:splat][0]
      bean = Bean.find(path.split('/'))
      return 404 unless bean
      # For post we write, then read.  get is the other way around.
      bean.bean_set_attributes(params)
      attribute_value_hash = bean.bean_get_attributes
      if params[:format] == 'json'
      else
        haml_for_ajax :content_attributes, :locals => {:path => '/' + URI.escape(path), :bean => bean, :attribute_value_hash => attribute_value_hash}
      end
    end

    get '/*/attribute.?:format?' do
      path = params[:splat][0]
      bean, attribute = Bean.find_attribute(path.split('/'))
      return 404 unless bean
      if params[:format] == 'json'
      else
        haml_for_ajax :content_attribute, :locals => {:path => '/' + URI.escape(path), :bean => bean, :attribute => attribute}
      end
    end

    post '/*/attribute.?:format?' do
      path = params[:splat][0]
      bean, attribute = Bean.find_attribute(path.split('/'))
      return 404 unless bean
      bean.bean_set_attributes(params)
      if params[:format] == 'json'
      else
        haml_for_ajax :content_attribute, :locals => {:path => '/' + URI.escape(path), :bean => bean, :attribute => attribute}
      end
    end

    get '/*/operations' do
      path = params[:splat][0]
      bean = Bean.find(path.split('/'))
      return 404 unless bean
      haml_for_ajax :content_operations, :locals => {:path => '/' + URI.escape(path), :bean => bean}
    end

    get '/*/operation.?:format?' do
      path = params[:splat][0]
      bean, operation = Bean.find_operation(path.split('/'))
      return 404 unless bean
      if params[:format] == 'json'
      else
        haml_for_ajax :content_operation, :locals => {:path => '/' + URI.escape(path), :bean => bean, :operation => operation}
      end
    end

    post '/*/operation.?:format?' do
      path = params[:splat][0]
      bean, operation = Bean.find_operation(path.split('/'))
      return 404 unless bean
      operation.run(bean, params).to_json
    end

  end
end
