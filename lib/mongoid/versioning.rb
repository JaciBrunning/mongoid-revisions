require 'mongoid/versioning/model_version.rb'
require 'mongoid/versioning/version.rb'

module Mongoid
  module Versioning
    extend ActiveSupport::Concern

    included do
      include Mongoid::Timestamps::Updated
      
      field :version_idx, type: Integer, default: 1
      field :_version_metadata, type: Hash, default: nil
      field :_versions, type: Array, default: []

      class_attribute :versioning_ignored_fields, default: []
    end

    def versions
      self._versions.map { |x| ModelVersion.new x }
    end

    def has_versions?
      !self._versions.empty?
    end

    def version
      @version
    end

    def version_at timestamp
      return self if !has_versions? || timestamp >= self.updated_at
      earliest = ModelVersion.new(self._versions.first)
      return earliest.reify if timestamp <= earliest.updated_at
      latest = ModelVersion.new(self._versions.last)
      return latest.reify if timestamp >= latest.updated_at
      vers = self._versions.reverse_each.find { |x| x['_version_metadata']['updated_at'] <= timestamp }
      return ModelVersion.new(vers).reify
    end

    def version?
      !@version.nil?
    end

    def live?
      !version?
    end

    def revise
      return false if version?
      save
      self.reload
      if !has_versions? || version_attributes_changed?
        _do_revise
      else
        false
      end
    end

    def revise!
      return false if version?
      save
      self.reload
      _do_revise
    end

    def _do_revise
      attrs = self.versioned_attributes
      self._versions << attrs.merge({
        '_version_metadata' => {    # This needs to be a string, since attrs aren't symbolized
          'updated_at' => DateTime.now,
          'model_class' => self.class.name,
          'idx' => self.version_idx
        }
      })
      self.version_idx = (self.version_idx || 1) + 1
      save
      true
    end

    def versioned_attributes attrs=nil
      ignored = self.class.versioning_ignored_fields.map(&:to_s)
      (attrs || self.attributes).except('_versions', '_version_metadata', 'updated_at', *ignored)
    end

    def versioned_attributes_for_changed attrs=nil
      versioned_attributes(attrs).except('version_idx')
    end

    def version_attributes_changed?
      return true if !has_versions?
      last_version_attrs = versioned_attributes_for_changed versions.last.attrs
      this_version_attrs = versioned_attributes_for_changed

      last_version_attrs != this_version_attrs
    end

    # Called when reified
    def _set_version version
      @version = version
    end

    class_methods do
      def ignore_versioning *fields
        self.versioning_ignored_fields.append *fields
      end

      def unignore_versioning *fields
        self.versioning_ignored_fields -= fields
      end
    end

  end
end
