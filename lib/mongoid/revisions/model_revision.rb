module Mongoid
  module Revisions
    class ModelRevision
      def initialize attrs
        @attrs = attrs
      end

      def metadata
        @attrs['_revision_metadata']
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
        mc._set_revision self
        mc
      end

      def inspect
        "#<#{self.class.name} model_class=#{model_class} idx=#{idx.inspect} updated_at='#{updated_at.inspect}'>"
      end
    end
  end
end