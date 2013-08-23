require 'test_helper'

class CertificateTest < ActiveSupport::TestCase

  def setup
    Certificate.destroy_all

    @certificate1 = FactoryGirl.create(:response_set_with_dataset).certificate
    @certificate2 = FactoryGirl.create(:response_set_with_dataset).certificate
    @certificate3 = FactoryGirl.create(:response_set_with_dataset).certificate
    @certificate4 = FactoryGirl.create(:response_set_with_dataset).certificate
    @certificate5 = FactoryGirl.create(:response_set_with_dataset).certificate

    @certificate1.update_attributes(name: 'Banana certificate', curator: 'John Smith')
    @certificate2.update_attributes(name: 'Monkey certificate', curator: 'John Wards')
    @certificate3.update_attributes(name: 'Monkey banana certificate', curator: 'Frank Smith')
    @certificate4.update_attributes(name: 'Gorilla certificate', curator: 'Frank Cho', published: true)
    @certificate5.update_attributes(name: 'Pineapple certificate', curator: 'Edward Smith', published: true)

    @certificate1.response_set.survey.update_attributes(full_title: 'United Kingdom')
    @certificate2.response_set.survey.update_attributes(full_title: 'United States')
    @certificate3.response_set.survey.update_attributes(full_title: 'Wales')
    @certificate4.response_set.survey.update_attributes(full_title: 'France', published: true)
    @certificate5.response_set.survey.update_attributes(full_title: 'France', published: true)



  end

  test 'search title matches single term' do
    assert_equal [@certificate1, @certificate3], Certificate.search_title('banana')
  end

  test 'search title matches multiple terms' do
    assert_equal [@certificate3], Certificate.search_title('certificate Monkey banana')
  end

  test 'search publisher matches single term' do
    assert_equal [@certificate1, @certificate2], Certificate.search_publisher('JOHN')
  end

  test 'search publisher matches multiple terms' do
    assert_equal [@certificate3], Certificate.search_publisher('Frank Smith')
  end

  test 'search country matches single term' do
    assert_equal [@certificate1, @certificate2], Certificate.search_country('United')
  end

  test 'search country matches multiple terms' do
    assert_equal [@certificate1], Certificate.search_country('United Kingdom')
  end




  test 'group_similar groups surveys by survey title and response_set id' do
    assert_equal [@certificate1, @certificate2, @certificate3, @certificate4, @certificate5], Certificate.group_similar
  end

  test 'certificates are ordered by most recently created' do
    assert_equal @certificate5, Certificate.by_newest.first
  end

  test 'latest returns the most recently published ' do
    @certificate5.response_set.publish!
    assert_equal @certificate5.id, Certificate.latest.id
  end


end
