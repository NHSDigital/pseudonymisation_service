# A wrapper class around mutiple identifiers sets.
class IdentifiersCollection
  include Enumerable

  def initialize(hashes)
    @collection = Array(hashes).map { |set| Identifiers.new(set) }
  end

  def each(&block)
    @collection.each(&block)
  end

  def valid?(field)
    all? { |identifiers| identifiers.valid?(field) }
  end

  def missing_for_variant(variant)
    flat_map { |identifiers| identifiers.missing_for_variant(variant) }.uniq
  end
end
