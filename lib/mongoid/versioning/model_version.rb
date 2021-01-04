module Mongoid
  module Versioning
    class ModelVersion
      def initialize attrs
        @attrs = attrs
      end

      def metadata
        @attrs['_version_metadata']
      end

      def updated_at
        metadata['updated_at']
      end

      def idx
        metadata['idx']
      end

      def model_class
        metadata['model_class'].constantize
      end

      def attrs
        @attrs
      end

      def reify
        mc = model_class.new @attrs 
        mc.updated_at = updated_at if mc.respond_to? :updated_at
        mc._set_version self
        mc
      end

      def inspect
        "#<#{self.class.name} model_class=#{model_class} idx=#{idx.inspect} updated_at='#{updated_at.inspect}'>"
      end
    end
  end
end