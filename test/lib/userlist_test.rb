require 'test_helper'

class UserlistTest < ActiveSupport::TestCase
  setup do
    @token = '2e5e5ea81c9e342d8f03b0233770d1006255c418b8156f0a907e69b73e56bcb4'
  end

  test 'can find entries by valid token' do
    assert_equal 'test_user', Userlist.find_by(token: "test_user:#{@token}")
  end

  test 'returns nothing for invalid token' do
    assert_nil Userlist.find_by(token: 'test_user:wibble')
    assert_nil Userlist.find_by(token: 'wibble')
  end

  test 'should remember valid token usages, for performance' do
    # Bcypt is slow, so successful auths should get cached:
    BCrypt::Password.any_instance.expects(:==).with(@token).once.returns(true)

    assert Userlist.find_by(token: "test_user:#{@token}")
    assert Userlist.find_by(token: "test_user:#{@token}")

    assert_equal 1, Userlist.token_cache.length
  end

  test 'should not remember valid token usages by wrong user' do
    refute Userlist.find_by(token: "another_user:#{@token}")
    refute Userlist.find_by(token: "another_user:#{@token}")

    assert_equal 0, Userlist.token_cache.length
  end

  test 'should not remember invalid token usages' do
    token = 'wibble' * 10

    refute Userlist.find_by(token: "user:#{token}")
    refute Userlist.find_by(token: "user:#{token}")

    assert_equal 0, Userlist.token_cache.length
  end

  test 'should not remember valid token usages after the YAML file changes' do
    # We "update" the userlist between checks, so we should expect full Bcrypt
    # comparisons for both checks:
    BCrypt::Password.any_instance.expects(:==).with(@token).twice.returns(true)

    travel_to(4.seconds.ago) do
      Userlist.list(force_read: true) # avoid leakage
      assert Userlist.find_by(token: "test_user:#{@token}")
    end
    FileUtils.touch Userlist.path, mtime: 3.seconds.ago.to_time
    travel_to(2.seconds.ago) do
      assert Userlist.find_by(token: "test_user:#{@token}")
      assert_equal 1, Userlist.token_cache.length
    end

    FileUtils.touch Userlist.path, mtime: 1.second.ago.to_time
    assert_equal 0, Userlist.token_cache.length
  end
end
