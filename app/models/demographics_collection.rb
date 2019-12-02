# A wrapper class around mutiple demographics sets.
class DemographicsCollection
  include Enumerable

  def initialize(hashes)
    @collection = Array(hashes).map { |set| Demographics.new(set) }
  end

  def each(&block)
    @collection.each(&block)
  end

  def valid?(field)
    all? { |demographics| demographics.valid?(field) }
  end

  def missing_for_variant(variant)
    flat_map { |demographics| demographics.missing_for_variant(variant) }.uniq
  end
end
