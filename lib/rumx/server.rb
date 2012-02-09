require 'sinatra/base'
require 'json'
require 'haml'
require 'uri'
require 'cgi'
# See http://groups.google.com/group/sinatrarb/browse_thread/thread/87bf7613631e48aa
require 'rack/file'

module Rumx
  class Server < Sinatra::Base
    configure do
      enable :logging
      mime_type :json, 'application/json'
      mime_type :properties, 'text/plain'
    end

    set :root, File.join(File.dirname(__FILE__), 'server')

    helpers do
      def render_tree_bean_attributes(path, bean)
        return '' unless bean.bean_has_attributes?
        partial :tree_bean_attributes, :locals => {:path => path, :bean => bean}
      end

      def render_tree_bean_operations(path, bean)
        return '' unless bean.bean_has_operations?
        partial :tree_bean_operations, :locals => {:path => path, :bean => bean}
      end

      def render_tree_bean_children(parent_path, parent_bean)
        val = ''
        parent_bean.bean_each_child do |name, bean|
          #puts "in child name=#{name} bean=#{bean}"
          path = "#{parent_path}/#{name}"
          val << partial(:tree_bean, :locals => {:path => path, :name =>name, :bean => bean})
        end
        val
      end

      def attributes_path(path)
        url URI.escape(path + '/attributes')
      end

      def attribute_path(path)
        url URI.escape(path + '/attribute')
      end

      def operations_path(path)
        url URI.escape(path + '/operations')
      end

      def operation_path(path)
        url URI.escape(path + '/operation')
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
        partial :link_to_content, :locals => {:href => attributes_path(path), :name => 'Attributes'}
      end

      def link_to_attribute(parent_path, attribute_info)
        path = rel_path(attribute_info.ancestry)
        partial :link_to_content, :locals => {:href => attribute_path(parent_path+'/'+path), :name => path}
      end

      def link_to_operations(path)
        partial :link_to_content, :locals => {:href => operations_path(path), :name => 'Operations'}
      end

      def link_to_operation(parent_path, operation)
        partial :link_to_content, :locals => {:href => operation_path(parent_path+'/'+operation.name.to_s), :name => operation.name}
      end

      def attribute_value_tag(attribute_info)
        partial :attribute_value_tag, :locals => {:attribute_info => attribute_info}
      end

      def rel_path(ancestry)
        ancestry.join('/')
      end

      def param_name(ancestry)
        pname = ancestry[0].to_s
        ancestry[1..-1].each do |name|
          pname += "[#{name}]"
        end
        return pname
      end
    end

    get '/' do
      haml :index, :locals => {:path => '', :root => ::Rumx::Bean.root}
    end

    get '/*/attributes.?:format?' do
      # For get we read, then write.  post is the other way around.
      do_get_or_post_splat_attributes(params, :bean_get_and_set_attributes)
    end

    post '/*/attributes.?:format?' do
      # For post we write, then read.  get is the other way around.
      do_get_or_post_splat_attributes(params, :bean_set_and_get_attributes)
    end

    # Allow a monitor to get the attributes from multiple beans.
    # Use with params such as prefix_0=bean0&bean_0=MyFolder/MyBean&prefix_1=bean1&bean_1=MyOtherFolder/SomeOtherBean
    get '/attributes.?:format?' do
      do_get_or_post_attributes(params, :bean_get_and_set_attributes)
    end

    post '/attributes.?:format?' do
      do_get_or_post_attributes(params, :bean_set_and_get_attributes)
    end

    get '/*/operations' do
      path = params[:splat][0]
      bean = Bean.find(path.split('/'))
      return 404 unless bean
      haml_for_ajax :content_operations, :locals => {:path => '/' + path, :bean => bean}
    end

    get '/*/operation.?:format?' do
      path = params[:splat][0]
      bean, operation = Bean.find_operation(path.split('/'))
      return 404 unless bean
      if params[:format] == 'json'
      else
        haml_for_ajax :content_operation, :locals => {:path => '/' + path, :bean => bean, :operation => operation}
      end
    end

    post '/*/operation.?:format?' do
      path = params[:splat][0]
      bean, operation = Bean.find_operation(path.split('/'))
      return 404 unless bean
      operation.run(bean, params).to_json
    end

    get '/:root' do
      root = Bean.root(params[:root])
      return 404 unless root
      haml :index, :locals => {:path => '/'+params[:root], :root => root}
    end

    #######
    protected
    #######

    def handle_attributes(attribute_hash, format)
      case format
        when 'json'
          content_type :json
          attribute_hash.to_json
        when 'properties'
          content_type :properties
          to_properties(attribute_hash)
        else
          404
      end
    end

    #######
    private
    #######

    def to_properties(val, prefix=nil)
      str = ''
      new_prefix = (prefix + '.') if prefix
      new_prefix = new_prefix || ''
      if val.kind_of?(Hash)
        val.each do |key, value|
          str += to_properties(value, new_prefix + key.to_s)
        end
      elsif val.kind_of?(Array)
        val.each_with_index do |value, i|
          str += to_properties(value, new_prefix + i.to_s)
        end
      else
        str += "#{prefix}=#{val}\n"
      end
      return str
    end

    def do_get_or_post_splat_attributes(params, get_set_method)
      #puts "params=#{params.inspect}"
      path = params[:splat][0]
      bean = Bean.find(path.split('/'))
      return 404 unless bean
      if params[:format]
        handle_attributes(bean.send(get_set_method, params), params[:format])
      else
        haml_for_ajax :content_attributes, :locals => {:get_set_method => get_set_method, :params => params, :path => path, :bean => bean}
      end
    end

    def do_get_or_post_attributes(params, get_set_method)
      hash = {}
      index = 0
      while query = params["query_#{index}"]
        index += 1
        uri = URI.parse(query)
        prefix = nil
        bean_path = uri.path
        if i = bean_path.index('=')
          prefix = bean_path[0,i]
          bean_path = bean_path[(i+1)..-1]
        end
        bean = Bean.find(bean_path.split('/'))
        return 404 unless bean
        new_params = {}
        if uri.query
          cgi = CGI.parse(uri.query)
          # We shouldn't have any dual params so let's turn this into a params object we can understand
          cgi.each do |key, value|
            new_params[key] = value[0]
          end
        end
        bean_hash = bean.send(get_set_method, new_params)
        if prefix
          hash[prefix.to_sym] = bean_hash
        else
          hash = hash.merge(bean_hash)
        end
      end
      if index > 0
        handle_attributes(hash, params[:format])
      else
        # If we didn't get called with any queries, assume we were meant to be a splat on the root bean
        params[:splat] = ['']
        do_get_or_post_splat_attributes(params, get_set_method)
      end
    end
  end
end
