module PDF
  module Core
    class Page #:nodoc:
      # As per the PDF spec, each page can have multiple content streams. This will
      # add a fresh, empty content stream this the page, mainly for use in loading
      # template files.
      #
      def new_content_stream
        return if in_stamp_stream?

        unless dictionary.data[:Contents].is_a?(Array)
          dictionary.data[:Contents] = [content]
        end
        @content    = document.ref({})
        dictionary.data[:Contents] << document.state.store[@content]
        document.open_graphics_state
      end

      def init_from_object(options)
        @dictionary = options[:object_id].to_i
        dictionary.data[:Parent] = document.state.store.pages if options[:page_template]

        unless dictionary.data[:Contents].is_a?(Array) # content only on leafs
          @content    = dictionary.data[:Contents].identifier
        end

        @stamp_stream      = nil
        @stamp_dictionary  = nil
        @imported_page     = true
      end
    end
  end
end
