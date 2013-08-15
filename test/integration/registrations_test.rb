require 'test_helper'

class RegistrationsTest < ActionDispatch::IntegrationTest
  test "should wrap password and password_confirmation fields in div with field_with_errors class on passwords don't match error" do

    resource.errors.include?(:password), resource.errors.include?(:password_confirmation)

     then resource.errors must include (:password_confirmation)
     must_equal = resource.errors.add(:password, :password_confirmation)


    assert_equal "resources.errors", must_equal



  end
end