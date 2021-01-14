require 'mongoid/association/embedded/embeds_many'
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
        # mc = model_class.new @attrs
        mc = _reify model_class, @attrs 
        mc.updated_at = updated_at if mc.respond_to? :updated_at
        mc._set_revision self
        mc
      end

      # Just calling model_cls.new(attrs) fails to account for embedded associations that are inherited with _type.
      # We check for embedded associations and ensure that embeds_many and embeds_one are handled properly.
      def _reify model_cls, attrs
        disc_key = model_cls.discriminator_key
        model_cls = attrs[disc_key].constantize if attrs[disc_key]
        instance = model_cls.new
        attrs.each do |k, v|
          if (rel = model_cls.relations[k]) && rel.embedded? 
            # Reify the subrel
            if rel.is_a?(Mongoid::Association::Embedded::EmbedsMany)
              instance[k] = v.map { |v_curr| _reify(rel.relation_class_name.constantize, v_curr) }
            else
              instance[k] = _reify(rel.relation_class_name.constantize, v)
            end
          else
            # Reify the attribute directly
            instance[k] = v
          end
        end
        instance
      end

      def inspect
        "#<#{self.class.name} model_class=#{model_class} idx=#{idx.inspect} updated_at='#{updated_at.inspect}'>"
      end
    end
  end
end