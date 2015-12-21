module PDF
  module Core
    class ObjectStore #:nodoc:
      def initialize(opts = {})
        @objects = {}
        @identifiers = []

        load_file(opts[:template]) if opts[:template]

        @info ||= ref(opts[:info] || {}).identifier
        @root ||= ref(:Type => :Catalog).identifier
        if opts[:print_scaling] == :none
          root.data[:ViewerPreferences] = { :PrintScaling => :None }
        end
        if pages.nil?
          root.data[:Pages] = ref(:Type => :Pages, :Count => 0, :Kids => [])
        end
      end
    end
  end
end
