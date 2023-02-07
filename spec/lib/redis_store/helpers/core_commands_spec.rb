require 'rails_helper'

describe RedisStore::Helpers::CoreCommands do
  let(:subject_class) do
    Class.new(Dry::Struct) do
      include RedisStore::Helpers::CoreCommands
      extend RedisStore::Helpers::CoreCommands::ClassMethods

      attribute :key, Types::String

      def redis
        self.class.redis
      end

      class << self
        def redis
          @redis ||= MockRedis.new
        end
      end
    end
  end

  let(:key) { 'some-key' }
  let(:field) { :field }
  let(:field_value) { 'some-value' }
  let(:hash_value) { {field => field_value } }
  let(:other_field) { :other_field }
  let(:other_value) { 'other_value' }

  let(:instance) { subject_class.new(key: key) }
  let(:subject) do
    instance.set_hash(hash_value)
    instance
  end

  describe 'ClassMethods' do
    describe '.read_value' do
      before(:each) { instance.set(other_value) }

      it 'returns set simple value' do
        actual = subject_class.read_value(key)

        expect(actual).to eql(other_value)
      end
    end

    describe '.read_hash' do
      it 'returns original hash value' do
        subject

        expect(subject_class.read_hash(key)).to eql(hash_value)
      end
    end

    describe '.read_by' do
      it 'returns original hash value' do
        subject

        expect(subject_class.read_by(key)).to eql(hash_value)
      end

      context 'with unexpected key' do
        it 'returns original hash value' do
          expect(subject_class.read_by('some-other-key')).to be_nil
        end
      end
    end
  end

  describe '.set_hash' do
    it 'sets hash value' do
      value = instance.set_hash(hash_value)

      expect(value).to be_nil

      expect(subject_class.read_hash(key)).to eql(hash_value)
    end
  end

  describe '#set_subhash' do
    it 'sets another field without affecting other fields' do
      subject.set_subhash(other_field, other_value)

      expect(subject.read).to eql(hash_value.merge( other_field => other_value))
    end
  end

  describe '#read' do
    it 'reads set value' do
      expect(subject.read).to eql(hash_value)
    end
  end

  describe '#read_subhash' do
    it 'reads set value' do
      expect(subject.read_subhash(field)).to eql(field_value)
    end
  end

  describe '#ttl' do
    it 'reads set value' do
      expect(subject.ttl).to eql(-1)
    end
  end

  describe '#expire' do
    it 'sets expiration' do
      subject.expire 200

      expect(subject.ttl).to_not eql(-1)
    end
  end

  describe '#exists?' do
    it 'returns true' do
      expect(subject.exists?).to be_truthy
    end

    it 'returns false when not persisted' do
      expect(instance.exists?).to be_falsey
    end
  end

  describe '#set' do
    it 'sets non hash values' do
      value = 'some-value'
      actual = instance.set(value)

      expect(actual).to be_nil
      expect(instance.read_value).to eql(value)
    end
  end
end
