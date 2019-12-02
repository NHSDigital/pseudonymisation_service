require 'test_helper'

class DemographicsCollectionTest < ActiveSupport::TestCase
  setup do
    @set1 = { nhs_number: '0123456789' }
    @set2 = { nhs_number: '0123456789', postcode: 'CB22 3AB' }

    @collection = DemographicsCollection.new([@set1, @set2])
  end

  test 'should iterate to return Demographics objects' do
    array = @collection.to_a

    assert_equal 2, array.length
    assert_equal Demographics.new(@set1), array[0]
    assert_equal Demographics.new(@set2), array[1]
  end

  test 'should be valid if all members are valid' do
    assert @collection.valid?(:nhs_number)
    refute @collection.valid?(:postcode)
  end

  test 'should uniquely combine missing fields across members' do
    assert_equal %i[], @collection.missing_for_variant(1)
    assert_equal %i[birth_date postcode], @collection.missing_for_variant(2)
    assert_equal %i[input_pseudoid], @collection.missing_for_variant(3)
  end
end
