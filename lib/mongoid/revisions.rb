require 'mongoid/revisions/model_revision.rb'
require 'mongoid/revisions/version.rb'

module Mongoid
  module Revisions
    extend ActiveSupport::Concern

    included do
      include Mongoid::Timestamps::Updated
      
      field :revision_idx, type: Integer, default: 1
      field :_revision_metadata, type: Hash, default: nil
      field :_revisions, type: Array, default: []

      class_attribute :revision_ignored, default: []
    end

    def revisions
      self._revisions.map { |x| ModelRevision.new x }
    end

    def lazy_revisions
      self._revisions.lazy.map { |x| ModelRevision.new x }
    end

    def has_revisions?
      !self._revisions.empty?
    end

    def revision
      @revision
    end

    def revision_at timestamp
      return self if !has_revisions? || timestamp >= self.updated_at
      earliest = ModelRevision.new(self._revisions.first)
      return earliest.reify if timestamp <= earliest.updated_at
      latest = ModelRevision.new(self._revisions.last)
      return latest.reify if timestamp >= latest.updated_at
      rev = self._revisions.reverse_each.find { |x| x['_revision_metadata']['updated_at'] <= timestamp }
      return ModelRevision.new(rev).reify
    end

    def revision_with_idx idx
      return self if self.revision_idx == idx
      lazy_revisions.find { |r| r.idx == idx }&.reify
    end

    def revision?
      !@revision.nil?
    end

    def live?
      !revision?
    end

    def revise
      return false if revision?
      save
      self.reload  # Required in order to populate self.attributes with relations. Also requires save.
      if !has_revisions? || revision_attrs_changed?
        _do_revise
      else
        false
      end
    end

    def revise!
      return false if revision?
      save
      self.reload  # Required in order to populate self.attributes with relations. Also requires save.
      _do_revise
    end

    def _do_revise
      attrs = self.revision_attrs
      self._revisions << attrs.merge({
        '_revision_metadata' => {    # This needs to be a string, since attrs aren't symbolized
          'updated_at' => DateTime.now,
          'model_class' => self.class.name,
          'idx' => self.revision_idx
        }
      })
      self.revision_idx = (self.revision_idx || 1) + 1
      save
      true
    end

    def revision_attrs attrs=nil
      ignored = self.class.revision_ignored.map(&:to_s)
      (attrs || self.attributes).except('_revisions', '_revision_metadata', 'updated_at', *ignored)
    end

    def revision_attrs_for_changed attrs=nil
      revision_attrs(attrs).except('revision_idx')
    end

    def revision_attrs_changed?
      return true if !has_revisions?
      last_attrs = revision_attrs_for_changed revisions.last.attrs
      this_attrs = revision_attrs_for_changed

      last_attrs != this_attrs
    end

    # Called when reified
    def _set_revision revision
      @revision = revision
    end

    class_methods do
      def revision_ignore *fields
        self.revision_ignore.append *fields
      end

      def revision_unignore *fields
        self.revision_ignore -= fields
      end
    end

  end
end
