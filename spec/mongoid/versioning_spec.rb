require_relative '../spec_helper'
require 'date'
require 'timecop'

describe Mongoid::Versioning do
  describe "#version_idx" do
    context "when the document is new" do
      it "should be 1" do
        expect(Person.create.version_idx).to eq(1)
      end
    end

    context "when the document is revised once" do
      let(:person) { Person.create }
      before { person.revise! }
      it "should be 2" do
        expect(person.version_idx).to eq(2)
      end
    end

    context "when the document is revised multiple times" do
      let(:person) { Person.create }
      before { 5.times { person.revise! } }
      it "should update" do
        expect(person.version_idx).to eq(6)
      end
    end
  end

  describe "#versions" do
    let(:person) { Person.create name: '1' }

    context "when the document is new" do
      it "should be empty" do
        expect(person.versions.empty?).to be true
        expect(person.has_versions?).to be false
      end
    end

    context "when the document is revised" do
      before { person.revise }
      it "should have the baseline revision" do
        expect(person.versions.count).to eq(1)
        expect(person.has_versions?).to eq true
      end
      
      context "then revised again with changes" do
        context "via first level attributes," do
          before { person.name = '2'; person.revise }

          it "should have a new version" do
            expect(person.versions.count).to eq(2)
          end

          context "the first reified version" do
            let(:reified) { person.versions[0].reify }
            it "should have the old attributes" do
              expect(reified.name).to eq('1')
            end
          end

          context "the second reified version" do
            let(:reified) { person.versions[1].reify }
            it "should have the new attributes" do
              expect(reified.name).to eq('2')
            end
          end
        end

        context "via embedded documents," do
          before { person.addresses.create(address: 'addr1'); person.revise }

          it "should have a new version" do
            expect(person.versions.count).to eq(2)
          end

          context "the first reified version" do
            let(:reified) { person.versions[0].reify }
            it "should have the old attributes" do
              expect(reified.addresses.empty?).to be true
            end
          end

          context "the second reified version" do
            let(:reified) { person.versions[1].reify }
            it "should have the new attributes" do
              expect(reified.addresses.size).to eq(1)
              expect(reified.addresses.first.address).to eq('addr1')
            end
          end
        end

        context "via has_and_belongs_to_many," do
          before { person.pets.create(name: 'pet1'); person.revise }

          it "should have a new version" do
            expect(person.versions.count).to eq(2)
          end

          context "the first reified version" do
            let(:reified) { person.versions[0].reify }
            it "should have the old attributes" do
              expect(reified.pets.empty?).to be true
            end
          end

          context "the second reified version" do
            let(:reified) { person.versions[1].reify }
            it "should have the new attributes" do
              expect(reified.pets.size).to eq(1)
              expect(reified.pets.first.name).to eq('pet1')
            end

            it "should only embed the objectID, not the whole document" do
              expect(reified.attributes).to include("pet_ids")
              expect(reified.attributes).not_to include("pets")
            end
          end
        end
      end

      context "then revised again without changes" do
        before { person.revise }
        it "should not have any additional versions" do
          expect(person.versions.count).to eq(1)
        end
      end

      context "then revised again without changes forcefully" do
        before { person.revise! }

        it "should have a new version" do
          expect(person.versions.count).to eq(2)
        end
      end
    end
  end

  describe "#version" do
    let(:person) { Person.create }
    context "when the document is new" do
      it "should be nil" do
        expect(person.version).to be nil
        expect(person.version?).to be false
      end

      it "should be live" do
        expect(person.live?).to be true
      end
    end

    context "when the document is revised" do
      before { person.revise! }
      it "should be nil" do
        expect(person.version).to be nil
        expect(person.version?).to be false
      end

      it "should be live" do
        expect(person.live?).to be true
      end

      context "and reified to the first revision" do
        let(:reified) { person.versions.first.reify }

        it "should not be live" do
          expect(reified.live?).to be false
        end

        it "should be a ModelVersion" do
          expect(reified.version).to be_instance_of(Mongoid::Versioning::ModelVersion)
          expect(reified.version?).to be true
        end

        it "should have the correct idx" do
          expect(reified.version.idx).to eq(1)
          expect(reified.version.idx).to eq(reified.version_idx)
        end

        it "should have the correct model class" do
          expect(reified.version.model_class).to eq(Person)
        end
      end
    end
  end

  describe "#version_at" do
    let(:person) { Person.create name: "No name" }
    context "when versions do not exist" do
      it "selects the live version" do
        march_15 = person.version_at(DateTime.new(2020, 3, 15))
        expect(march_15.name).to eq("No name")
      end
    end

    context "when versions exist" do
      before do
        Timecop.freeze(DateTime.new(2020, 4)) do 
          person.name = "April"
          person.revise
        end

        Timecop.freeze(DateTime.new(2020, 5)) do
          person.name = "May"
          person.revise
        end

        Timecop.freeze(DateTime.new(2020, 6)) do
          person.name = "June"
          person.revise
        end

        Timecop.freeze(DateTime.new(2020, 7)) do
          person.name = "July"
          person.save
        end
      end

      context "when the timestamp is before all versions" do
        it "selects the earliest version" do
          march_15 = person.version_at(DateTime.new(2020, 3, 15))
          expect(march_15.name).to eq("April")
        end
      end

      context "when the timestamp is inbetween versions" do
        it "selects the earlier version" do
          april_15 = person.version_at(DateTime.new(2020, 4, 15))
          expect(april_15.name).to eq("April")
          may_15 = person.version_at(DateTime.new(2020, 5, 15))
          expect(may_15.name).to eq("May")
        end
      end

      context "when the timestamp is beyond all versions" do
        context "and below updated_at" do
          it "selects the latest version" do
            june_15 = person.version_at(DateTime.new(2020, 6, 15))
            expect(june_15.name).to eq("June")
          end
        end

        context "and above updated_at" do
          it "selects the live version" do
            december = person.version_at(DateTime.new(2020, 12))
            expect(december.name).to eq("July")
            expect(december.live?).to be true
          end
        end
      end
    end
  end
end
