require 'traject'

module Traject
  # Just some internal utility methods
  module Util

    def self.exception_to_log_message(e)
      indent = "    "

      msg  = indent + "Exception: " + e.class.name + ": " + e.message + "\n"
      msg += indent + e.backtrace.first + "\n"

      if (e.respond_to?(:getRootCause) && e.getRootCause && e != e.getRootCause )
        caused_by = e.getRootCause
        msg += indent + "Caused by\n"
        msg += indent + caused_by.class.name + ": " + caused_by.message + "\n"
        msg += indent + caused_by.backtrace.first + "\n"
      end

      return msg
    end

    # From ruby #caller method, you get an array. Pass one line
    # of the array here,  get just file and line number out.
    def self.extract_caller_location(str)
      str.split(':in `').first
    end

    # Requires marc4j jar(s) from settings['marc4j.jar_dir'] if given, otherwise
    # uses jars bundled with traject gem in ./vendor
    #
    # Have to pass in a settings arg, so we can check it for specified jar dir.
    #
    # Tries not to do the dirglob and require if marc4j has already been loaded.
    # Will define global constants with classes MarcPermissiveStreamReader and MarcXmlReader
    # if not already defined.
    #
    # This is all a bit janky, maybe there's a better way to do this? We do want
    # a 'require' method defined somewhere utility, so multiple classes can
    # use it, including extra gems. This method IS used by extra gems, so should
    # be considered part of the API -- after it's called, those top-level
    # globals should be available, and marc4j should be loaded.
    def self.require_marc4j_jars(settings)
      require 'java'

      tries = 0
      begin
        tries += 1

        org.marc4j

        # java_import which we'd normally use weirdly doesn't work
        # from a class method. https://github.com/jruby/jruby/issues/975
        Object.const_set("MarcPermissiveStreamReader",  org.marc4j.MarcPermissiveStreamReader) unless defined? ::MarcPermissiveStreamReader
        Object.const_set("MarcXmlReader",  org.marc4j.MarcXmlReader) unless defined? ::MarcXmlReader
      rescue NameError  => e
        # /Users/jrochkind/code/solrj-gem/lib"

        include_jar_dir = File.expand_path("../../vendor/marc4j/lib", File.dirname(__FILE__))

        jardir = settings["marc4j.jar_dir"] || include_jar_dir
        Dir.glob("#{jardir}/*.jar") do |x|
          require x
        end

        if tries > 1
          raise LoadError.new("Can not find Marc4J java classes")
        else
          retry
        end
      end
    end

    # Requires solrj jar(s) from settings['solrj.jar_dir'] if given, otherwise
    # uses jars bundled with traject gem in ./vendor
    #
    # Have to pass in a settings arg, so we can check it for specified jar dir.
    #
    # Tries not to do the dirglob and require if solrj has already been loaded.
    # Will define global constants with classes HttpSolrServer and SolrInputDocument
    # if not already defined.
    #
    # This is all a bit janky, maybe there's a better way to do this? We do want
    # a 'require' method defined somewhere utility, so multiple classes can
    # use it, including extra gems. This method may be used by extra gems, so should
    # be considered part of the API -- after it's called, those top-level
    # globals should be available, and solrj should be loaded.
    def self.require_solrj_jars(settings)
      require 'java'

      tries = 0
      begin
        tries += 1

        org.apache.solr
        org.apache.solr.client.solrj

        # java_import which we'd normally use weirdly doesn't work
        # from a class method. https://github.com/jruby/jruby/issues/975
        Object.const_set("HttpSolrServer", org.apache.solr.client.solrj.impl.HttpSolrServer) unless defined? ::HttpSolrServer
        Object.const_set("SolrInputDocument", org.apache.solr.common.SolrInputDocument) unless defined? ::SolrInputDocument
      rescue NameError  => e
        # /Users/jrochkind/code/solrj-gem/lib"

        included_jar_dir = File.expand_path("../../vendor/solrj/lib", File.dirname(__FILE__))

        jardir = settings["solrj.jar_dir"] || included_jar_dir
        Dir.glob("#{jardir}/*.jar") do |x|
          require x
        end
        if tries > 1
          raise LoadError.new("Can not find SolrJ java classes")
        else
          retry
        end
      end
    end

  end
end